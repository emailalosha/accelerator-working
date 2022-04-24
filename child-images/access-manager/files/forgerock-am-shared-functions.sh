#!/bin/bash
# ==================================================================
# Script to support the execution of the ForgeRock Access Management
# Kubernetes container on startup.

# Created 19/02/2020
# Copyright 2022: Midships
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
# ===================================================================
# Inherit Midhsips shared functions
. "${MIDSHIPS_SCRIPTS}/midshipscore.sh"
path_tmpFolder="/tmp/am"
mkdir -p "${path_tmpFolder}"

# ****************************************************************************
# This function checks if a Forgerock K8s pod is alive. It will wait for a
# predefined time until the server is alive before it exits.
#
# Parameters:
#  -s|--svc:
#    Kubernetes service URL for pod. Format for statefulset pod service URL is
#    {hostname}.{service-name}.{POD_NAMESPACE}.svc.cluster.local
#  -t|--type: Server type. 'ds' or 'am'
#  -c|--channel: Transfer Protocol E.g. 'http' or 'https'
#  -p|--port: TCP Port number. E.g. '8443'
#  -z|--resSuccessTotal: Number of successful resposes required
#  -y|--resCurrentSuccessCount: Current counter of successful resposes
#  -i|--iterations: Number of times to check for sucessful response
#  -r|--resCodeExpected: Expected HTTP resposne code required. Default 200
# ****************************************************************************
function checkServerIsAlive() {
  local svcURL=
  local srvType=
  local svcChannel="http"
  local svcPort="8443"
  local successCountReq=1
  local successCountCurr=1
  local noOfChecks=12
  local responseCodeExpected="200"
  local srv_aliveCounter=1
  local checkFrequency=5
  local srv_aliveURL=
  local responseCodeActual=

  # Getting Paramwters
  while [[ "$#" -gt 0 ]]
  do
    case ${1} in
      -s|--svc)
        local svcURL="${2}"
        ;;
      -t|--type)
        local srvType="${2}"
        ;;
      -c|--channel)
        local svcChannel="${2}"
        ;;
      -p|--port)
        local svcPort="${2}"
        ;;
      -z|--resSuccessTotal)
        if [ -n "${2}" ] && [ "${2}" -eq "${2}" ] 2>/dev/null; then
          local successCountReq="${2}"
        fi
        ;;
      -y|--resCurrentSuccessCount)
        if [ -n "${2}" ] && [ "${2}" -eq "${2}" ] 2>/dev/null; then
          local successCountCurr="${2}"
        fi
        ;;
      -i|--iterations)
        if [ -n "${2}" ] && [ "${2}" -eq "${2}" ] 2>/dev/null; then
          local noOfChecks="${2}"
        fi
        ;;
      -r|--resCodeExpected)
        if [ -n "${2}" ] && [ "${2}" -eq "${2}" ] 2>/dev/null; then
          local responseCodeExpected="${2}"
        fi
        ;;
      #
    esac
    shift
  done

  # Validating Paramwters
  if [ -z "${svcURL}" ] || [ "${svcURL}" == "null" ] || \
     [ -z "${srvType}" ] || [ "${srvType}" == "null" ] || \
     [ -z "${svcChannel}" ] || [ "${svcChannel}" == "null" ] || \
     [ -z "${svcPort}" ] || [ "${svcPort}" == "null" ] || \
     [ -z "${successCountReq}" ] || [ "${successCountReq}" == "null" ] || \
     [ -z "${successCountCurr}" ] || [ "${successCountCurr}" == "null" ] || \
     [ -z "${noOfChecks}" ] || [ "${noOfChecks}" == "null" ] || \
     [ -z "${responseCodeExpected}" ] || [ "${responseCodeExpected}" == "null" ]; then
    echo "-- ERROR: Ensure that none of the below parameters are Null or Empty for the checkServerIsAlive() function:"
    echo "   [svcURL] $svcURL"
    echo "   [srvType] $srvType"
    echo "   [svcChannel] $svcChannel"
    echo "   [svcPort] $svcPort"
    echo "   [successCountReq] $successCountReq"
    echo "   [successCountCurr] $successCountCurr"
    echo "   [noOfChecks] $noOfChecks"
    echo "   [responseCodeExpected] $responseCodeExpected"
    echo "-- Exiting..."
    echo ""
    exit 1
  fi

  if [ "${srvType}" == "am" ]; then
    srv_aliveURL="${svcChannel}://${svcURL}:${svcPort}/${AM_URI}/json/health/live"
  elif [ "${srvType}" == "ds" ]; then
    srv_aliveURL="${svcChannel}://${svcURL}:${svcPort}/alive"
  else
    srv_aliveURL="${svcURL}"
  fi

  echo "-> Checking if URL (${srv_aliveURL}) is alive"
  echo "   HTTP Response Code expected is ${responseCodeExpected}"

  if [ "${successCountCurr}" -le "${successCountReq}" ]; then
    echo "-- Checking for a successful response ${successCountCurr}/${successCountReq} time(s)"
    if [ "${successCountCurr}" -eq "${successCountReq}" ]; then
      successCountCurr=$((successCountCurr + 1))
    fi
  else
    echo "-- Checking for a successful response ${successCountReq}/${successCountReq} time(s)"
  fi

  while [[ "${responseCodeActual}" != "${responseCodeExpected}" ]];
  do
    responseCodeActual="$(curl -sk -o /dev/null -w "%{http_code}" "${srv_aliveURL}")"
    echo "-- (${srv_aliveCounter}/${noOfChecks}) Returned ${responseCodeActual}. Waiting ${checkFrequency} seconds ..."
    sleep ${checkFrequency}

    if [ ${srv_aliveCounter} == ${noOfChecks} ]; then
      secondsWaitedFor=$((checkFrequency * noOfChecks))
      echo "-- Waited for ${secondsWaitedFor} seconds and NO valid response"
      echo "-- Exiting"
      exit 1
    fi
    srv_aliveCounter=$((srv_aliveCounter + 1))
  done

  echo "-- Server (${srv_aliveURL}) available"
  if [ "${successCountCurr}" -le "${successCountReq}" ]; then
    echo "-- Waiting 10 before next attempt"
    sleep 10
    successCountCurr=$((successCountCurr + 1))
    checkServerIsAlive tmpErrFound "${svcURL}" "${srvType}" "${svcChannel}" "${svcPort}" ${successCountReq} ${successCountCurr} ${noOfChecks} "${responseCodeExpected}"
  else
    sleep ${checkFrequency}
  fi
  echo ""
}

# ****************************************************************************
# This function checks if a Forgerock K8s Directory Services (DS) pod is
# Healthy. It will wait for an apredefined time until the server responds
# before it exits.
#
# Parameters:
#  - ${1}:
#    Kubernetes service URL for pod. Format for statefulset pod service URL is
#    {hostname}.{service-name}.{POD_NAMESPACE}.svc.cluster.local
#  - ${2}: Topology. E.g. 'http' or 'https'
#  - ${3}: TCP Port number. E.g. '8443'
# ****************************************************************************
function checkDSisHealthy() {
  local svcURL=${1}
  local topology=${2}
  local port=${3}
  local srv_helthyCounter=1
  local checkFrequency=10
  local noOfChecks=30
  local srv_helthyURL="${topology}://${svcURL}:${port}/healthy"
  echo "-> Checking if DS Server (${srv_helthyURL}) is Healthy"
  while [[ "$(curl -sk -o /dev/null -w "%{http_code}" ${srv_helthyURL})" != "200" ]];
  do
    echo "-- (${srv_helthyCounter}/${noOfChecks}) Waiting ${checkFrequency} seconds ..."
    sleep ${checkFrequency}

    if [ ${srv_helthyCounter} == ${noOfChecks} ]; then
      secondsWaitedFor=$((${checkFrequency} * ${noOfChecks}))
      echo "-- Waited for ${secondsWaitedFor} seconds and no response"
      echo "-- Exiting"
      exit 1
    fi
    srv_helthyCounter=$((${srv_helthyCounter} + 1))
  done
  sleep ${checkFrequency}
  echo "-- Server (${srv_helthyURL}) is Healthy"
  echo ""
}

