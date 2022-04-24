#!/usr/bin/env bash

##############################################################################
# Forgerock Directory Server (DS) Shared functions
#
# These are typically installed to a known location, such as:
#  - /opt/ds/scripts/forgerock-ds-shared-functions.sh or
#  - ${DS_SCRIPTS}/forgerock-ds-shared-functions.sh
#
# Typically you would 'source' these into another script, e.g.
#  - source /opt/ds/scripts/forgerock-ds-shared-functions.sh or
#  - source ${DS_SCRIPTS}/forgerock-ds-shared-functions.sh
#
# Important:
# Ensure any changes made are compatible with all scripts that
# use these functions.
##############################################################################

# Inherit Midhsips shared functions
. ${MIDSHIPS_SCRIPTS}/midshipscore.sh

set +H #Disablng Historical Expansion to allow things like ! in varibles
errorFound="false"
path_tmpFolder="/tmp/ds"
path_keystoreFile="${DS_APP}/keystore.p12"
path_keystorePinFile="${DS_APP}/keystore.pin"
path_rootUserPasswordFile="${path_tmpFolder}/rootUserPassword.txt"
path_monitorUserPasswordFile="${path_tmpFolder}/monitorUserPassword.txt"
podIndx=$(echo "${HOSTNAME//[!0-9]/}")
file_properties=""
file_schema=""
rootUserPassword=""
monitorUserPassword=""
amIdentityStoreAdminPassword=""
userStoreCertPwd=""
truststorePwd=""
certificate=""
certificateKey=""

# ****************************************************************************
# This fucntion ensures the Forgerock Directory Server (DS) binaries are in the
# required location for the execution of the sahred functions in this script.
# Must be executed before running first DS binary command on server.
# ****************************************************************************
function prepareServerFolders() {
  echo "-> Preparing DS server folders"
  tmpPath_SetupFiles="${DS_HOME}/setupFiles"
  if [ -d "${tmpPath_SetupFiles}" ] && [ -n "$(ls -A "${tmpPath_SetupFiles}")" ]; then
    if [ ! -d "${DS_INSTANCE}" ] || [ -z "$(ls -A "${DS_INSTANCE}")" ]; then
      echo "--  ${DS_INSTANCE} does not exists or is Empty"
      # This needs to be done after the pvc is mounted to ensure on pod termination it can resume.
      # DS files are moved into the pvc location. Make sure Kubernetes pvc is mounted to ${DS_APP}
      echo "-- Copying setup files .."
      cp -R "${tmpPath_SetupFiles}/." "${DS_APP}/"
    fi
    # Remove instance lock file if already exists
    tmp_instance_file=${DS_INSTANCE}/instance.loc
    if [ -f "${tmp_instance_file}" ]; then
      echo "--  ${tmp_instance_file} exists"
      echo "-- Deleting .."
      rm -f "${DS_INSTANCE}/instance.loc"
    fi
  else
    echo "-- ERROR: DS Setup Files not found at '${tmpPath_SetupFiles}'"
    echo "-- Exiting ..."
    exit 1
  fi
  echo "-- Done"
  echo ""
}

# ****************************************************************************
# This function checks if a kubernetes pod is alive. It will wait for a
# predefined time until the server is alive before it exits.
#
# Parameters:
#  - ${1}: errorFound return value. Boolean string true or false
#  - ${2}:
#    Kubernetes service URL for pod. Format for statefulset pod service URL is
#    {hostname}.{service-name}.{POD_NAMESPACE}.svc.${CLUSTER_DOMAIN}
#  - ${3}:
#    The protocol to use http, https
#  - ${4}:
#    The port number to make the call using. E.g. 8443
#  - ${5}:
#    This is a multipler for the ${checkFrequency}
# ****************************************************************************
function checkServerIsAlive() {
  svcURL=${2}
  topology=${3}
  port=${4}
  srv_aliveCounter=1
  checkFrequency=10
  responseCodeExpected="200"
  responseCodeActual="000"
  srv_aliveURL="${topology}://${svcURL}:${port}/alive"

  if [ -z ${5} ] || [ "${5}" == "null" ]; then
    noOfChecks=24
  else
    noOfChecks=${5}
  fi
  echo "-> Checking if Server (${svcURL}) is alive"
  echo "   URL to check is ${srv_aliveURL}"
  echo "   HTTP Response Code expected is ${responseCodeExpected}"
  while [[ ${responseCodeActual} != ${responseCodeExpected} ]]; do
    responseCodeActual=$(curl -k --head --location --connect-timeout 5 --write-out %{http_code} --silent --output /dev/null ${srv_aliveURL})
    echo "-- (${srv_aliveCounter}/${noOfChecks}) Returned ${responseCodeActual}. Waiting ${checkFrequency} seconds ..."
    sleep ${checkFrequency}

    if [ ${srv_aliveCounter} == ${noOfChecks} ]; then
      secondsWaitedFor=$((${checkFrequency} * ${noOfChecks}))
      echo "-- Waited for ${secondsWaitedFor} seconds and NO valid response"
      echo "-- Exiting"
      eval "${1}='true'"
      exit 1
    fi
    srv_aliveCounter=$((${srv_aliveCounter} + 1))
  done
  echo "-- Server (${srv_aliveURL}) available"
  echo "-- Done"
  echo ""
}

