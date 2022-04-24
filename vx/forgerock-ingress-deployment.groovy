@Library('SharedLibraryFROG@master') _
def loadEKSConfig(env_name, market, deployment_namespace ) {
        println("★★★ Loading... eks/${env_name}/${market}/${deployment_namespace}.groovy file ★★★ ")
        load "${WORKSPACE}/eks/${env_name}/${market}/${deployment_namespace}.groovy"
        println("★★★ Loading... eks/${env_name}/proxies.groovy file ★★★ ")
        load "${WORKSPACE}/eks/${env_name}/proxies.groovy"
        println("★★★ Loading... eks/${env_name}/certificate.groovy file ★★★ ")
        load "${WORKSPACE}/eks/${env_name}/certificate.groovy"
        println("★★★ Loading eks config complete ★★★ ")
}

def awsSTSTokenAccess() {
    sh '''
    aws-sts login --skip-prompt --hostname sts01.internal.sc.com -u $ADUSER -a $ACCOUNT_ID --role $ROLE
    aws eks update-kubeconfig --name $EKS_CLUSTER --region $REGION
    kubectl config set-context \$(kubectl config current-context) --namespace=${DEPLOYMENT_NAMESPACE}
    '''
}

def getENV(jobName){
    envn = jobName.contains('OAT') ? 'oat' : jobName.contains('STAGING') ? 'stg' : jobName.contains('UAT') ? 'uat' : jobName.contains('DEV') ? 'dev' : jobName.contains('PT') ? 'pt' : 'none'
    return envn
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
        booleanParam(name: "CLEAR_INGRESS", defaultValue: false)
        booleanParam(name: "DEPLOY_INGRESS", defaultValue: false)
        string(defaultValue: 'sg', name: 'MARKET_NAME', trim: true)
        string(defaultValue: 'application-1', name: 'DEPLOYMENT_NAMESPACE', trim: true)
    } //parameters

    environment {
        PODNAME_INGRESS = "forgerock-ingress"
        deployment_namespace = "${params.DEPLOYMENT_NAMESPACE}"
        NAMESPACE = "${DEPLOYMENT_NAMESPACE}"
        market = "${params.MARKET_NAME}"
        env_name = getENV(JOB_NAME)
        ENV_TYPE = "fr7"
        SERVICENAME_AM = "forgerock-access-manager"
    }//environment

    stages{
        // stage('Verify User'){
        //     steps{
        //         script{
        //             validator.validateUser(env_name)
        //         }
        //     }
        // }
        stage('Clear Ingress') {
            when { expression { params.CLEAR_INGRESS } }
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
                                    try{
                                        sh "helm uninstall forgerock-ingress"
                                    }catch(exception){
                                        echo "Clean-up ingress for Namespace ${DEPLOYMENT_NAMESPACE} failed"
                                    }
                                    debugDeploymentEvents(DEPLOYMENT_NAMESPACE)
                                }
                            }
                        }
                    }
                }
            }
        }//stage('Deploy Ingress')
        stage('Deploy Ingress') {
            when { expression { params.DEPLOY_INGRESS } }
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
            }
        }//stage('Deploy Ingress')
    }
}