# ****************************************************************************
# This function checks if a HTTP/HTTPS URL is accessible. It will wait for an
# apredefined time until the server responds before it exits.
#
# Parameters:
#  - ${1}: errorFound return value. Boolean string true or false
#  - ${2}: URL to validate
#  - ${3}: Expected HTTP response code
# ****************************************************************************
function checkURLisAlive() {
  urlToValidate=${2}
  srv_aliveCounter=1
  checkFrequency=10
  noOfChecks=30
  responseCodeExpected=${3}
  responseCodeActual=

  if [ -z "${responseCodeExpected}" ] || [ "${responseCodeExpected}" == "null" ]; then
    responseCodeExpected="200"
  fi

  echo "-> Checking if URL (${urlToValidate}) is alive"
  echo "   HTTP Response Code expected is ${responseCodeExpected}"
  while [[ "${responseCodeActual}" != "${responseCodeExpected}" ]];
  do
    responseCodeActual="$(curl -sk -o /dev/null -w "%{http_code}" ${urlToValidate})"
    echo "-- (${srv_aliveCounter}/${noOfChecks}) Returned ${responseCodeActual}. Waiting ${checkFrequency} seconds ..."
    sleep ${checkFrequency}

    if [ ${srv_aliveCounter} == ${noOfChecks} ]; then
      secondsWaitedFor=$((${checkFrequency} * ${noOfChecks}))
      echo "-- Waited for ${secondsWaitedFor} seconds and NO valid response"
      echo "-- Exiting"
      eval "${1}='true'"
      return 2
    fi
    srv_aliveCounter=$((${srv_aliveCounter} + 1))
  done
  echo "-- Server (${urlToValidate}) is Alive"
  eval "${1}='false'"
  echo "-- Done"
  echo ""
}

# ****************************************************************************
# This function manages the Tomcat web container
#
# Parameters:
#  - ${1}: Tomcat Operation to perform
#       > "stop" : To Stop Tomcat
#       > "start-debug" : Start Tomcat in the background
#       > "start" : Start Tomcat in the forgeground
#  - "{2}: Access Manager HTTPS port"
# ****************************************************************************
function manageTomcat() {
  tmpAppRunning=
  tomcatAMurl=
  tomcatCmd=${1}
  tmpAMhttpsPort=${2}
  tmpAMuri=${3}
  [ -z "${tmpAMhttpsPort}" ] && tmpAMhttpsPort=8443
  [ -z "${tmpAMuri}" ] && tmpAMuri="am"
  tomcatAMurl="https://localhost:${tmpAMhttpsPort}/${tmpAMuri}"
  case ${tomcatCmd} in
    "stop")
      echo "-> Stoppting Tomcat"
      ${TOMCAT_HOME}/bin/catalina.sh stop
      checkURLisAlive tmpAppRunning "${tomcatAMurl}" "000"
      if [ "${tmpAppRunning,,}" == "false" ]; then
        echo "-- Tomcat stopped successfully"
      else
        echo "-- ERROR: Can't find evidence of successful Tomcat shutdown. Proceeding anyway ..."
      fi
      echo "-- Done"
      echo ""
    ;;
    "start-debug")
      echo "-> Starting Tomcat"
      ${TOMCAT_HOME}/bin/catalina.sh jpda start
      checkURLisAlive tmpAppStopped "${tomcatAMurl}" "302"
      if [ "${tmpAppStopped,,}" == "false" ]; then
        echo "-- Tomcat started successfully"
      else
        echo "-- ERROR: Can't find evidence of successful Tomcat startup. Proceeding anyway ..."
      fi
      echo "-- Done"
      echo ""
    ;;
    "start")
      echo "-> Starting Tomcat"
      ${TOMCAT_HOME}/bin/catalina.sh run –security
      ;;
  esac
}

# ****************************************************************************
# Create a AM cookie file following a login attempt
#
# Parameters:
# - ${1}: Return Value. Total number of Realms found
# - ${2}: AM Cookie Name
# - ${3}: AM Server URL
# - ${4}: AM Admin Password
# ****************************************************************************
function getNumberOfRealms() {
  echo "-> Enered function getNumberOfRealms()"
  echo ""
  tmpCookieName=${2}
  tmpServerUrl=${3}
  tmpAMadminPwd=${4}
  if [ -n "${tmpCookieName}" ] && [ -n "${tmpServerUrl}" ] && [ -n "${tmpAMadminPwd}" ]; then
    echo "-- Checking if AM is connected to a already configured config-store"
    echo "-- COOKIE name is ${tmpCookieName}"
    echo "-- AM instance checking against is ${tmpServerUrl}"
    echo "-- Getting AM session"
    tmpToken=$( curl -s -k --request POST \
      --header 'Accept-API-Version: resource=2.1' \
      --header 'Content-Type: application/json' \
      --header 'X-OpenAM-Username: amadmin' \
      --header "X-OpenAM-Password: ${tmpAMadminPwd}" \
      "${tmpServerUrl}/json/realms/root/authenticate"  | jq -r '.tokenId' )
    echo "-- Session token is ${tmpToken}"
    echo "-- Done"
    echo ""
    if [ -n "${tmpToken}" ] && [ "${tmpToken}" != "null" ]; then
      echo "-- Getting current # of Realms in AM"
      echo "   If 1+ then Access Manager (AM) is already configured "
      totalRealms=$( curl -s -k --request GET \
        --header "Content-Type:application/json" \
        --header "${tmpCookieName}: ${tmpToken}" \
        "${tmpServerUrl}"'/json/global-config/realms?_queryFilter=true' | jq -r '.resultCount' )
      # Use iPlanetDirectoryPro Cookie name if this is the initial deployment of AM
      if [ -z "${totalRealms}" ] || [ "${totalRealms}" == "null" ]; then
        echo "-- Invalid Realm details returned. Checking with default iPlanetDirectoryPro Cookie"
        totalRealms=$( curl -s -k --request GET \
          --header "Content-Type:application/json" \
          --header "iPlanetDirectoryPro: ${tmpToken}" \
          "${tmpServerUrl}"'/json/global-config/realms?_queryFilter=true' | jq -r '.resultCount' )
      fi
    fi
    if [ -z "${totalRealms}" ] || [ "${totalRealms}" == "null" ]; then
      totalRealms=0
    fi
    echo "-- ${totalRealms} Realm(s) found in AM"
    eval "${1}='${totalRealms}'"
    echo "-- Done"
    echo ""
  else
    echo "-- ERROR: One of the below input variables were EMPTY:"
    echo "   > tmpCookieName is ${tmpCookieName}"
    echo "   > tmpServerUrl is ${tmpServerUrl}"
    echo "   > tmpAMadminPwd length is ${#tmpAMadminPwd}"
    echo "-- Exiting ...."
    exit 1
  fi
}