# ****************************************************************************
# This function checks if a Forgerock K8s Directory Services (DS) pod is
# Healthy. It will wait for an apredefined time until the server responds
# before it exits.
#
# Parameters:
#  - ${1}: errorFound return value. Boolean string true or false
#  - ${2}:
#    Kubernetes service URL for pod. Format for statefulset pod service URL is
#    {hostname}.{service-name}.{POD_NAMESPACE}.svc.${CLUSTER_DOMAIN}
#  - ${3}: Topology. E.g. 'http' or 'https'
#  - ${4}: TCP Port number. E.g. '8443'
#  - ${5}: This is a multipler for the ${checkFrequency}
# ****************************************************************************
function checkDSisHealthy() {
  svcURL=${2}
  topology=${3}
  port=${4}
  srv_helthyCounter=1
  checkFrequency=10
  noOfChecks=${5}
  responseCodeExpected="200"
  responseCodeActual=
  srv_helthyURL="${topology}://${svcURL}:${port}/healthy"

  if [ -z ${5} ] || [ "${5}" == "null" ]; then
    noOfChecks=24
  else
    noOfChecks=${5}
  fi

  echo "-> Checking if DS Server (${svcURL}) is Healthy"
  echo "   URL to check is ${srv_helthyURL}"
  echo "   HTTP Response Code expected is ${responseCodeExpected}"
  while [[ "${responseCodeActual}" != "${responseCodeExpected}" ]];
  do
    responseCodeActual="$(curl -sk -o /dev/null -w "%{http_code}" "${srv_helthyURL}")"
    echo "-- (${srv_helthyCounter}/${noOfChecks}) Returned ${responseCodeActual}. Waiting ${checkFrequency} seconds ..."
    sleep ${checkFrequency}

    if [ ${srv_helthyCounter} == ${noOfChecks} ]; then
      secondsWaitedFor=$(( checkFrequency * noOfChecks ))
      echo "-- Waited for ${secondsWaitedFor} seconds and NO valid response"
      echo "-- Exiting"
      eval "${1}='true'"
      return 2
    fi
    srv_helthyCounter=$(( srv_helthyCounter + 1 ))
  done
  eval "${1}='false'"
  echo "-- Server (${svcURL}) is Healthy"
  echo "-- Done"
  echo ""
}

# ****************************************************************************
# This functions configures the below replications server thresholds for the
# desired replication servers:
# - disk-low-threshold
# - disk-full-threshold
#
# Parameters:
#  - ${svcURL}:
#    Kubernetes service URL for the pod. Format for statefulset pod service URL is
#    {hostname}.{service-name}.{POD_NAMESPACE}.svc.${CLUSTER_DOMAIN}
# - ${path_bindPasswordFile}: Path to text file with password
# - ${diskLowThreshold}:
#   At which point to throw a warning that server is running low on disk space
#   Example/Format 10 GB
# - ${diskFullThreshold}:
#   At which point (disk free space) to throw a Error and turn off replication
#   Should be smaller than the diskLowThreshold. Example/Format 5 GB
# ****************************************************************************
function configureReplicationThreshold() {
  svcURL=${1}
  adminConnectorPort=${2}
  rootUserDN=${3}
  path_bindPasswordFile=${4}
  diskLowThreshold=${5}
  diskFullThreshold=${6}
  echo "-> Configuring Replication disk space threshold:"
  echo "-- Server: ${svcURL}"
  echo "-- disk-low-threshold:${diskLowThreshold}"
  echo "-- disk-full-threshold:${diskFullThreshold}"
  ${DS_APP}/bin/dsconfig set-replication-server-prop \
  --hostname "${svcURL}" \
  --port ${adminConnectorPort} \
  --bindDN "${rootUserDN}" \
  --bindPasswordFile "${path_bindPasswordFile}" \
  --provider-name "Multimaster Synchronization" \
  --set "disk-low-threshold:${diskLowThreshold}" \
  --set "disk-full-threshold:${diskFullThreshold}" \
  --trustAll \
  --no-prompt
  echo "-- Done"
  echo ""
}

