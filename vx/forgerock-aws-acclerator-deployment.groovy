@Library('SharedLibraryFROG@master') _
def base64_decoded
def amConfigAdminPassword
def helm3Image
// Groovy Function to encode input String to Base64 String
def base64Encode(inputString) {
    encoded = inputString.bytes.encodeBase64().toString()
    return encoded
}

// Groovy Function to decode Base64 input to String
def base64Decode(encodedString) {
    return new String(encodedString.decodeBase64())
}

def deploy_components(env_name, market, deployment_namespace, component){
    docker.withRegistry('https://artifactory.global.standardchartered.com/', 'jenkins_deployer') {
        helm3Image = docker.image("frogpl/helm3-base:latest")
        retry(3) {
            helm3Image.pull()
        }
        helm3Image.inside('-u root') {
            loadEKSConfig(env_name, market, deployment_namespace )
            String credentialId = "EKS_SSO_PASSWORD_APP_NS_${market.toUpperCase()}_${env_name.toUpperCase()}"
            println("Using credential with id $credentialId")
            withCredentials([string(credentialsId: credentialId, variable: 'sso_password_from_credentials')]) {
                withEnv(["SSO_PASSWORD=${sso_password_from_credentials}"]) {
                    awsSTSTokenAccess()
                    echo "params.SECRETS_MODE is ${SECRETS_MODE}"
                    if(component == 'AM'){
                        try{
                            sh "kubectl get ingress am-ingress-${deployment_namespace}"
                        }catch(error){
                            echo "You need to install ingress first"
                        }
                        try{
                            sh "kubectl get pods | grep repl-server"
                        }catch(error){
                            echo "You need to install DS components first"
                            throw error
                        }
                    }
                    sh """
                        chmod 660 cicd-scripts/deploy-all-components.sh
                        chmod +x cicd-scripts/deploy-all-components.sh
                        cicd-scripts/deploy-all-components.sh
                    """
                    debugDeploymentEvents(DEPLOYMENT_NAMESPACE)
                }
            }
        }
    }
}

def getSecretFromCredentials(env, market, id) {
    def credentialName = getNameBy(env, market, id)
    println("${credentialName}")
    withCredentials([string(credentialsId: credentialName, variable: 'PASSWORD')]) {
        return PASSWORD
    }
}

def getENV(jobName){
    envn = jobName.contains('OAT') ? 'oat' : jobName.contains('STAGING') ? 'stg' : jobName.contains('UAT') ? 'uat' : jobName.contains('DEV') ? 'dev' : jobName.contains('PT') ? 'pt' : 'none'
    return envn
}

def getNameBy(env, market, id) {
    def credentialId = "FORGEROCK_${id.toUpperCase()}_${deployment_namespace.toUpperCase().replace('-','_')}_NS_${market.toUpperCase()}_${env.toUpperCase().replace('-', '_')}"
    echo "credentialId -> ${credentialId}"
    return credentialId
}

def loadEKSConfig(env_name, market, deployment_namespace ) {
        println("★★★ Loading... eks/${env_name}/${market}/${deployment_namespace}.groovy file ★★★ ")
        load "${WORKSPACE}/eks/${env_name}/${market}/${deployment_namespace}.groovy"
        println("★★★ Loading... eks/${env_name}/proxies.groovy file ★★★ ")
        load "${WORKSPACE}/eks/${env_name}/proxies.groovy"
        println("★★★ Loading eks config complete ★★★ ")
}

def awsSTSTokenAccess() {
    sh '''
    aws-sts login --skip-prompt --hostname sts01.internal.sc.com -u $ADUSER -a $ACCOUNT_ID --role $ROLE
    aws eks update-kubeconfig --name $EKS_CLUSTER --region $REGION
    kubectl config set-context \$(kubectl config current-context) --namespace=${DEPLOYMENT_NAMESPACE}
    '''
}

def debugDeploymentEvents(current_ns){
    sh """
        kubectl -n ${current_ns} get services
        kubectl -n ${current_ns} get deployments
        kubectl -n ${current_ns} get pods
        kubectl get events -n ${current_ns} --sort-by=.metadata.creationTimestamp
    """
}