# ****************************************************************************
# Takes a sring and encrypts and ncode using the Accces Manager encode.jsp page
#
# Parameters:
#  - ${1}: Encrypted and Encoded string Return value
#  - ${2}: String to encrypt and encode
#  - ${3}: AM Server URL including URI
#  - ${4}: AM admin user Password
# ****************************************************************************
function encryptEncodeString() {
  local stringToEncryptEncode="${2}"
  local amServerUrl="${3}"
  local amAdminPwd="${4}"
  echo "-> Entered function encryptEncodeString()"
  echo ""
  local path_amCookieFile="${path_tmpFolder}/cookie.txt"
  getAMCookieFile "${amServerUrl}" "${amAdminPwd}" "${path_amCookieFile}"
  echo "-- Encrypting and Encoding provided string"
  tmpEncryptedEncodedString=$(curl --silent --insecure \
  --cookie "${path_amCookieFile}" \
  --data "password=${stringToEncryptEncode}" \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --request POST "${amServerUrl}/encode.jsp" | awk '/Encoded Password is/{getline; print}')
  echo "Result of encryption is ${tmpEncryptedEncodedString}"
  eval "${1}='${tmpEncryptedEncodedString}'"
  echo "-- Done"
  echo ""
}

# ****************************************************************************
# Re-creates the default required Keys that are deployed in a Access Manager
# Keystore  by default
#
# Parameters:
#  - ${1}: Path to AM Keystore file
#  - ${2}: Keystore type. E.g. JCEKS, JKS, etc.
#  - ${3}: Location of AM .keypass file
#  - ${4}: Location of AM .storepass file
# ****************************************************************************
function recreateAMkeysInStore() {
  echo "-> Entered function recreateAMkeysInStore()"
  echo ""
  local path_amKeystore="${1}"
  local amKeystoreType="${2}"
  local path_amKeypass=${3}
  local path_amStorepass=${4}

  echo "[ Re-creating AM Certificate and Secrets Aliases in Keystore (${path_amKeystore}) ]"
  echo ""

  if [ -z "${path_amKeystore}" ] || [ "${path_amKeystore}" == "null" ] || \
     [ -z "${amKeystoreType}" ] || [ "${amKeystoreType}" == "null" ] || \
     [ -z "${path_amKeypass}" ] || [ "${path_amKeypass}" == "null" ] || \
     [ -z "${path_amStorepass}" ] || [ "${path_amStorepass}" == "null" ]; then
    echo "-- ERROR: Ensure that none of the below parameters are Null or Empty for the recreateAMkeysInStore() function:"
    echo "   [path_amKeystore] $path_amKeystore"
    echo "   [amKeystoreType] $amKeystoreType"
    echo "   [path_amKeypass] $path_amKeypass"
    echo "   [path_amStorepass] $path_amStorepass"
    echo "-- Exiting..."
    echo ""
    exit 1
  fi

  echo "Adding aliases for Certs and Keys"
  echo "---------------------------------"
  local certAliases=( "cert_es256!es256test" "cert_es384!es384test" "cert_es512!es512test" "cert_selfserviceenc!selfserviceenctest" "cert_rsajwtsign!rsajwtsigningkey" "cert_general!test" )

  for certAlias in "${certAliases[@]}"
  do
    echo "****************"
    IFS=' !' read -ra aliasDetails <<< "${certAlias}"
    aliasNameShort=${aliasDetails[0]}
    aliasName=${aliasDetails[1]}
    echo "-> Adding Alias '${aliasName}'"
    getSecretAndConfig certificate "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${AM_SECRETS}" "${aliasNameShort}" "${VAULT_CLIENT_PATH_AM}" "${VAULT_TOKEN}" "true"
    getSecretAndConfig certificateKey "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${AM_SECRETS}" "${aliasNameShort}Key" "${VAULT_CLIENT_PATH_AM}" "${VAULT_TOKEN}" "true"
    if [ -z "${certificate}" ] || [ -z "${certificateKey}" ] || [ "${certificate}" == "null" ] || [ "${certificateKey}" == "null" ]; then
      echo "-- ERROR: An error occurred retrieving Cert and/or Key. Exiting ..."
      exit 1
    else
      createPKCS12fromCerts "${aliasName}" "${certificate}" "${certificateKey}" "${path_tmpFolder}/${aliasName}.p12" "$(cat ${path_amKeypass})"
      importPKCS12IntoKeyStore "${aliasName}" "${path_tmpFolder}/${aliasName}.p12" "${path_amKeystore}" "$(cat ${path_amKeypass})" "$(cat ${path_amStorepass})" "${amKeystoreType}"
      echo "-- Done"
      echo ""
    fi
  done

  echo "Adding aliases for Secret Keys"
  echo "------------------------------"
  certAliases=( "encKey_selfservicesign!selfservicesigntest" "encKey_hmacsign!hmacsigningtest" "encKey_directenc!directenctest" )

  for certAlias in "${certAliases[@]}"
  do
    echo "   ****************"
    IFS=' !' read -ra aliasDetails <<< "${certAlias}"
    aliasValue=
    aliasNameShort=${aliasDetails[0]}
    aliasName=${aliasDetails[1]}
    getSecretAndConfig aliasValue "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${AM_SECRETS}" "${aliasNameShort}" "${VAULT_CLIENT_PATH_AM}" "${VAULT_TOKEN}"
    if [ -z "${aliasValue}" ] || [ "${aliasValue}" == "null" ]; then
      echo "-- ERROR: An error occurred retrieving Alias value. Exiting ..."
      exit 1
    else
      tmpPwd="$(cat ${path_amStorepass})"
      echo "${aliasValue}" | keytool -importpass -alias "${aliasName}" -keystore "${path_amKeystore}" -storetype "${amKeystoreType}" -storepass "$(cat "${path_amStorepass}")" -keypass "$(cat "${path_amKeypass}")"
      echo "-- Done"
      echo ""
    fi
  done
}

# ****************************************************************************
# Deletes the default Access Manager Keystore, storepass and keypass files
# ****************************************************************************
function deleteAMdefaultKeystoreAndSecrets() {
  echo "-> Entered function deleteAMdefaultKeystoreAndSecrets()"
  echo ""
  local path_cfgDir="${AM_HOME}/config"
  local path_amSecurityDir="${path_cfgDir}/security"
  local path_amSecretsDir="${path_amSecurityDir}/secrets"
  local path_amEncryptedDir="${path_amSecretsDir}/encrypted"
  local path_amKeystoreJCEKS="${path_amSecurityDir}/keystores/keystore.jceks"
  local path_amStorepass="${path_amSecretsDir}/default/.storepass"
  local path_amKeypass="${path_amSecretsDir}/default/.keypass"
  local path_amSecretsEntrypass="${path_amEncryptedDir}/entrypass"
  local path_amSecretsStorepass="${path_amEncryptedDir}/storepass"

  if [ -f "${path_amKeystoreJCEKS}" ]; then
    echo ""
    echo "-> Deleting current keystore (${path_amKeystoreJCEKS})"
    rm -f "${path_amKeystoreJCEKS}"
    echo "-- Done"
    echo ""
  fi

  if [ -f "${path_amStorepass}" ]; then
    echo "-> Deleting ${path_amStorepass}"
    rm -f "${path_amStorepass}"
    echo "-- Done"
    echo ""
  fi

  if [ -f "${path_amKeypass}" ]; then
    echo "-> Deleting ${path_amKeypass}"
    rm -f "${path_amKeypass}"
    echo "-- Done"
    echo ""
  fi

  if [ -f "${path_amSecretsEntrypass}" ]; then
    echo "-> Deleting ${path_amSecretsEntrypass}"
    rm -f "${path_amSecretsEntrypass}"
    echo "-- Done"
    echo ""
  fi

  if [ -f "${path_amSecretsStorepass}" ]; then
    echo "-> Deleting ${path_amSecretsStorepass}"
    rm -f "${path_amSecretsStorepass}"
    echo "-- Done"
    echo ""
  fi
}