# ****************************************************************************
# This functions adds a trust manager provider to access the server truststore
#
# Parameters:
#  - ${svcURL}:
#    Kubernetes service URL for the pod. Format for statefulset pod service URL is
#    {hostname}.{service-name}.{POD_NAMESPACE}.svc.${CLUSTER_DOMAIN}
#  - ${path_bindPasswordFile}: Path to the file with the bind password for 'Directory Manager'
#  - ${path_truststoreFile}: The path to the truststore file import the pkcs12 cert
#  - ${pwd_keystore}: pkcs12 keystore password
#  - ${pwd_truststore}: Truststore password
# ****************************************************************************
function allowTruststoreAccessByDS() {
  svcURL=${1}
  adminConnectorPort=${2}
  rootUserDN=${3}
  path_bindPasswordFile=${4}
  path_truststoreFile=${5}
  pwd_truststore=${6}
  echo "-> Adding a trust manager provider to access the server truststore"
  ${DS_APP}/bin/dsconfig create-trust-manager-provider \
    --hostname "${svcURL}" \
    --port ${adminConnectorPort} \
    --bindDN "${rootUserDN}" \
    --bindPasswordFile ${path_bindPasswordFile} \
    --type file-based \
    --provider-name "Trust Manager" \
    --set enabled:true \
    --set trust-store-file:${path_truststoreFile} \
    --set trust-store-pin:"${pwd_truststore}" \
    --trustAll \
    --no-prompt
  echo "-- Done"
  echo ""
}

# ****************************************************************************
# This function sets the Global Server ID for the Forgerock Directory Server (DS)
#
# Parameters:
#  - ${svcURL}:
#    Kubernetes service URL for the pod. Format for statefulset pod service URL is
#    {hostname}.{service-name}.{POD_NAMESPACE}.svc.${CLUSTER_DOMAIN}
#  - ${path_bindPasswordFile}: Path to the file with the bind password for 'Directory Manager'
#  - ${srvGlbID}: The Global ID for the DS instnace. Value is an Integer.
# ****************************************************************************
function setDSglobalID() {
  svcURL=${1}
  adminConnectorPort=${2}
  rootUserDN=${3}
  path_bindPasswordFile=${4}
  srvGlbID=${5}
  echo "-> Setting Server Global ID to ${srvGlbID}"
  ${DS_APP}/bin/dsconfig set-global-configuration-prop \
  --hostname "${svcURL}" \
  --port ${adminConnectorPort} \
  --bindDN "${rootUserDN}" \
  --bindPasswordFile "${path_bindPasswordFile}" \
  --set server-id:${srvGlbID} \
  --trustAll \
  --no-prompt
  echo "-- Done"
  echo ""
}

# ****************************************************************************
# This function sets the Replication Server ID for the Forgerock Directory Server (DS)
#
# Parameters:
#  - ${svcURL}:
#    Kubernetes service URL for the pod. Format for statefulset pod service URL is
#    {hostname}.{service-name}.{POD_NAMESPACE}.svc.${CLUSTER_DOMAIN}
#  - ${path_bindPasswordFile}: Path to the file with the bind password for 'Directory Manager'
#  - ${srvGlbID}: The Global ID for the DS instnace. Value is an Integer.
# ****************************************************************************
function setDSreplicationID() {
  svcURL=${1}
  adminConnectorPort=${2}
  rootUserDN=${3}
  path_bindPasswordFile=${4}
  srvGlbID=${5}
  echo "-> Setting Server Global ID to ${srvGlbID}"
  ${DS_APP}/bin/dsconfig set-replication-server-prop \
  --provider-name "Multimaster Synchronization" \
  --hostname "${svcURL}" \
  --port ${adminConnectorPort} \
  --bindDN "${rootUserDN}" \
  --bindPasswordFile "${path_bindPasswordFile}" \
  --set replication-server-id:${srvGlbID} \
  --trustAll \
  --no-prompt
  echo "-- Done"
  echo ""
}