pipeline {
    agent { label "docker2x" }

    parameters {
        booleanParam(name: "CLEAR", defaultValue: false)
        booleanParam(name: "SETUP", defaultValue: false)
        booleanParam(name: "RETRIEVE_SECRETS", defaultValue: false)
        booleanParam(name: "DEPLOY_RS", defaultValue: false)
        booleanParam(name: "DEPLOY_US", defaultValue: false)
        booleanParam(name: "DEPLOY_TS", defaultValue: false)
        booleanParam(name: "DEPLOY_AM", defaultValue: false)
        string(defaultValue: 'sg', name: 'MARKET_NAME', trim: true)
        string(defaultValue: 'application-1', name: 'DEPLOYMENT_NAMESPACE', trim: true)
        string(defaultValue: 'scb-ubi', name: 'DEPLOYMENT_IMAGES_TAG', trim: true)
        choice(name: 'REPLICAS', choices: ['1', '2', '3', '4'], description: 'Pick number of replicas')
        string(defaultValue: 'am.global.standardchartered.com', name: 'AM_LB_DOMAIN', trim: true)
        string(defaultValue: 'iPlanetDirectoryPro', name: 'COOKIE_NAME', trim: true)
        choice(name: 'SECRETS_MODE', choices: ['k8s'], description: 'Pick secrets mode')
        booleanParam(name: "CS_SIDECAR_MODE", defaultValue: true)
    } //parameters

    environment {
        path_gcp_registry_admin = "/tmp/gcp-docker-registry-admin.json"
        path_kubeconfig = "$HOME/.kube/config"
        IMAGE_PULL_SECRETS = 'fr-nexus-docker'
        deployment_namespace = "${params.DEPLOYMENT_NAMESPACE}"
        NAMESPACE = "${DEPLOYMENT_NAMESPACE}"
        market = "${params.MARKET_NAME}"
        env_name = getENV(JOB_NAME)
        CS_SIDECAR_MODE = "${params.CS_SIDECAR_MODE}"
        DEPLOY_IMAGES_TAG = "${DEPLOYMENT_IMAGES_TAG}"
        secrets_mode = "${params.SECRETS_MODE}"
        VAULT_BASE_URL = "DUMMY_PLACEHOLDER_CONTENT_VAULT_BASE_URL"
        VAULT_TOKEN = "DUMMY_PLACEHOLDER_CONTENT_VAULT_TOKEN"
        ENV_TYPE = "fr7"
        SECRETS_BASE_PATH = "forgerock/data/${ENV_TYPE}/"
        CONFIGSTORE_VAULT_PATH = "${SECRETS_BASE_PATH}config-store"
        USERSTORE_VAULT_PATH = "${SECRETS_BASE_PATH}user-store"
        TOKENSTORE_VAULT_PATH = "${SECRETS_BASE_PATH}token-store"
        REPLSERVER_VAULT_PATH = "${SECRETS_BASE_PATH}repl-server"
        AM_VAULT_PATH = "${SECRETS_BASE_PATH}access-manager"
        IDM_VAULT_PATH = ""
        DEPLOY_IDM = "${params.DEPLOY_IDM}"
        AM_LB_DOMAIN = "${AM_LB_DOMAIN}"
        DS_REPLICAS_CS = "${params.REPLICAS}"
        DS_REPLICAS_US = "${params.REPLICAS}"
        DS_REPLICAS_TS = "${params.REPLICAS}"
        DS_REPLICAS_RS = "${params.REPLICAS}"
        AM_REPLICAS = "${params.REPLICAS}"
        IDM_REPLICAS = "${params.REPLICAS}"
        AM_COOKIE_NAME = "${COOKIE_NAME}"
        SELF_REPL_TS = "false"
        SELF_REPL_US = "false"
        SELF_REPL_CS = "true"
        CS_K8S_SVC_URL = "forgerock-access-manager.${NAMESPACE}.svc.cluster.local"
        TS_K8S_SVC_URL = "forgerock-token-store.${NAMESPACE}.svc.cluster.local"
        US_K8S_SVC_URL = "forgerock-user-store.${NAMESPACE}.svc.cluster.local"
        USERSTORE_LOAD_SCHEMA = "true"
        USERSTORE_LOAD_DSCONFIG = "true"
        EXTERNAL_POLICY_STORE = "false"
        AM_AMSTER_FILES = 'amster_DefaultCtsDataStoreProperties\\,amster_platform'
        PODNAME_AM = "forgerock-access-manager"
        PODNAME_INGRESS = "forgerock-ingress"
        PODNAME_CS = "forgerock-config-store"
        PODNAME_US = "forgerock-user-store"
        PODNAME_TS = "forgerock-token-store"
        PODNAME_RS = "forgerock-repl-server"
        PODNAME_IDM = "forgerock-idm"
        SERVICENAME_AM = "forgerock-access-manager"
        SERVICENAME_CS = "forgerock-config-store"
        SERVICENAME_US = "forgerock-user-store"
        SERVICENAME_TS = "forgerock-token-store"
        SERVICENAME_RS = "forgerock-repl-server"
        SERVICENAME_IDM = "forgerock-idm"
        CI_REGISTRY_URL = "artifactory.global.standardchartered.com/ciam/forgerock"
        CLOUD_TYPE = 'sftp'
        K8S_LOCATION = "azure"
        FR_KUBE_CONFIG = ""
    }//environment


    stages {

        // stage('Verify User'){
        //     steps{
        //         script{
        //             validator.validateUser(env_name)
        //         }
        //     }
        // }

        stage('Clear Down Environment') {
            when { expression { params.CLEAR } }
            // agent { label "docker2x" }
            steps {
                script {

                    docker.withRegistry('https://artifactory.global.standardchartered.com/', 'jenkins_deployer') {
                        helm3Image = docker.image("frogpl/helm3-base:latest")
                        retry(3) {
                            helm3Image.pull()
                        }
                        helm3Image.inside('-u root') {

                            loadEKSConfig(env_name, market, deployment_namespace )

                            String credentialId = "EKS_SSO_PASSWORD_APP_NS_${market.toUpperCase()}_${env_name.toUpperCase()}"
                            println("Using credential with id $credentialId")
                            withCredentials([string(credentialsId: credentialId, variable: 'sso_password_from_credentials')]) {
                                withEnv(["SSO_PASSWORD=${sso_password_from_credentials}"]) {
                                    awsSTSTokenAccess()
                                    try {
                                        sh """
                                            kubectl get ns ${DEPLOYMENT_NAMESPACE}
                                            helm ls --all --short -n "${DEPLOYMENT_NAMESPACE}" | grep -v ${PODNAME_INGRESS} | xargs helm uninstall -n "${DEPLOYMENT_NAMESPACE}"
                                            kubectl delete pvc --all --force --grace-period=0 -n ${DEPLOYMENT_NAMESPACE}
                                        """
                                        echo "Waiting 30 seconds for SVC to finish clearing up ..."
                                        sleep(time: 30, unit: "SECONDS")
                                    }
                                    catch (error) {
                                        echo "Clean-up for Namespace ${DEPLOYMENT_NAMESPACE} failed"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }//stage('Clear Down Environment')

        stage('Setup Cluster Pre-requisites') {
            when { expression { params.SETUP } }
            // agent { label "docker2x" }

            steps {
                echo 'Setup Cluster Pre-requisites'
                script {
                    docker.withRegistry('https://artifactory.global.standardchartered.com/', 'jenkins_deployer') {
                        helm3Image = docker.image("frogpl/helm3-base:latest")
                        retry(3) {
                            helm3Image.pull()
                        }
                        helm3Image.inside('-u root') {

                            loadEKSConfig(env_name, market, deployment_namespace )

                            String credentialId = "EKS_SSO_PASSWORD_APP_NS_${market.toUpperCase()}_${env_name.toUpperCase()}"
                            println("Using credential with id $credentialId")
                            withCredentials([string(credentialsId: credentialId, variable: 'sso_password_from_credentials')]) {
                                withEnv(["SSO_PASSWORD=${sso_password_from_credentials}"]) {

                                    awsSTSTokenAccess()

                                    try {
                                        sh """
                                           kubectl get ns ${DEPLOYMENT_NAMESPACE}
                                        """
                                    }
                                    catch (error) {
                                        sh """
                                           kubectl config current-context
                                           echo '-> Creating Namespace'
                                           kubectl create ns ${DEPLOYMENT_NAMESPACE}
                                           """
                                    }
                                    sh("kubectl config set-context --current --namespace=${DEPLOYMENT_NAMESPACE}")
                                }
                            }
                        }
                    }
                }
            }
        }// stage('Setup Cluster Pre-requisites')

        stage('Deploy Secrets From Jenkins') {
            when { expression { params.RETRIEVE_SECRETS } }
            steps {
                script {
                    def secretkey_cs = "config-store"
                    def secretkey_us = "user-store"
                    def secretkey_ts = "token-store"
                    def secretkey_rs = "repl-server"
                    def secretkey_am = "access-manager"
                    def cs_certificate = ""
                    def cs_certificateKey = ""
                    def cs_amConfigAdminPassword = ""
                    def cs_configStoreCertPwd = ""
                    def cs_deploymentKey = ""
                    def cs_monitorUserPassword = ""
                    def cs_rootUserPassword = ""
                    def cs_truststorePwd = ""
                    def rs_certificate = ""
                    def rs_certificateKey = ""
                    def rs_deploymentKey = ""
                    def rs_keystorePwd = ""
                    def rs_monitorUserPassword = ""
                    def rs_rootUserPassword = ""
                    def rs_truststorePwd = ""

                    def us_amIdentityStoreAdminPassword = ""
                    def us_deploymentKey = ""
                    def us_monitorUserPassword = ""
                    def us_rootUserPassword = ""
                    def us_truststorePwd = ""
                    def us_userStoreCertPwd = ""
                    def us_certificate = ""
                    def us_certificateKey = ""

                    def ts_amCtsAdminPassword = ""
                    def ts_deploymentKey = ""
                    def ts_monitorUserPassword = ""
                    def ts_rootUserPassword = ""
                    def ts_tokenStoreCertPwd = ""
                    def ts_truststorePwd = ""
                    def ts_certificate = ""
                    def ts_certificateKey = ""

                    def am_amAdminPwd = ""
                    def am_cfgStoreDirMgrPwd = ""
                    def am_ctsDirMgrPwd = ""
                    def am_tomcatJKSPwd = ""
                    def am_truststorePwd = ""
                    def am_userStoreDirMgrPwd = ""
                    def am_encKey_AmPwd = ""
                    def am_encKey_directenc = ""
                    def am_encKey_hmacsign = ""
                    def am_encKey_selfservicesign = ""
                    def am_cert_es256 = ""
                    def am_cert_es256Key = ""
                    def am_cert_es384 = ""
                    def am_cert_es384Key = ""
                    def am_cert_es512 = ""
                    def am_cert_es512Key = ""
                    def am_cert_general = ""
                    def am_cert_generalKey = ""
                    def am_cert_rsajwtsign = ""
                    def am_cert_rsajwtsignKey = ""
                    def am_cert_selfserviceenc = ""
                    def am_cert_selfserviceencKey = ""
                    def am_certificate = ""
                    def am_certificateKey = ""

                    println ""
                    println "-> Getting Config Store secrets"
                    cs_certificate = base64Decode(getSecretFromCredentials("${env_name}", "${market}", "CS_CERTIFICATE"))
                    cs_certificateKey = base64Decode(getSecretFromCredentials("${env_name}", "${market}", "CS_CERTIFICATE_KEY"))
                    cs_amConfigAdminPassword = getSecretFromCredentials("${env_name}", "${market}", "CS_AM_CONFIG_ADMIN_PASSWORD")
                    cs_configStoreCertPwd = getSecretFromCredentials("${env_name}", "${market}", "CS_CONFIG_STORE_CERT_PWD")
                    cs_deploymentKey = getSecretFromCredentials("${env_name}", "${market}", "CS_DEPLOYMENT_KEY")
                    cs_monitorUserPassword = getSecretFromCredentials("${env_name}", "${market}", "CS_MONITOR_USER_PASSWORD")
                    cs_rootUserPassword = getSecretFromCredentials("${env_name}", "${market}", "CS_ROOT_USER_PASSWORD")
                    cs_truststorePwd = getSecretFromCredentials("${env_name}", "${market}", "CS_TRUSTSTORE_PWD")
                    println "-- Done"

                    println ""
                    println "-> Getting Replication Server secrets"
                    rs_certificate = base64Decode(getSecretFromCredentials("${env_name}", "${market}", "RS_CERTIFICATE"))
                    rs_certificateKey = base64Decode(getSecretFromCredentials("${env_name}", "${market}", "RS_CERTIFICATE_KEY"))
                    rs_deploymentKey = getSecretFromCredentials("${env_name}", "${market}", "RS_DEPLOYMENT_KEY")
                    rs_keystorePwd = getSecretFromCredentials("${env_name}", "${market}", "RS_KEYSTORE_PWD")
                    rs_monitorUserPassword = getSecretFromCredentials("${env_name}", "${market}", "RS_MONITOR_USR_PWD")
                    rs_rootUserPassword = getSecretFromCredentials("${env_name}", "${market}", "RS_ROOT_USER_PWD")
                    rs_truststorePwd = getSecretFromCredentials("${env_name}", "${market}", "RS_TRUSTSTORE_PWD")
                    println "-- Done"
                    println ""

                    println ""
                    println "-> Getting User Store secrets"
                    us_amIdentityStoreAdminPassword = getSecretFromCredentials("${env_name}", "${market}", "US_AM_IDENTITY_STORE_ADMIN")
                    us_deploymentKey = getSecretFromCredentials("${env_name}", "${market}", "US_DEPLOYMENT_KEY")
                    us_monitorUserPassword = getSecretFromCredentials("${env_name}", "${market}", "US_MONITOR_USER_PWD")
                    us_rootUserPassword = getSecretFromCredentials("${env_name}", "${market}", "US_ROOT_USER_PWD")
                    us_truststorePwd = getSecretFromCredentials("${env_name}", "${market}", "US_TRUSTSTORE_PWD")
                    us_userStoreCertPwd = getSecretFromCredentials("${env_name}", "${market}", "US_USER_STORE_CERT_PWD")
                    us_certificate = base64Decode(getSecretFromCredentials("${env_name}", "${market}", "US_CERTIFICATE"))
                    us_certificateKey = base64Decode(getSecretFromCredentials("${env_name}", "${market}", "US_CERTIFICATE_KEY"))
                    println "-- Done"
                    println ""

                    println ""
                    println "-> Getting Token Store secrets"
                    ts_amCtsAdminPassword = getSecretFromCredentials("${env_name}", "${market}", "TS_AM_CTS_ADMIN_PWD")
                    ts_deploymentKey = getSecretFromCredentials("${env_name}", "${market}", "TS_DEPLOYMENT_KEY")
                    ts_monitorUserPassword = getSecretFromCredentials("${env_name}", "${market}", "TS_MONITOR_USER_PWD")
                    ts_rootUserPassword = getSecretFromCredentials("${env_name}", "${market}", "TS_ROOT_USER_PWD")
                    ts_tokenStoreCertPwd = getSecretFromCredentials("${env_name}", "${market}", "TS_TOKEN_STORE_CERT_PWD")
                    ts_truststorePwd = getSecretFromCredentials("${env_name}", "${market}", "TS_TRUSTSTORE_PWD")
                    ts_certificate = base64Decode(getSecretFromCredentials("${env_name}", "${market}", "TS_CERTIFICATE"))
                    ts_certificateKey = base64Decode(getSecretFromCredentials("${env_name}", "${market}", "TS_CERTIFICATE_KEY"))
                    println "-- Done"
                    println ""

                    println ""
                    println "-> Getting Access Manager secrets"
                    am_amAdminPwd = getSecretFromCredentials("${env_name}", "${market}", "AM_ADMIN_PWD")
                    am_cfgStoreDirMgrPwd = getSecretFromCredentials("${env_name}", "${market}", "AM_CFG_STORE_DIR_MGR_PWD")
                    am_ctsDirMgrPwd = getSecretFromCredentials("${env_name}", "${market}", "AM_CTS_DIR_MGR_PWD")
                    am_tomcatJKSPwd = getSecretFromCredentials("${env_name}", "${market}", "AM_TOMCAT_JKS_PWD")
                    am_truststorePwd = getSecretFromCredentials("${env_name}", "${market}", "AM_TRUSTSTORE_PWD")
                    am_userStoreDirMgrPwd = getSecretFromCredentials("${env_name}", "${market}", "AM_USER_STORE_DIR_MGR_PWD")
                    am_encKey_AmPwd = getSecretFromCredentials("${env_name}", "${market}", "AM_ENCKEY_AM_PWD")
                    am_encKey_directenc = getSecretFromCredentials("${env_name}", "${market}", "AM_ENCKEY_DIRECTENC")
                    am_encKey_hmacsign = getSecretFromCredentials("${env_name}", "${market}", "AM_ENCKEY_HMACSIGN")
                    am_encKey_selfservicesign = getSecretFromCredentials("${env_name}", "${market}", "AM_ENCKEY_SELF_SERVICE_SIGN")
                    am_cert_es256 = base64Decode(getSecretFromCredentials("${env_name}", "${market}", "AM_CERT_ES256"))
                    am_cert_es256Key = base64Decode(getSecretFromCredentials("${env_name}", "${market}", "AM_CERT_ES256_KEY"))
                    am_cert_es384 = base64Decode(getSecretFromCredentials("${env_name}", "${market}", "AM_CERT_ES384"))
                    am_cert_es384Key = base64Decode(getSecretFromCredentials("${env_name}", "${market}", "AM_CERT_ES384KEY"))
                    am_cert_es512 = base64Decode(getSecretFromCredentials("${env_name}", "${market}", "AM_CERT_ES512"))
                    am_cert_es512Key = base64Decode(getSecretFromCredentials("${env_name}", "${market}", "AM_CERT_ES512KEY"))
                    am_cert_general = base64Decode(getSecretFromCredentials("${env_name}", "${market}", "AM_CERT_GENERAL"))
                    am_cert_generalKey = base64Decode(getSecretFromCredentials("${env_name}", "${market}", "AM_CERT_GENERAL_KEY"))
                    am_cert_rsajwtsign = base64Decode(getSecretFromCredentials("${env_name}", "${market}", "AM_CERT_RAW_JWT_SIGN"))
                    am_cert_rsajwtsignKey = base64Decode(getSecretFromCredentials("${env_name}", "${market}", "AM_CERT_RAW_JWT_SIGNKEY"))
                    am_cert_selfserviceenc = base64Decode(getSecretFromCredentials("${env_name}", "${market}", "AM_CERT_SELF_SERVICE_ENC"))
                    am_cert_selfserviceencKey = base64Decode(getSecretFromCredentials("${env_name}", "${market}", "AM_CERT_SELF_SERVICE_ENC_KEY"))
                    am_certificate = base64Decode(getSecretFromCredentials("${env_name}", "${market}", "AM_CERTIFICATE"))
                    am_certificateKey = base64Decode(getSecretFromCredentials("${env_name}", "${market}", "AM_CERTIFICATE_KEY"))
                    println "-- Done"
                    println ""

                    docker.withRegistry('https://artifactory.global.standardchartered.com/', 'jenkins_deployer') {
                        helm3Image = docker.image("frogpl/helm3-base:latest")
                        retry(3) {
                            helm3Image.pull()
                        }
                        helm3Image.inside('-u root') {

                            loadEKSConfig(env_name, market, deployment_namespace )

                            String credentialId = "EKS_SSO_PASSWORD_APP_NS_${market.toUpperCase()}_${env_name.toUpperCase()}"
                            println("Using credential with id $credentialId")
                            withCredentials([string(credentialsId: credentialId, variable: 'sso_password_from_credentials')]) {
                                withEnv(["SSO_PASSWORD=${sso_password_from_credentials}"]) {

                                    awsSTSTokenAccess()

                                    sh """
                                         helm upgrade --install --debug --wait --timeout 10m0s \
                                            --set configstore.pod_name="$PODNAME_CS" \
                                            --set configstore.amConfigAdminPassword="${cs_amConfigAdminPassword}" \
                                            --set configstore.configStoreCertPwd="${cs_configStoreCertPwd}" \
                                            --set configstore.deploymentKey="${cs_deploymentKey}" \
                                            --set configstore.monitorUserPassword="${cs_monitorUserPassword}" \
                                            --set configstore.rootUserPassword="${cs_rootUserPassword}" \
                                            --set configstore.truststorePwd="${cs_truststorePwd}" \
                                            --set configstore.certificate="${cs_certificate}" \
                                            --set configstore.certificateKey="${cs_certificateKey}" \
                                            --set userstore.pod_name="$PODNAME_US" \
                                            --set userstore.amIdentityStoreAdminPassword="${us_amIdentityStoreAdminPassword}" \
                                            --set userstore.deploymentKey="${us_deploymentKey}" \
                                            --set userstore.monitorUserPassword="${us_monitorUserPassword}" \
                                            --set userstore.rootUserPassword="${us_rootUserPassword}" \
                                            --set userstore.truststorePwd="${us_truststorePwd}" \
                                            --set userstore.userStoreCertPwd="${us_userStoreCertPwd}" \
                                            --set userstore.certificate="${us_certificate}" \
                                            --set userstore.certificateKey="${us_certificateKey}" \
                                            --set tokenstore.pod_name="$PODNAME_TS" \
                                            --set tokenstore.amCtsAdminPassword="${ts_amCtsAdminPassword}" \
                                            --set tokenstore.deploymentKey="${ts_deploymentKey}" \
                                            --set tokenstore.monitorUserPassword="${ts_monitorUserPassword}" \
                                            --set tokenstore.rootUserPassword="${ts_rootUserPassword}" \
                                            --set tokenstore.tokenStoreCertPwd="${ts_tokenStoreCertPwd}" \
                                            --set tokenstore.truststorePwd="${ts_truststorePwd}" \
                                            --set tokenstore.certificate="${ts_certificate}" \
                                            --set tokenstore.certificateKey="${ts_certificateKey}" \
                                            --set replserver.pod_name="$PODNAME_RS" \
                                            --set replserver.certificate="${rs_certificate}" \
                                            --set replserver.certificateKey="${rs_certificateKey}" \
                                            --set replserver.deploymentKey="${rs_deploymentKey}" \
                                            --set replserver.keystorePwd="${rs_keystorePwd}" \
                                            --set replserver.truststorePwd="${rs_truststorePwd}" \
                                            --set replserver.monitorUserPassword="${rs_monitorUserPassword}" \
                                            --set replserver.rootUserPassword="${rs_rootUserPassword}" \
                                            --set am.pod_name="$PODNAME_AM" \
                                            --set am.amAdminPwd="${am_amAdminPwd}" \
                                            --set am.cfgStoreDirMgrPwd="${am_cfgStoreDirMgrPwd}" \
                                            --set am.ctsDirMgrPwd="${am_ctsDirMgrPwd}" \
                                            --set am.tomcatJKSPwd="${am_tomcatJKSPwd}" \
                                            --set am.truststorePwd="${am_truststorePwd}" \
                                            --set am.userStoreDirMgrPwd="${am_userStoreDirMgrPwd}" \
                                            --set am.encKey_AmPwd="${am_encKey_AmPwd}" \
                                            --set am.encKey_directenc="${am_encKey_directenc}" \
                                            --set am.encKey_hmacsign="${am_encKey_hmacsign}" \
                                            --set am.encKey_selfservicesign="${am_encKey_selfservicesign}" \
                                            --set am.cert_es256="${am_cert_es256}" \
                                            --set am.cert_es256Key="${am_cert_es256Key}" \
                                            --set am.cert_es384="${am_cert_es384}" \
                                            --set am.cert_es384Key="${am_cert_es384Key}" \
                                            --set am.cert_es512="${am_cert_es512}" \
                                            --set am.cert_es512Key="${am_cert_es512Key}" \
                                            --set am.cert_general="${am_cert_general}" \
                                            --set am.cert_generalKey="${am_cert_generalKey}" \
                                            --set am.cert_rsajwtsign="${am_cert_rsajwtsign}" \
                                            --set am.cert_rsajwtsignKey="${am_cert_rsajwtsignKey}" \
                                            --set am.cert_selfserviceenc="${am_cert_selfserviceenc}" \
                                            --set am.cert_selfserviceencKey="${am_cert_selfserviceencKey}" \
                                            --set am.certificate="${am_certificate}" \
                                            --set am.certificateKey="${am_certificateKey}" \
                                            --set idm.pod_name="$PODNAME_IDM" \
                                            --set secrets.namespace="$DEPLOYMENT_NAMESPACE" \
                                            --set env_name="$env_name" \
                                            --namespace "$DEPLOYMENT_NAMESPACE" \
                                            forgerock-secrets-and-configmaps secrets-and-configs/kubernetes/
                                       """
                                }
                            }
                        }
                    }
                }
            }
        }// end-stage('Deploy Secrets From Jenkins')
        stage('Deploy a DS Component(s)') {
            when { 
                anyOf{
                    expression { params.DEPLOY_RS } 
                    expression { params.DEPLOY_TS } 
                    expression { params.DEPLOY_US } 
                }
            }
            steps {
                script {
                    deploy_components(env_name, market, deployment_namespace, 'DS')
                }
            }
        }

        stage('Deploy AM') {
            when { expression { params.DEPLOY_AM } }
            steps {
                script {
                    deploy_components(env_name, market, deployment_namespace, 'AM')
                }
            }
        }//stage('Deploy AM')

    }//stages-end

}//pipeline-end