# ****************************************************************************
# Update the Path to the AM Secrets Keystore, type, storepass and keypass files
#
# Parameters:
#  - ${1}: HTTP response code returned
#  - ${2}: AM server URL including URI
#  - ${3}: Path to NEW AM keysore file
#  - ${4}: Path to NEW AM storepass file
#  - ${5}: Path to NEW AM keypass file
#  - ${6}: Path to AM Cookie File
#  - ${7}: AM Cookie Name
# ****************************************************************************
function updatePathToKeystoreAndSecrets() {
  echo "-> Entered function updatePathToKeystoreAndSecrets()"
  if [ -n "${2}" ] && [ -n "${3}" ] && [ -n "${4}" ] && [ -n "${5}" ] && [ -n "${6}" ] && [ -n "${7}" ]; then
    local amServerUrl="${2}"
    local path_amKeystoreJCEKS_new="${3}"
    local path_amStorepass_new="${4}"
    local path_amKeypass_new="${5}"
    local path_amCookieFile="${6}"
    local amCookieName="${7}"
    if [ -f "${path_amCookieFile}" ]; then
      echo "-- Executing command ..."
      httpCode=$(curl --header 'Content-Type: application/json' \
        --header 'Accept-API-Version: protocol=1.0,resource=1.0' \
        --request 'PUT' --compressed --silent --insecure -o /dev/null -w "%{http_code}" \
        --cookie "${path_amCookieFile}" \
        --data '{"amconfig.header.encryption":{"am.encryption.pwd":"@AM_ENC_PWD@","com.iplanet.security.encryptor":"com.iplanet.services.util.JCEEncryption","com.iplanet.security.SecureRandomFactoryImpl":"com.iplanet.am.util.SecureRandomFactoryImpl"},"amconfig.header.validation":{"com.iplanet.services.comm.server.pllrequest.maxContentLength":"16384","com.iplanet.am.clientIPCheckEnabled":false},"amconfig.header.cookie":{"com.iplanet.am.cookie.name":"'"${amCookieName}"'","com.iplanet.am.cookie.secure":false,"com.iplanet.am.cookie.encode":false},"amconfig.header.securitykey":{"com.sun.identity.saml.xmlsig.keystore":"'"${path_amKeystoreJCEKS_new}"'","com.sun.identity.saml.xmlsig.storetype":"JCEKS","com.sun.identity.saml.xmlsig.storepass":"'"${path_amStorepass_new}"'","com.sun.identity.saml.xmlsig.keypass":"'"${path_amKeypass_new}"'","com.sun.identity.saml.xmlsig.certalias":"test"},"amconfig.header.crlcache":{"com.sun.identity.crl.cache.directory.host":"","com.sun.identity.crl.cache.directory.port":"","com.sun.identity.crl.cache.directory.ssl":false,"com.sun.identity.crl.cache.directory.user":"","com.sun.identity.crl.cache.directory.searchlocs":"","com.sun.identity.crl.cache.directory.searchattr":""},"amconfig.header.ocsp.check":{"com.sun.identity.authentication.ocspCheck":false,"com.sun.identity.authentication.ocsp.responder.url":"","com.sun.identity.authentication.ocsp.responder.nickname":""},"amconfig.header.deserialisationwhitelist":{"openam.deserialisation.classes.whitelist":"com.iplanet.dpro.session.DNOrIPAddressListTokenRestriction,com.sun.identity.common.CaseInsensitiveHashMap,com.sun.identity.common.CaseInsensitiveHashSet,com.sun.identity.common.CaseInsensitiveKey,com.sun.identity.common.configuration.ServerConfigXML,com.sun.identity.common.configuration.ServerConfigXML$DirUserObject,com.sun.identity.common.configuration.ServerConfigXML$ServerGroup,com.sun.identity.common.configuration.ServerConfigXML$ServerObject,com.sun.identity.console.base.model.SMSubConfig,com.sun.identity.console.session.model.SMSessionData,com.sun.identity.console.user.model.UMUserPasswordResetOptionsData,com.sun.identity.shared.datastruct.OrderedSet,com.sun.xml.bind.util.ListImpl,com.sun.xml.bind.util.ProxyListImpl,java.lang.Boolean,java.lang.Integer,java.lang.Number,java.lang.StringBuffer,java.net.InetAddress,java.security.cert.Certificate,java.security.cert.Certificate$CertificateRep,java.util.ArrayList,java.util.Collections$EmptyMap,java.util.Collections$EmptySet,java.util.Collections$SingletonList,java.util.HashMap,java.util.HashSet,java.util.LinkedHashSet,java.util.Locale,org.forgerock.openam.authentication.service.protocol.RemoteCookie,org.forgerock.openam.authentication.service.protocol.RemoteHttpServletRequest,org.forgerock.openam.authentication.service.protocol.RemoteHttpServletResponse,org.forgerock.openam.authentication.service.protocol.RemoteServletRequest,org.forgerock.openam.authentication.service.protocol.RemoteServletResponse,org.forgerock.openam.authentication.service.protocol.RemoteSession,org.forgerock.openam.dpro.session.NoOpTokenRestriction,org.forgerock.openam.dpro.session.ProofOfPossessionTokenRestriction"}}' \
        "${amServerUrl}/json/global-config/servers/server-default/properties/security")
      eval "${1}='${httpCode}'"
      echo "-- ${1} returned is ${httpCode}"
      echo "-- Done"
      echo ""
    else
      echo "-- ERROR: Cookie file (${path_amCookieFile}) cannot be found. Exiting..."
      echo ""
      exit 1
    fi
  else
    echo "-- ERROR: One of the below input variables were EMPTY:"
    echo "   > amServerUrl ${2}"
    echo "   > path_amKeystoreJCEKS_new is ${3}"
    echo "   > path_amStorepass_new is ${4}"
    echo "   > path_amKeypass_new is ${5}"
    echo "   > path_amCookieFile is ${6}"
    echo "   > amCookieName is ${7}"
    echo "-- Exiting ...."
    exit 1
  fi
}

# ****************************************************************************
# Create a AM cookie file following a login attempt
#
# Parameters:
# - ${1}: AM server URL including URI
# - ${2}: AM Admin Password
# - ${3}: AM Cookie file full path
# ****************************************************************************
function getAMCookieFile() {
  echo "-> Entered function getAMCookieFile()"
  local amServerUrl="${1}"
  local amAdminPwd="${2}"
  local path_amCookieFile="${3}"
  if [ -z "${3}" ]; then path_amCookieFile="${path_tmpFolder}/cookie.txt"; fi
  if [ -f "${path_amCookieFile}" ]; then echo "-- Deleting existing file '${path_amCookieFile}'"; rm -f "${path_amCookieFile}";fi
  if [ -n "${1}" ] && [ -n "${2}" ] && [ -n "${3}" ]; then
    echo "-- Cookie FIle Path is ${path_amCookieFile}"
    echo ""
    checkURLisAlive errorFound "${amServerUrl}/json/health/live" "200"
    echo "-- Authenticating ..."
    curl --insecure --request POST \
      -c "${path_amCookieFile}" --silent \
      --header "Content-Type: application/json" \
      --header "X-OpenAM-Username: amadmin" \
      --header "X-OpenAM-Password: ${amAdminPwd}" \
      --header "Accept-API-Version: resource=2.0, protocol=1.0" \
      --data "{}" \
      "${amServerUrl}/json/realms/root/authenticate"
    echo "-- Done"
    echo ""
  else
    echo "-- ERROR: One of the below input variables were EMPTY:"
    echo " > {1} amServerUrl ${1}"
    echo " > {2} amAdminPwd length is ${#2}"
    echo " > {3} path_amCookieFile is ${3}"
    echo "-- Exiting ...."
    exit 1
  fi
}