# ****************************************************************************
# This function displays the current replication status of the specified
# Directory Server/Services (DS)
#
# Parameters:
#  - ${1}: Kubernetes service URL for the DS pod. Format for statefulset pod service URL is
#          {hostname}.{service-name}.{POD_NAMESPACE}.svc.${CLUSTER_DOMAIN}
#  - ${2}: Path to the file with the bind password for 'Directory Manager'
#  - ${3}: Administration port
#  - ${4}: bindDN
# ****************************************************************************
function getReplicationStatus() {
  currHost=${1}
  path_rootUserPasswordFile=${2}
  adminConnectorPort=${3}
  bindDN=${4}
  echo "-> Getting Replication status for '${currHost}' ..."
  ${DS_APP}/bin/dsrepl status \
    --hostname "${currHost}" \
    --bindDn "${bindDN}" \
    --bindPasswordFile "${path_rootUserPasswordFile}" \
    --port ${adminConnectorPort} \
    --trustAll --showReplicas --no-prompt
  echo "-- Done"
  echo ""
}

# ****************************************************************************
# This function sets up a Direcotry Server (DS) for use with Self Replication
#
# Parameters:
#  - ${1}: SELF_REPLICATE             ${2}: rootUserDN
#  - ${3}: rootUserPasswordFile       ${4}: httpPort or httpsPort
#  - ${5}: adminConnectorPort         ${6}: DS_BASE_DN
#  - ${7}: diskLowThreshold           ${8}: diskFullThreshold
#  - ${9}: http or https              ${10}: reverseReplication
# ****************************************************************************
function setupSelfRepl_ifEnabled(){
  # Replication needs to only be setup once on the store
  # We will be setting up from the this instance and the previous instance
  errFound="false"
  local self_replicate="${1}"
  local hostnamePrefix=${HOSTNAME//[0-9]/}
  local podIndx_curr=$(echo "${HOSTNAME//[!0-9]/}")
  local httpOrHttps=${9,,}
  local reverseReplication=${10,,}

  if [ -z ${httpOrHttps} ] || [ "${httpOrHttps}" == "null" ] && [ "${httpOrHttps}" != "http" ] && [ "${httpOrHttps}" != "https" ]; then
    httpOrHttps="http"
  fi
  if [ -z ${reverseReplication} ] || [ "${reverseReplication}" == "null" ] && [ "${reverseReplication}" != "true" ] && [ "${httpOrHttps}" != "false" ]; then
    reverseReplication="false"
  fi

  if [ "${self_replicate,,}" == "true" ] && [ "${podIndx_curr}" -gt "0" ]; then
    podIndx_prev=$((${podIndx_curr}-1))

    if [ "${reverseReplication,,}" == "false" ]; then
      svcURL_source="${hostnamePrefix}${podIndx_curr}.${POD_SERVICE_NAME}.${POD_NAMESPACE}.svc.${CLUSTER_DOMAIN}"
      svcURL_dest="${hostnamePrefix}${podIndx_prev}.${POD_SERVICE_NAME}.${POD_NAMESPACE}.svc.${CLUSTER_DOMAIN}"
    else
      svcURL_source="${hostnamePrefix}${podIndx_prev}.${POD_SERVICE_NAME}.${POD_NAMESPACE}.svc.${CLUSTER_DOMAIN}"
      svcURL_dest="${hostnamePrefix}${podIndx_curr}.${POD_SERVICE_NAME}.${POD_NAMESPACE}.svc.${CLUSTER_DOMAIN}"
    fi

    echo "-> Setting up DS with self replication"
    echo ""
    echo "-- SELF_REPLICATE is set to '${SELF_REPLICATE,,}'"
    echo "-- reverseReplication is ${reverseReplication}"
    echo "-- Source Pod is ${svcURL_source}"
    echo "-- Destination Pod is ${svcURL_dest}"
    echo ""

    checkDSisHealthy errFound "${svcURL_dest}" "${httpOrHttps}" "${4}"
    if [ "${errFound}" == "false" ]; then
      checkServerIsAlive errFound "${svcURL_source}" "${httpOrHttps}" "${4}"
      if [ "${errFound}" == "false" ]; then
        configureReplicationThreshold "${svcURL_source}" ${5} "${2}" "${3}" "${7}" "${8}"
        configureReplicationThreshold "${svcURL_dest}" ${5} "${2}" "${3}" "${7}" "${8}"
        initializeReplication "${svcURL_source}" "${svcURL_dest}" "${3}" "${6}" ${5} "${2}"
        #getReplicationStatus "${svcURL_source}" "${3}" "${5}" "${2}"
      fi
    fi
  else
    echo "-- Either this is the first POD in StatefulSet and/or SELF_REPLICATE is not set to 'true'"
    echo "-- SELF_REPLICATE set to ${1}"
    echo "-- The current POD is ${HOSTNAME}"
    echo ""
  fi
}

# ****************************************************************************
# This function initializes replication for from one Directory Server (DS)
# to another server in the topology.
#
# Parameters:
#  - ${1}: Kubernetes service URL for the source server. Format for statefulset pod service URL is
#          {hostname}.{service-name}.{POD_NAMESPACE}.svc.${CLUSTER_DOMAIN}
#  - ${2}: Destination DS Server ID
#  - ${3}: Path to the file with the bind password for 'Directory Manager'
#  - ${4}: baseDN to be replicated
#  - ${5}: Administration port
#  - ${6}: bindDN
# ****************************************************************************
function initializeReplication() {
  svcURL_source=${1}
  svcURL_dest=${2}
  path_bindPasswordFile=${3}
  baseDn=${4}
  adminConnectorPort=${5}
  bindDN=${6}

  echo "-> Replication Initialization Summary"
  echo "   Source: ${svcURL_source}"
  echo "   Destination: ${svcURL_dest}"
  echo ""

  echo "-- Getting Server ID for destination server (${svcURL_dest})"
  serverID=$(echo $(${DS_APP}/bin/dsconfig get-global-configuration-prop \
            --bindDN "${bindDN}" --record --bindPasswordFile "${path_bindPasswordFile}" \
            --hostname "${svcURL_dest}" --port ${adminConnectorPort} --property server-id \
            --trustAll --no-prompt) | tr -d '\n' | grep -oE '[^ ]+$')
  echo "-- Server ID is ${serverID}"
  echo "-- Done"
  echo ""

  echo "-- Initializing replication for ${baseDn}"
  ${DS_APP}/bin/dsrepl initialize \
  --baseDN "${baseDn}" \
  --bindDN "${bindDN}" \
  --bindPasswordFile "${path_bindPasswordFile}" \
  --hostname "${svcURL_source}" \
  --toServer "${serverID}" \
  --port ${adminConnectorPort} \
  --trustAll
  echo "-- Done"
  echo ""
}

# ****************************************************************************
# This function initializes replication for all Forgerock Directory Server (DS)
# servers in the topology.
#
# Parameters:
#  - ${1}: Kubernetes service URL for the source server. Format for statefulset pod service URL is
#          {hostname}.{service-name}.{POD_NAMESPACE}.svc.${CLUSTER_DOMAIN}
#  - ${2}: Path to the file with the bind password for 'Directory Manager'
#  - ${3}: baseDN to be replicated
#  - ${4}: Administration port
#  - ${5}: bindDN
# ****************************************************************************
function initializeReplication_allServers() {
  svcURL_source=${1}
  path_bindPasswordFile=${2}
  baseDn=${3}
  adminConnectorPort=${4}
  bindDN=${5}
  echo "-> Initializing replication for ${baseDn}"
  echo "   Source: ${svcURL_source}"
  echo "   Destination: All Servers"
  ${DS_APP}/bin/dsrepl initialize \
  --baseDN "${baseDn}" \
  --bindDN "${bindDN}" \
  --bindPasswordFile "${path_bindPasswordFile}" \
  --hostname "${svcURL_source}" \
  --port ${adminConnectorPort} \
  --toAllServers --trustAll
  echo "-- Done"
  echo ""
}

# ****************************************************************************
# This function starts the Directory Server (DS)
#
# Parameters:
#  - ${1}: type. Start DS in 'background' or 'foreground'
#  - ${2}: DS admin port for Online status. optional.
#  - ${3}: DS BindDN for online status. optional.
#  - ${4}: DS BindDN password for online status. optinal.
# ****************************************************************************
function startDS() {
  tmpAdminConnectorPort=${2}
  tmpBindDn=${3}
  tmpBindPassword=${4}
  echo "Starting Directory Server (DS)"
  echo "------------------------------"
  echo ""
  if [ "${1,,}" == "background" ]; then
    echo "-- Server starting in background ..."
    nohup ${DS_APP}/bin/start-ds > ${path_tmpFolder}/serverstart.log 2>&1 </dev/null &
    echo "-- Waiting 30 secs for server to finish starting up"
    sleep 30
    cat ${path_tmpFolder}/serverstart.log
    echo "-- Done"
    echo ""
  elif [ "${1,,}" == "foreground" ]; then
    echo "-> Cleaning up ..."
    rm -rf ${path_tmpFolder}/*
    echo "-- Done"

    if [ -n "${2}" ] && [ -n "${3}" ] && [ -n "${4}" ]; then
      echo "-> Getting Server Status (online)"
      ${DS_APP}/bin/status --trustAll \
        --hostname localhost --port ${tmpAdminConnectorPort} \
        --bindDn "${tmpBindDn}" --bindPassword "${tmpBindPassword}"
      echo ""
    else
      echo "-> Getting Server Status (offline)"
      ${DS_APP}/bin/status --offline
    fi
    echo "-> Server starting in foreground ..."
    ${DS_APP}/bin/start-ds --nodetach
  fi
}

# ****************************************************************************
# This function stop the Directory Server (DS)
# ****************************************************************************
function stopDS() {
  echo "-> Stopping server ..."
  ${DS_APP}/bin/stop-ds
  echo "-- Done"
  echo ""
}

# ****************************************************************************
# Check if Directory Server (DS) is installed before starting in the foreground
#
# Parameters:
#  - ${1}: type. Start DS in 'background' or 'foreground'
# ****************************************************************************
function startDS_ifInstalled() {
  if [ -f "${DS_INSTANCE}/locks/server.lock" ]; then
    echo "-> Removing ${DS_INSTANCE}/locks/server.lock from potential previous pod termination"
    rm -f ${DS_INSTANCE}/locks/server.lock
    echo "-- Done"
    echo ""
  fi

  if [ -d "${DS_INSTANCE}/db" ]; then
    echo "Directory Server already configured"
    echo "-----------------------------------"
    echo "-- ${DS_INSTANCE}/db found. Proceeding to start DS ..."
    echo ""
    startDS "foreground"
  fi
}

# ****************************************************************************
# Detect Pod resources and update JVM as required
# ****************************************************************************
function optimizeJVMforPod(){
  echo "-> Java Experimental VM Settings"
  java -XX:+UnlockExperimentalVMOptions -XshowSettings:vm -version
  echo ""
}

# ****************************************************************************
# This function checks disables HTTP and LDAP handlers for Directory Server (DS)
#
# Parameters:
#  - ${1}: DISABLE_INSECURE_COMMS. A 'true' or 'false'
#  - ${2}: Kubernetes service URL for the DS server to update. Format for statefulset pod service URL is
#          {hostname}.{service-name}.{POD_NAMESPACE}.svc.${CLUSTER_DOMAIN}
#  - ${3}: Administration port
#  - ${4}: rootUserDN
#  - ${5}: rootUserPasswordFile
# ****************************************************************************
function disableInsecureCommsDS()  {
  if [ "${1}" == "true" ]; then
    echo "Disabling Insecure Communications (HTTP and LDAP)"
    echo "-------------------------------------------------"
    setDSHandlerStatus  "${2}" ${3} "${4}" "${5}" "LDAP" "false"
    setDSHandlerStatus  "${2}" ${3} "${4}" "${5}" "HTTP" "false"
  else
    echo "-> Disabling Confidentiality Mode / Secure Authentication"
    # To resolve the error: Confidentiality Required
    ${DS_APP}/bin/dsconfig set-password-policy-prop \
        --policy-name Default\ Password\ Policy \
        --set require-secure-authentication:false \
        --hostname "${2}" \
        --port ${3} \
        --bindDn "${4}" \
        --bindPasswordFile "${5}" \
        --trustAll \
        --no-prompt
  fi
  echo "-- Done"
  echo ""
}

# ****************************************************************************
# This function checks if a custom javaProperties file is required and if so,
# downloads and load it onto the server.
#
# Parameters:
#  - ${1}: 'true' or 'false' variable indicating whether or not to use a custom javaProperties file
#  - ${2}: Name of property in Secrets Manager that holds the encoded javaProperties file contents
#  - ${3}: Secrets Mode. Accepts 'k8s' or 'REST'
#  - ${4}: Secrets Manager URL
#  - ${5}: Secrets folder path in K8s mode
#  - ${6}: Name of Secrets file or Path to secrets in Manager
#  - ${7}: Token to access Secrets Manager
# ****************************************************************************
function setupCustomJavaProperties()  {
  useCustomJavaProp="${1}"
  tmpSecretKeyName="${2}"
  tmpSecretsMode="${3}"
  tmpSecretsMngrURL="${4}"
  tmpSecretsFolder="${5}"
  tmpSecretName=${6}
  tmpSecretMngrToken="${7}"
  tmpProps=
  echo "-> Entered function setupCustomJavaProperties"
  echo "-- useCustomJavaProp set to '${useCustomJavaProp}'"
  if [ "${useCustomJavaProp}" == "true" ]; then
    echo "-- Getting custom javaProperties from Vault"
    getSecretAndConfig tmpProps "${tmpSecretsMode}" "${tmpSecretsMngrURL}" "${tmpSecretsFolder}" "${tmpSecretKeyName}" "${tmpSecretName}" "${tmpSecretMngrToken}" "true"
    if [ -z "${tmpProps}" ]; then
      echo "-- ${tmpSecretKeyName} not found in VAULT"
      echo "-- Exiting ..."
      echo ""
      errorFound="true"
    else
      echo "-- Loading javaProperties as variables"
      filename_tmp=${path_tmpFolder}/javaProperties
      echo "-- Coping javaProperties to ${filename_tmp}"
      echo "${tmpProps}" | base64 --decode > ${filename_tmp}
      cp -R "${filename_tmp}" "${DS_INSTANCE}/config/java.properties"
      echo "-- Done"
      echo ""
    fi
  else
    echo "-- Doing nothing as 'useCustomJavaProp' is not set to 'true'"
  fi
  echo "-- Done"
  echo ""
}

# ****************************************************************************
# This function disables a Directory Server (DS) Handler
#
# Parameters:
#  - ${1}: The hostname of the current host
#  - ${2}: The administration connection port for DS
#  - ${3}: The Root User DN for the DS
#  - ${4}: The path to the file containing the password for the Root User DN
#  - ${5}: DS Handler Name
#  - ${6}: Required status of DS Handler. Must be 'true' or 'false'
# ****************************************************************************
function setDSHandlerStatus()  {
  currHost=${1}
  dsAdminPort=${2}
  dsBindDN=${3}
  dsBindDNPasswordFile=${4}
  dsHandlerName=${5}
  dsHandlerStatus=${6,,}
  echo "-> Setting Handler(${dsHandlerName}) to ${dsHandlerStatus}"
  if [ "${dsHandlerStatus,,}" != "true" ] && [ "${dsHandlerStatus,,}" != "false" ]; then
    echo "-- Provided status (${dsHandlerStatus}) is not 'true' or 'false'."
    echo "-- Exiting function ..."
    echo "-- Done"
  else
    echo "-- Executing command ..."
    ${DS_APP}/bin/dsconfig set-connection-handler-prop \
      --hostname "${currHost}" \
      --port ${dsAdminPort} \
      --bindDN "${dsBindDN}" \
      --bindPasswordFile "${dsBindDNPasswordFile}" \
      --handler-name "${dsHandlerName}" \
      --set enabled:${dsHandlerStatus} \
      --trustAll \
      --no-prompt
    echo "-- Done"
  fi
  echo ""
}

# ****************************************************************************
# This function disables a Directory Server (DS) Handler
#
# Parameters:
#  - ${1}: VAULT_BASE_URL. The base URL for your secrets manager.
#          For instance: http://111.112.113.001:8200
#  - ${2}: VAULT_TOKEN access token for authenticating with your secrets manager.
#  - ${3}: JAVA_CACERTS full path.
#  - ${4}: truststorePwd
#  - ${5}: certsPaths: Bash array in format "ds_component1_vault_path!cert_alias" "ds_component1_vault_path!cert_alias"
#          For instance:
#           "forgerock/data/sit/token-store!token-store" "forgerock/data/sit/repl-server!repl-server"
#  - ${6}: certAlias: Alias provided in certsPaths of certificate tp add to DS keystore
#  - ${7}: path_keystoreFile: Full path to keystore File to be created
#  - ${8}: keyStorePwd: Pasword for Key Store to be created
#  - ${9}: Secres Mode: Whether 'REST' or 'k8s'
#  - ${10}: Array of k8s Secrets/ConfigMap paths
#
# Legal Notice: Installation and use of this script is subject to
# a license agreement with Midships Limited (a company registered
# in England, under company registration number: 11324587).
# This script cannot be modified or shared with another organisation
# unless approved in writing by Midships Limited.
# You as a user of this script must review, accept and comply with the
# license terms of each downloaded/installed package that is referenced
# by this script. By proceeding with the installation, you are accepting
# the license terms of each package, and acknowledging that your use of
# each package will be subject to its respective license terms.
# ****************************************************************************
function setupDS_TrustAndKeyStores() {
  VAULT_BASE_URL=${1}
  VAULT_TOKEN=${2}
  JAVA_CACERTS=${3}
  truststorePwd=${4}
  certsPaths=( ${5} )
  certAlias=${6}
  path_keystoreFile=${7}
  keyStorePwd=${8}
  tmpSecretsMode="${9}"
  arrK8sSecretsPaths=( ${10} )
  tmpK8sSecretsPathIndx=0
  echo "-> Entered setupDS_TrustAndKeyStore"
  echo ""
  arrLngth_REST=${#certsPaths[@]}
  arrLngth_k8s=${#arrK8sSecretsPaths[@]}
  echo "-- Checking JAVA_CACERTS by: ls -l $JAVA_CACERTS"
  ls -l $JAVA_CACERTS
  echo "-- Copying the JAVA_CACERTS from ${DS_HOME}/cacerts to ${JAVA_CACERTS} .."
  cp "${DS_HOME}/cacerts" "${JAVA_CACERTS}"
  chmod 644 $JAVA_CACERTS
  echo "-- Checking JAVA_CACERTS by: ls -l $JAVA_CACERTS"
  ls -l $JAVA_CACERTS
  echo "-- Done .."

  if [ "${arrLngth_REST}" -eq "${arrLngth_k8s}" ]; then
    changeTrustStorePassword "${JAVA_CACERTS}" "changeit" "${truststorePwd}"
    #certsPaths=( "${VAULT_CLIENT_PATH_US}!${certAlias}" "${VAULT_CLIENT_PATH_RS}!repl-server" )
    for certPath in "${certsPaths[@]}"
    do
      echo "[** Getting Certifiate and Key for below **]"
      urlOrPath=
      alias=
      if [ "${tmpSecretsMode^^}" == "REST" ]; then
        IFS=' !' read -ra pathDetails <<< "${certPath}"
        urlOrPath=${pathDetails[0]}
        alias=${pathDetails[1]}
        echo " > ${VAULT_BASE_URL}"
        echo " > ${urlOrPath} : ${alias}"
      elif [ "${tmpSecretsMode,,}" == "k8s" ]; then
        currK8scretsPathAndAlias=${arrK8sSecretsPaths[${tmpK8sSecretsPathIndx}]}
        IFS=' !' read -ra pathDetails <<< "${currK8scretsPathAndAlias}"
        urlOrPath=${pathDetails[0]}
        alias=${pathDetails[1]}
        echo " > ${urlOrPath}"
        echo " > ${alias}"
      fi
      echo ""
      if [[ -n "${urlOrPath}" ]] && [ "${urlOrPath}" != "null" ]; then
        getSecretAndConfig certificate "${tmpSecretsMode}" "${VAULT_BASE_URL}" "${urlOrPath}" "certificate" "${urlOrPath}" "${VAULT_TOKEN}" "true"
        getSecretAndConfig certificateKey "${tmpSecretsMode}" "${VAULT_BASE_URL}" "${urlOrPath}" "certificateKey" "${urlOrPath}" "${VAULT_TOKEN}" "true"
        if [ -z "${certificate}" ] || [ -z "${certificateKey}" ] || [ "${certificate}" == "null" ] || [ "${certificateKey}" == "null" ] || [ "${certificate}" == "" ] || [ "${certificateKey}" == "" ]; then
          echo "-- ERROR: Could not retrieve Cert and/or Key"
          exit 1
        else
          importCertIntoTrustStore "${alias}" "${certificate}" "${JAVA_CACERTS}" "${truststorePwd}"
          if [ "${alias}" == "${certAlias}" ]; then
            createPKCS12fromCerts "${alias}" "${certificate}" "${certificateKey}" "${path_keystoreFile}" "${keyStorePwd}"
          fi
          echo "-- Done"
          echo ""
        fi
      else
        echo "-- No path provided for alias ${alias}"
        echo ""
      fi
      tmpK8sSecretsPathIndx=$((tmpK8sSecretsPathIndx + 1))
    done
    echo "-- Exiting function"
    echo "-- Done"
    echo ""
  else
    echo "-- [ERROR]"
    echo "   Both arrays needs to be the mae size for the successfuly operation of this function."
    echo "   Please check prameters and retry. Below is a summary of Arrays:"
    echo "   > Array (REST) size is ${#arrLngth_REST[@]}"
    echo "   > Array (K8s) size is ${#arrLngth_k8s[@]}"
    echo "-- Exiting ..."
    exit 1
  fi
}