# ****************************************************************************
# Update the Path to the AM Default Secrets Store Key Store
#
# Parameters:
#  - ${1}: HTTP response code returned
#  - ${2}: AM server URL including URI
#  - ${3}: Path to NEW AM keystore files
#  - ${4}: Path to NEW AM encrypted storepass file. Filename should have no special charcters.
#  - ${5}: Path to NEW AM encrypted entrypass file. Filename should have no special charcters.
#  - ${6}: AM Cookie file full path
#  - ${7}: Secret Store Key Store type. E.g. JCEKS
# ****************************************************************************
function updatePathToDefaultSecretStoreKeyStore() {
  echo "-> Entered function updatePathToDefaultSecretStoreKeyStore()"
  if [ -n "${2}" ] && [ -n "${3}" ] && [ -n "${4}" ] && [ -n "${5}" ] && [ -n "${6}" ] && [ -n "${7}" ]; then
    local amServerUrl="${2}"
    local path_amKeystoreJCEKS_new="${3}"
    local path_amEncryptedStorepass_new="${4}"
    local path_amEncryptedKeypass_new="${5}"
    local path_amCookieFile="${6}"
    local amStoreType="${7}"
    local amEncrytedStorepas_new="$(basename ${path_amEncryptedStorepass_new})"
    local amEncrytedKeypass_new="$(basename ${path_amEncryptedKeypass_new})"
    echo "-- amStoreType is ${amStoreType}"
    echo "-- path_amKeystoreJCEKS_new is ${path_amKeystoreJCEKS_new}"
    echo "-- amEncrytedStorepas_new is ${amEncrytedStorepas_new}"
    echo "-- amEncrytedKeypass_new is ${amEncrytedKeypass_new}"
    echo "-- Executing command ..."
    httpCode=$(curl --header 'Content-Type: application/json' \
      --header 'Accept-API-Version: protocol=2.0,resource=1.0' \
      --request 'PUT' --compressed --silent --insecure -o /dev/null -w "%{http_code}" \
      --cookie "${path_amCookieFile}" \
      --data '{"providerName":"SunJCE","storePassword":"'"${amEncrytedStorepas_new}"'","storetype":"'"${amStoreType}"'","keyEntryPassword":"'"${amEncrytedKeypass_new}"'","file":"'"${path_amKeystoreJCEKS_new}"'","leaseExpiryDuration":5,"_id":"default-keystore","_type":{"_id":"KeyStoreSecretStore","name":"Keystore","collection":true}}' \
      "${amServerUrl}/json/global-config/secrets/stores/KeyStoreSecretStore/default-keystore")
    eval "${1}='${httpCode}'"
    echo "-- ${1} returned is ${httpCode}"
    echo "-- Done"
    echo ""
  else
    echo "-- ERROR: One of the below input variables were EMPTY:"
    echo "   > amServerUrl ${2}"
    echo "   > path_amKeystoreJCEKS_new is ${3}"
    echo "   > path_amEncryptedStorepass_new is ${4}"
    echo "   > path_amEncryptedKeypass_new is ${5}"
    echo "   > path_amCookieFile is ${6}"
    echo "   > amStoreType is ${7}"
    echo "-- Exiting ...."
    exit 1
  fi
}

# ****************************************************************************
# Creates a new Keystore,storepass and keypass forr a Access Manager instance
# and delete the original default Keystore, storepass and keypass
#
# Parameters:
#  - ${1}: AM Server URL
#  - ${2}: AM Admin User Password
#  - ${3}: AM Keystore Password
#  - ${4}: AM HTTP/HTTPS Port
# ****************************************************************************
function createAMkeystoreAndSecrets() {
  echo "-> Entered function createAMkeystoreAndSecrets()"
  echo ""
  local path_amKeystoreType="JCEKS"
  local path_cfgDir="${AM_HOME}/config"
  local path_amSecurityDir="${path_cfgDir}/security"
  local path_amSecretsDir="${path_amSecurityDir}/secrets"
  local path_amEncryptedDir="${path_amSecretsDir}/encrypted"
  local path_amKeystoreJCEKS_new="${path_amSecurityDir}/keystores/keystore_new.jceks"
  local path_amStorepass_new="${path_amSecretsDir}/default/.storepass_new"
  local path_amKeypass_new="${path_amSecretsDir}/default/.keypass_new"
  local path_amSecretsEntrypass_new="${path_amEncryptedDir}/entrypassnew" # Filename should have no special characters
  local path_amSecretsStorepass_new="${path_amEncryptedDir}/storepassnew" # Filename should have no special characters
  local encryptedEncodedString=
  local path_amCookieFile=""
  local amServerUrl=
  local amAdminPwd=
  local keystorePwd=
  local amPort=
  local amCookieName=


  if [ -n "${1}" ] && [ -n "${2}" ] && [ -n "${3}" ] && [ -n "${4}" ] && [ -n "${COOKIE_NAME}" ]; then
    amServerUrl="${1}"
    amAdminPwd="${2}"
    keystorePwd="${3}"
    amPort=${4}
    amCookieName="${COOKIE_NAME}"

    echo "** [ STEP 01/07 Creating NEW Keypass and Storepass ] **"
    echo ""
    echo "-> Creating ${path_amKeypass_new}"
    echo -n "${keystorePwd}" > "${path_amKeypass_new}"
    chmod 400 "${path_amKeypass_new}"
    echo "-- Done"
    echo ""
    echo "-> Creating ${path_amStorepass_new}"
    echo -n "${keystorePwd}" > "${path_amStorepass_new}"
    chmod 400 "${path_amStorepass_new}"
    echo "-- Done"
    echo ""

    echo "** [ STEP 02/07 Creating NEW keystore (${path_amKeystoreJCEKS_new}) and Secrets ] **"
    echo ""
    recreateAMkeysInStore "${path_amKeystoreJCEKS_new}" "${path_amKeystoreType}" \
                          "${path_amKeypass_new}" "${path_amStorepass_new}"

    echo "** [ STEP 03/07 Creating Encrypted Encoded string ] **"
    echo ""
    encryptEncodeString encryptedEncodedString "${keystorePwd}" "${amServerUrl}" "${amAdminPwd}"
    echo "-> Validating Encrypted and Encoded string"
    if [ -n "${encryptedEncodedString}" ] && [ "${encryptedEncodedString,,}" != "null" ]; then
      echo "-- String valid"
      mkdir -p "${path_amEncryptedDir}"
      echo "-- Creating ${path_amSecretsEntrypass_new}"
      [ -f "${path_amSecretsEntrypass_new}" ] && mv "${path_amSecretsEntrypass_new}" "${path_amSecretsEntrypass_new}_bak"
      echo -n "${encryptedEncodedString}" > "${path_amSecretsEntrypass_new}"
      echo "-- Creating ${path_amSecretsStorepass_new}"
      [ -f "${path_amSecretsStorepass_new}" ] && mv "${path_amSecretsStorepass_new}" "${path_amSecretsStorepass_new}_bak"
      echo -n "${encryptedEncodedString}" > "${path_amSecretsStorepass_new}"
    else
      echo "-- ERROR occurred encrypting and Encoding the required string"
      echo "   See logs above for addition information"
      exit 1
    fi
    echo "-- Done"
    echo ""

    echo "** [ STEP 04/04 Updating AM to use new Keypass, Storepass and Cookie Name ] **"
    echo ""
    path_amCookieFile="${path_tmpFolder}/cookie.txt"
    getAMCookieFile "${amServerUrl}" "${amAdminPwd}" "${path_amCookieFile}"

    if [ -f "${path_amCookieFile}" ]; then
      updatePathToKeystoreAndSecrets httpCode "${amServerUrl}" "${path_amKeystoreJCEKS_new}" \
        "${path_amStorepass_new}" "${path_amKeypass_new}" "${path_amCookieFile}" "${amCookieName}"

      if [ "${httpCode}" != "200" ]; then
        echo "-- ERROR occurred updating AM Secrets and Keystore "
        echo "-- Exiting ..."
        echo ""
        exit 1
      fi

      echo "** [ STEP 05/07 Updating AM to use new default Secret Store ] **"
      updatePathToDefaultSecretStoreKeyStore httpCode "${amServerUrl}" "${path_amKeystoreJCEKS_new}" \
        "${path_amSecretsStorepass_new}" "${path_amSecretsEntrypass_new}" "${path_amCookieFile}" \
        "${path_amKeystoreType}"
      if [ "${httpCode}" != "200" ]; then
        echo "-- ERROR occurred updating AM Default Secret Store"
        echo "-- Exiting ..."
        echo ""
        exit 1
      fi

      echo "** [ STEP 06/07 Restarting Tomcat to apply changes ] **"
      echo ""
      manageTomcat "stop" "${amPort}" "${AM_URI}"
      manageTomcat "start-debug" "${amPort}" "${AM_URI}"

      echo "** [ STEP 07/07 Removing original AM Key Store and Secrets ] **"
      echo ""
      deleteAMdefaultKeystoreAndSecrets
      echo "-- Done"
      echo ""
    else
      echo "-- ERROR: Required AM Coookie file (${path_amCookieFile}) not found"
      echo "   Please checkthe code and log file"
      echo "-- Exiting ..."
      exit 1
    fi
  else
    echo "-- ERROR: One of the below input variables were EMPTY:"
    echo "   > amServerUrl ${1}"
    echo "   > amAdminPwd length is ${#2}"
    echo "   > keystorePwd length is ${#3}"
    echo "   > amPort is ${4}"
    echo "   > COOKIE_NAME is ${COOKIE_NAME}"
    echo "-- Exiting ...."
    exit 1
  fi
}

# ****************************************************************************
# Applies recommeded Access Manager hardening requirements
#
# Parameters:
#  - ${1}: AM server URL including URI
#  - ${2}: AM Admin Password
#  - ${3}: Token Store comma separated FQDN and Ports. E.g. token-store-0:1636,token-store-1:1636,
#  - ${4}: Token Store RootSuffix
#  - ${5}: Token Store BindDN
#  - ${6}: Token Store BindDN Password
#  - ${7}: User Store Root Suffix
#  - ${8}: User Store Bind DN
#  - ${9}: User Store Bind DN Password
#  - ${10}: User Store Affinity String
#  - ${11}: AM load balancer domain
# ****************************************************************************
function applyAMDefaultHardening() {
  echo "-> Entered function applyAMDefaultHardening()"
  echo "   amServerUrl is ${amServerUrl}"
  echo ""
  if [ -n "${1}" ] && [ -n "${2}" ] && [ -n "${3}" ] && [ -n "${4}" ] && \
     [ -n "${5}" ] && [ -n "${6}" ] && [ -n "${7}" ] && [ -n "${8}" ] && \
     [ -n "${9}" ] && [ -n "${10}" ] && [ -n "${11}" ]; then
    local amServerUrl="${1}"
    local amAdminPwd="${2}"
    local ctsConnStr_Affinity="${3}"
    local ctsRootSuffix="${4}"
    local ctsBindDN="${5}"
    local ctsBindDNPwd="${6}"
    local userStoreRootSuffix="${7}"
    local userStoreDirMgr="${8}"
    local userStoreDirMgrPwd="${9}"
    local userStoreConnString_Affinity="${10}"
    local amLBdomain="${11}"
    local serverIndx=${HOSTNAME//[^0-9]/}
    local lbcookieIndx=$(printf "%02d\n" $((serverIndx + 1)))
    local path_amCookieFile="${path_tmpFolder}/cookie.txt"
    local path_tmpJsonFile="${path_tmpFolder}/sample.json"
    getAMCookieFile "${amServerUrl}" "${amAdminPwd}" "${path_amCookieFile}"
    if [ -f "${path_amCookieFile}" ]; then
      echo "-> [ STEP 01/05 ] Updating Global Authentication settings"
      httpCode=$(curl --header 'Content-Type: application/json' \
        --header 'Accept-API-Version: protocol=1.0,resource=1.0' \
        --header 'X-Requested-With: XMLHttpRequest' \
        --request 'PUT' --compressed --silent --insecure -o /dev/null -w "%{http_code}" \
        --cookie "${path_amCookieFile}" \
        --data '{"defaults":{"security":{"moduleBasedAuthEnabled":false}}}' \
        "${amServerUrl}/json/global-config/authentication")
      echo "-- Request returned HTTP Status Code ${httpCode}"
      if [ -n "${httpCode}" ] && [ "${httpCode}" == "200" ]; then
        echo "-- Done"
        echo ""
      else
        echo "-- ERROR: Failed to update the Global Authentication settings"
        echo "-- Exiting ..."
        exit 1
      fi

      echo "-> [ STEP 02/05 ] Updating Advanced Properties (amlbcookie)"
      echo "-- Getting current properties"
      local cmd_getAdvProps=$(echo curl \
        "${amServerUrl}/json/global-config/servers/01/properties/advanced" \
        --header 'Content-Type: application/json' \
        --header 'Accept-API-Version: protocol=1.0,resource=1.0' \
        --header 'X-Requested-With: XMLHttpRequest' \
        --request 'GET' --compressed --silent --insecure \
        --cookie "${path_amCookieFile}")
      httpCode=$(eval "${cmd_getAdvProps} " -o /dev/null -w "%{http_code}")
      httpCode="${httpCode:0:3}"
      echo "-- Request returned HTTP Status Code ${httpCode}"
      if [ -n "${httpCode}" ] && [ "${httpCode}" == "200" ]; then
        echo "-- Updating the com.iplanet.am.lbcookie.value to ${lbcookieIndx}"
        jsonAdvProps=$(eval "${cmd_getAdvProps}")
        jsonAdvProps=$(echo "${jsonAdvProps}" | jq -c ".[\"com.iplanet.am.lbcookie.value\"]=\"${lbcookieIndx}\"")
        echo "-- Removing _id key"
        jsonAdvProps=$(echo "${jsonAdvProps}" | jq -c "del(.[\"_id\"])")
        echo "-- Removing _rev key"
        jsonAdvProps=$(echo "${jsonAdvProps}" | jq -c "del(.[\"_rev\"])")
        echo "-- saving updated json to ${path_tmpJsonFile}"
        echo "${jsonAdvProps}" > "${path_tmpJsonFile}"
        httpCode=$(curl --header 'Content-Type: application/json' \
          --header 'Accept-API-Version: protocol=1.0,resource=1.0' \
          --header 'X-Requested-With: XMLHttpRequest' \
          --request 'PUT' --compressed --silent --insecure -o /dev/null -w "%{http_code}" \
          --cookie "${path_amCookieFile}" \
          --data @${path_tmpJsonFile} \
          "${amServerUrl}/json/global-config/servers/01/properties/advanced")
        httpCode="${httpCode:0:3}"
        echo "-- Request returned HTTP Status Code ${httpCode}"
        if [ -n "${httpCode}" ] && [ "${httpCode}" == "200" ]; then
          echo "-- Done"
          echo ""
        else
          echo "-- ERROR: Failed to update Advanced Properties"
          echo "-- Exiting ..."
          exit 1
        fi
      else
        echo "-- ERROR: Failed to retrieve Advanced Properties"
        echo "-- Exiting ..."
        exit 1
      fi

      echo "-> [ STEP 03/05 ] Skip Updating Platform (Cookie Domains)"
      # Cookie Domain string format is a Comma separated list of Cookie Domains. E.g. "localhost","yourcomapny.com","am.yourcomponay.com"
#      amCookieDomainsStr='"'${amLBdomain}'","'${amLBdomain#*.}'","localhost"'
#      echo "-- amCookieDomainsStr is ${amCookieDomainsStr}"
#      httpCode=$(curl --header 'Content-Type: application/json' \
#        --header 'Accept-API-Version: protocol=1.0,resource=1.0' \
#        --header 'X-Requested-With: XMLHttpRequest' \
#        --request 'PUT' --compressed --silent --insecure -o /dev/null -w "%{http_code}" \
#        --cookie "${path_amCookieFile}" \
#        --data '{"locale":"en_US","cookieDomains":['"${amCookieDomainsStr}"'],"_id":"","_type":{"_id":"platform","name":"Platform","collection":false}}' \
#        "${amServerUrl}/json/global-config/services/platform")
#      httpCode="${httpCode:0:3}"
#      echo "-- Request returned HTTP Status Code ${httpCode}"
#      if [ -n "${httpCode}" ] && [ "${httpCode}" == "200" ]; then
#        echo "-- Done"
#        echo ""
#      else
#        echo "-- ERROR: Failed to update Platform (Cookie Domains)"
#        echo "-- Exiting ..."
#        exit 1
#      fi

      echo "-> [ STEP 04/05 ] Updating external Token Store(s) and Affinity settings for Root realm"
      echo "-- ctsConnStr_Affinity is ${ctsConnStr_Affinity}"
      echo "-- ctsRootSuffix is ${ctsRootSuffix}"
      echo "-- ctsBindDN is ${ctsBindDN}"
      echo "-- ctsBindDNPwd length is ${#ctsBindDNPwd}"
      httpCode=$(curl --header 'Content-Type: application/json' \
        --header 'Accept-API-Version: protocol=1.0,resource=1.0' \
        --header 'X-Requested-With: XMLHttpRequest' \
        --request 'PUT' --compressed --silent --insecure -o /dev/null -w "%{http_code}" \
        --cookie "${path_amCookieFile}" \
        --data '{"amconfig.org.forgerock.services.cts.store.common.section":{"org.forgerock.services.cts.store.location":"external","org.forgerock.services.cts.store.root.suffix":"'"${ctsRootSuffix}"'","org.forgerock.services.cts.store.max.connections":"10","org.forgerock.services.cts.store.page.size":"0","org.forgerock.services.cts.store.vlv.page.size":"1000"},"amconfig.org.forgerock.services.cts.store.external.section":{"org.forgerock.services.cts.store.ssl.enabled":true,"org.forgerock.services.cts.store.directory.name":"'"${ctsConnStr_Affinity}"'","org.forgerock.services.cts.store.loginid":"'"${ctsBindDN}"'","org.forgerock.services.cts.store.password":"'"${ctsBindDNPwd}"'","org.forgerock.services.cts.store.heartbeat":"10","org.forgerock.services.cts.store.affinity.enabled":true}}' \
        "${amServerUrl}/json/global-config/servers/server-default/properties/cts")
      echo "-- Request returned HTTP Status Code ${httpCode}"
      if [ -n "${httpCode}" ] && [ "${httpCode}" == "200" ]; then
        echo "-- Done"
        echo ""
      else
        echo "-- ERROR: Failed to update External Token Store(s) and Affinity settings"
        echo "-- Exiting ..."
        exit 1
      fi

      echo "-> [ STEP 05/05 ] Updating external User Store(s) and Affinity settings for Root realm"
      echo "-- userStoreConnString_Affinity is ${userStoreConnString_Affinity}"
      echo "-- userStoreRootSuffix is ${userStoreRootSuffix}"
      echo "-- userStoreDirMgr is ${userStoreDirMgr}"
      echo "-- userStoreDirMgrPwd length is ${#userStoreDirMgrPwd}"
      httpCode=$(curl --header 'Content-Type: application/json' \
        --header 'Accept-API-Version: protocol=2.0,resource=1.0' \
        --header 'X-Requested-With: XMLHttpRequest' \
        --request 'PUT' --compressed --silent --insecure -o /dev/null -w "%{http_code}" \
        --cookie "${path_amCookieFile}" \
        --data '{"authentication":{"sun-idrepo-ldapv3-config-auth-naming-attr":"uid"},"cachecontrol":{"sun-idrepo-ldapv3-dncache-enabled":true,"sun-idrepo-ldapv3-dncache-size":1500},"errorhandling":{"com.iplanet.am.ldap.connection.delay.between.retries":1000},"groupconfig":{"sun-idrepo-ldapv3-config-group-attributes":["dn","cn","uniqueMember","objectclass"],"sun-idrepo-ldapv3-config-group-container-name":"ou","sun-idrepo-ldapv3-config-group-container-value":"groups","sun-idrepo-ldapv3-config-group-objectclass":["top","groupofuniquenames"],"sun-idrepo-ldapv3-config-groups-search-attribute":"cn","sun-idrepo-ldapv3-config-groups-search-filter":"(objectclass=groupOfUniqueNames)","sun-idrepo-ldapv3-config-memberurl":"memberUrl","sun-idrepo-ldapv3-config-uniquemember":"uniqueMember"},"ldapsettings":{"openam-idrepo-ldapv3-affinity-enabled":true,"openam-idrepo-ldapv3-behera-support-enabled":true,"openam-idrepo-ldapv3-contains-iot-identities-enriched-as-oauth2client":true,"openam-idrepo-ldapv3-heartbeat-interval":10,"openam-idrepo-ldapv3-heartbeat-timeunit":"SECONDS","openam-idrepo-ldapv3-proxied-auth-denied-fallback":false,"openam-idrepo-ldapv3-proxied-auth-enabled":false,"sun-idrepo-ldapv3-config-authid":"'"${userStoreDirMgr}"'","sun-idrepo-ldapv3-config-authpw":"'"${userStoreDirMgrPwd}"'","sun-idrepo-ldapv3-config-connection-mode":"LDAPS","sun-idrepo-ldapv3-config-connection_pool_max_size":10,"sun-idrepo-ldapv3-config-connection_pool_min_size":1,"sun-idrepo-ldapv3-config-ldap-server":['"${userStoreConnString_Affinity}"'],"sun-idrepo-ldapv3-config-max-result":1000,"sun-idrepo-ldapv3-config-organization_name":"'"${userStoreRootSuffix}"'","sun-idrepo-ldapv3-config-search-scope":"SCOPE_SUB","sun-idrepo-ldapv3-config-time-limit":10},"persistentsearch":{"sun-idrepo-ldapv3-config-psearch-filter":"(!(objectclass=frCoreToken))","sun-idrepo-ldapv3-config-psearch-scope":"SCOPE_SUB","sun-idrepo-ldapv3-config-psearchbase":"ou=am-config"},"pluginconfig":{"sunIdRepoAttributeMapping":[],"sunIdRepoClass":"org.forgerock.openam.idrepo.ldap.DJLDAPv3Repo","sunIdRepoSupportedOperations":["realm=read,create,edit,delete,service","user=read,create,edit,delete,service","group=read,create,edit,delete"]},"userconfig":{"sun-idrepo-ldapv3-config-active":"Active","sun-idrepo-ldapv3-config-auth-kba-attempts-attr":["kbaInfoAttempts"],"sun-idrepo-ldapv3-config-auth-kba-attr":["kbaInfo"],"sun-idrepo-ldapv3-config-auth-kba-index-attr":"kbaActiveIndex","sun-idrepo-ldapv3-config-createuser-attr-mapping":["cn","sn"],"sun-idrepo-ldapv3-config-inactive":"Inactive","sun-idrepo-ldapv3-config-isactive":"scb-inetUserStatus","sun-idrepo-ldapv3-config-people-container-name":"ou","sun-idrepo-ldapv3-config-people-container-value":"people","sun-idrepo-ldapv3-config-user-attributes":["iplanet-am-auth-configuration","iplanet-am-user-alias-list","iplanet-am-user-password-reset-question-answer","mail","assignedDashboard","authorityRevocationList","dn","iplanet-am-user-password-reset-options","employeeNumber","createTimestamp","kbaActiveIndex","caCertificate","iplanet-am-session-quota-limit","iplanet-am-user-auth-config","sun-fm-saml2-nameid-infokey","sunIdentityMSISDNNumber","iplanet-am-user-password-reset-force-reset","sunAMAuthInvalidAttemptsData","devicePrintProfiles","givenName","iplanet-am-session-get-valid-sessions","objectClass","adminRole","inetUserHttpURL","lastEmailSent","iplanet-am-user-account-life","postalAddress","userCertificate","preferredtimezone","iplanet-am-user-admin-start-dn","oath2faEnabled","preferredlanguage","sun-fm-saml2-nameid-info","userPassword","iplanet-am-session-service-status","telephoneNumber","iplanet-am-session-max-idle-time","distinguishedName","iplanet-am-session-destroy-sessions","kbaInfoAttempts","modifyTimestamp","uid","iplanet-am-user-success-url","iplanet-am-user-auth-modules","kbaInfo","memberOf","sn","preferredLocale","manager","iplanet-am-session-max-session-time","deviceProfiles","cn","oathDeviceProfiles","webauthnDeviceProfiles","iplanet-am-user-login-status","pushDeviceProfiles","push2faEnabled","inetUserStatus","retryLimitNodeCount","iplanet-am-user-failure-url","iplanet-am-session-max-caching-time","scb-lastLoginTime","scb-inetUserStatus","scb-RelID","scb-loginTime","scb-logoutTime","scb-invalidAuthAttemptsDetails","scb-EncPassword","scb-otpTempLockoutTime","scb-otpSendTime","scb-otpValidationAttemptTime","scb-otpValidationStatus","scb-otpUserOperation","scb-otpFailureCounter","scb-otpUserPhone","scb-countryCode","scb-EBID"],"sun-idrepo-ldapv3-config-user-objectclass":["iplanet-am-managed-person","inetuser","sunFMSAML2NameIdentifier","inetorgperson","devicePrintProfilesContainer","iplanet-am-user-service","iPlanetPreferences","pushDeviceProfilesContainer","forgerock-am-dashboard-service","organizationalperson","top","kbaInfoContainer","person","sunAMAuthAccountLockout","oathDeviceProfilesContainer","webauthnDeviceProfilesContainer","iplanet-am-auth-configuration-service","deviceProfilesContainer","ciamIdentity"],"sun-idrepo-ldapv3-config-users-search-attribute":"uid","sun-idrepo-ldapv3-config-users-search-filter":"(objectclass=inetorgperson)"}}' \
        "${amServerUrl}/json/realms/root/realm-config/services/id-repositories/LDAPv3ForOpenDS/OpenDJ")
      echo "-- Request returned HTTP Status Code ${httpCode}"
      if [ -n "${httpCode}" ] && [ "${httpCode}" == "200" ]; then
        echo "-- Done"
        echo ""
      else
        echo "-- ERROR: Failed to update External User Store(s) and Affinity settings"
        echo "-- Exiting ..."
        exit 1
      fi
    else
      echo "-- ERROR: Required AM Coookie file (${path_amCookieFile}) not found"
      echo "   Please check log file"
      echo "-- Exiting ..."
      exit 1
    fi
  else
    echo "-- ERROR: One of the below input variables were EMPTY:"
    echo "   > {1} amServerUrl ${1}"
    echo "   > {2} amAdminPwd length is ${#2}"
    echo "   > {3} ctsConnStr_Affinity is ${3}"
    echo "   > {4} ctsRootSuffix is ${4}"
    echo "   > {5} ctsBindDN is ${5}"
    echo "   > {6} ctsBindDNPwd length is ${#6}"
    echo "   > {7} userStoreRootSuffix is ${7}"
    echo "   > {8} userStoreDirMgr is ${8}"
    echo "   > {9} userStoreDirMgrPwd length is ${#9}"
    echo "   > {10} userStoreConnString_Affinity is ${10}"
    echo "   > {11} amLBdomain is ${11}"
    echo "-- Exiting ...."
    exit 1
  fi
}

# ****************************************************************************
# Update all authenticated users that cannot be managed with amster script
#
# Parameters:
#  - ${1}: AM server URL including URI
#  - ${2}: AM Admin Password
#  - ${3}: AM Realm name
# ****************************************************************************

function updateAllAuthenticatedUsersForAM() {
  echo "-> Entered function updateAllAuthenticatedUsersForAM()"
  echo ""
  if [ -n "${1}" ] && [ -n "${2}" ] && [ -n "${3}" ]; then
    local amServerUrl="${1}"
    local amAdminPwd="${2}"
    local amRealmName="${3}"
    echo "amServerUrl -> ${amServerUrl}"
    echo "amRealmName -> ${amRealmName}"
    local path_amCookieFile="${path_tmpFolder}/cookie.txt"
    getAMCookieFile "${amServerUrl}" "${amAdminPwd}" "${path_amCookieFile}"
    echo "-> Updating AllAuthenticatedUsers settings for ${amRealmName}"
    httpCode=$(curl --header 'Content-Type: application/json' \
      --header 'Accept-API-Version: protocol=2.1,resource=1.0' \
      --header 'X-Requested-With: XMLHttpRequest' \
      --header 'if-match: *' \
      --request 'PUT' --compressed --silent --insecure -o /dev/null -w "%{http_code}" \
      --cookie "${path_amCookieFile}" \
      --data '{"privileges":{"RealmAdmin":false,"LogAdmin":false,"LogRead":false,"LogWrite":false,"AgentAdmin":false,"FederationAdmin":false,"RealmReadAccess":false,"PolicyAdmin":false,"EntitlementRestAccess":true,"PrivilegeRestReadAccess":false,"PrivilegeRestAccess":false,"ApplicationReadAccess":false,"ApplicationModifyAccess":false,"ResourceTypeReadAccess":false,"ResourceTypeModifyAccess":false,"ApplicationTypesReadAccess":false,"ConditionTypesReadAccess":false,"SubjectTypesReadAccess":false,"DecisionCombinersReadAccess":false,"SubjectAttributesReadAccess":false,"SessionPropertyModifyAccess":false}}' \
      "${amServerUrl}/json/realms/root/realms/${amRealmName}/groups/allauthenticatedusers")
    echo "-- Request returned HTTP Status Code ${httpCode}"
    if [ -n "${httpCode}" ] && [ "${httpCode}" == "200" ]; then
      echo "-- Done"
      echo ""
    else
      echo "-- ERROR: Failed to update AllAuthenticatedUsers settings for ${amRealmName}"
      echo "-- Exiting ..."
      exit 1
    fi
  fi
}