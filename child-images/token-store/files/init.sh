#!/bin/bash

# =======================================================
# Script to be executed by ForgeRock Directory Server(DS)
# Kubernetes container on startup to configure itself as
# a ForgeRock Directory Server (Token Store).

# Created 19/08/2018
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
# =======================================================

echo "----------------------------------------------------"
echo "****************************************************"
echo "[[ ForgeRock Directory Server (DS) - Token Store ]]"
echo "->           Server Name: ${HOSTNAME}"
echo "->               DS_HOME: ${DS_HOME}"
echo "->                DS_APP: ${DS_APP}"
echo "->            DS_SECRETS: ${DS_SECRETS}"
echo "->         DS_CONFIGMAPS: ${DS_CONFIGMAPS}"
echo "->            DS_BASE_DN: ${DS_BASE_DN}"
echo "->        SELF_REPLICATE: ${SELF_REPLICATE}"
echo "->           DS_INSTANCE: ${DS_INSTANCE}"
echo "->            DS_SCRIPTS: ${DS_SCRIPTS}"
echo "->            DS_VERSION: ${DS_VERSION}"
echo "->        VAULT_BASE_URL: ${VAULT_BASE_URL}"
echo "->  VAULT_CLIENT_PATH_TS: ${VAULT_CLIENT_PATH_TS}"
echo "->  VAULT_CLIENT_PATH_RS: ${VAULT_CLIENT_PATH_RS}"
echo "->           VAULT_TOKEN: ${VAULT_TOKEN}"
echo "->         POD_NAMESPACE: ${POD_NAMESPACE}"
echo "->          POD_BASENAME: ${POD_BASENAME}"
echo "->      POD_SERVICE_NAME: ${POD_SERVICE_NAME}"
echo "-         CLUSTER_DOMAIN: ${CLUSTER_DOMAIN}"
echo "->             JAVA_HOME: ${JAVA_HOME}"
echo "->          JAVA_CACERTS: ${JAVA_CACERTS}"
echo "-> USE_CUSTOM_JAVA_PROPS: ${USE_CUSTOM_JAVA_PROPS}"
echo "->DISABLE_INSECURE_COMMS: ${DISABLE_INSECURE_COMMS}"
echo "->                RS_SVC: ${RS_SVC}"
echo "->          SECRETS_MODE: ${SECRETS_MODE}"
echo "->              ENV_TYPE: ${ENV_TYPE}"
echo "----------------------------------------------------"
echo ""

echo "-> Loading required scripts"
echo "-- Loading ${DS_SCRIPTS}/forgerock-ds-shared-functions.sh"
. ${DS_SCRIPTS}/forgerock-ds-shared-functions.sh
echo "-- Done"
echo ""

# Local Variables
# ---------------
errorFound="false"
rootUserPassword=
monitorUserPassword=
amCtsAdminPassword=
tokenStoreCertPwd=
truststorePwd=
deploymentKey=
file_properties=
certAlias="token-store"
path_tmpScript="${path_tmpFolder}/setupDS.sh"
# Note that format for statefulset pod service URL is {hostname}.{service-name}.{POD_NAMESPACE}.svc.{CLUSTER_DOMAIN}
svcURL_curr="${HOSTNAME}.${POD_SERVICE_NAME}.${POD_NAMESPACE}.svc.${CLUSTER_DOMAIN}"
tmpRSsecretsPath="/opt/rs/secrets"

echo "Setting up pre-requsite(s)"
echo "--------------------------"
mkdir -p ${path_tmpFolder}
echo "-- Done"
echo ""

echo "Checking Environment variable"
echo "-----------------------------"
if [ -z "${ENV_TYPE}" ]; then
  echo "-> ERROR: ENV_TYPE is empty."
  echo "-- Please set environment variable to 'fat', 'fit', 'sit', 'uat', 'nft', etc."
  echo ""
  errorFound="true"
fi

if [ -z "${SECRETS_MODE}" ]; then
  echo "-> WARN: SECRETS_MODE is empty."
  echo "-- Setting to 'k8s' as default. Please set in future to 'k8s' or 'REST'"
  echo "   Former where secrets and config are stored in K8s, later in a REST secrets manager."
  echo ""
  export SECRETS_MODE="k8s"
fi

if [ "${SECRETS_MODE,,}" != "k8s" ]; then
  if [ -z "${VAULT_BASE_URL}" ]; then
    echo "-> ERROR: VAULT_BASE_URL is empty."
    echo "-- Please set environment variable to the Kubernetes service url for the your Secrets Manager."
    echo "-- Format is {service-name}.{POD_NAMESPACE}.svc.cluster.local"
    echo ""
    errorFound="true"
  fi

  if [ -z "${VAULT_CLIENT_PATH_TS}" ]; then
    echo "-> ERROR: VAULT_CLIENT_PATH_TS is empty. Required when using Repication Server."
    echo "-- Please set environment variable to the path for Client secrets in your Secrets Manager"
    echo ""
    errorFound="true"
  fi

  if [ -z "${VAULT_CLIENT_PATH_RS}" ]; then
    echo "-> WARN: VAULT_CLIENT_PATH_RS is empty."
    if [ "${SELF_REPLICATE}" != "true" ]; then
      echo "-- Please set environment variable to the path for Replication Server in your Secrets Manager"
      errorFound="true"
    fi
    echo ""
  fi

  if [ -z "${VAULT_TOKEN}" ]; then
    echo "-> ERROR: VAULT_TOKEN is empty."
    echo "-- Please set environment variable to VAULT Token to use to access your Secrets Manager."
    echo ""
    errorFound="true"
  fi
fi

if [ -z "${POD_BASENAME}" ]; then
  echo "-> ERROR: POD_BASENAME is empty."
  echo "-- Please set to the kubernetes statefulset POD name in deployment yaml"
  echo ""
  errorFound="true"
fi

if [ -z "${POD_SERVICE_NAME}" ]; then
  echo "-> ERROR: POD_SERVICE_NAME is empty."
  echo "-- Please set to the name of kubernetes service used to access the POD"
  echo ""
  errorFound="true"
fi

if [ -z "${CLUSTER_DOMAIN}" ]; then
  echo "-> ERROR: CLUSTER_DOMAIN is empty."
  echo "-- Please set to the kubernetes cluster domain. E.g. cluster.local"
  echo ""
  errorFound="true"
fi

if [ -z "${POD_NAMESPACE}" ]; then
  echo "-> ERROR: POD_NAMESPACE is empty."
  echo "-- Please set to pod metadata.namespace. E.g. forgerock"
  echo ""
  errorFound="true"
fi

if [ -z "${DS_BASE_DN}" ]; then
  echo "-> ERROR: DS_BASE_DN is empty."
  echo "-- Please set to the required DS_BASE_DN for the Token Store. E.g. 'ou=token'"
  echo ""
  errorFound="true"
fi

if [ -z "${DS_INSTANCE}" ]; then
  echo "-> ERROR: DS_INSTANCE is empty. "
  echo "-- Please set to the path of the DS instance directory. E.g. /opt/ds/instance"
  echo ""
  errorFound="true"
fi

if [ -z "${SELF_REPLICATE}" ]; then
  echo "-> WARN: SELF_REPLICATE is empty. "
  echo "-- Setting to 'true' as default. Please set in future to 'true' or 'false' "
  echo ""
  export SELF_REPLICATE="true"
fi

if [ -z "${USE_CUSTOM_JAVA_PROPS}" ]; then
  echo "-> WARN: USE_CUSTOM_JAVA_PROPS is empty."
  echo "-- Setting to 'false' as default. Please set in future to 'true' or 'false' "
  echo ""
  export USE_CUSTOM_JAVA_PROPS="false"
fi

if [ -z "${DISABLE_INSECURE_COMMS}" ]; then
  echo "-> WARN: DISABLE_INSECURE_COMMS is empty."
  echo "-- Setting to 'false' as default. Please set in future to 'true' or 'false' "
  echo ""
  export DISABLE_INSECURE_COMMS="false"
fi

if [ -z "${RS_SVC}" ]; then
  echo "-> WARN: RS_SVC is empty. Required when using Repication Server."
  export RS_SVC=""
  if [ "${SELF_REPLICATE}" != "true" ]; then
    echo "-- RS_SVC must b set to the comma separated list of Replication Servers (RS) SVC if SELF_REPLICATE is NOT true."
    echo "-- Format is {rs1-pod-name}.{service-name}.{POD_NAMESPACE}.svc.cluster.local,{rs2-pod-name}.{service-name}.{POD_NAMESPACE}.svc.cluster.local"
    errorFound="true"
  fi
  echo ""
fi
echo "-- Done"
echo ""

if [ "${errorFound}" == "false" ]; then
  echo "Getting Secrets and Configuration"
  echo "---------------------------------"
  echo ""
  # Getting Secrets
  getSecretAndConfig rootUserPassword "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_SECRETS}" "rootUserPassword" "${VAULT_CLIENT_PATH_TS}" "${VAULT_TOKEN}"
  getSecretAndConfig monitorUserPassword "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_SECRETS}" "monitorUserPassword" "${VAULT_CLIENT_PATH_TS}" "${VAULT_TOKEN}"
  getSecretAndConfig amCtsAdminPassword "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_SECRETS}" "amCtsAdminPassword" "${VAULT_CLIENT_PATH_TS}" "${VAULT_TOKEN}"
  getSecretAndConfig tokenStoreCertPwd "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_SECRETS}" "tokenStoreCertPwd" "${VAULT_CLIENT_PATH_TS}" "${VAULT_TOKEN}"
  getSecretAndConfig truststorePwd "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_SECRETS}" "truststorePwd" "${VAULT_CLIENT_PATH_TS}" "${VAULT_TOKEN}"
  getSecretAndConfig deploymentKey "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_SECRETS}" "deploymentKey" "${VAULT_CLIENT_PATH_TS}" "${VAULT_TOKEN}"
  # Getting Configuation
  getSecretAndConfig file_properties "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_CONFIGMAPS}" "properties" "${VAULT_CLIENT_PATH_TS}" "${VAULT_TOKEN}" "true"

  echo "Verifying Secrets and Configuration"
  echo "-----------------------------------"
  echo ""
  if [ -z "${rootUserPassword}" ] || [ "${rootUserPassword}" == "null" ]; then
    echo "-- ERROR: 'rootUserPassword' not found"
    errorFound="true"
  fi
  if [ -z "${monitorUserPassword}" ] || [ "${monitorUserPassword}" == "null" ]; then
    echo "-- ERROR: 'monitorUserPassword' not found"
    errorFound="true"
  fi
  if [ -z "${amCtsAdminPassword}" ] || [ "${amCtsAdminPassword}" == "null" ]; then
    echo "-- ERROR: 'amCtsAdminPassword' not found"
    errorFound="true"
  fi
  if [ -z "${tokenStoreCertPwd}" ] || [ "${tokenStoreCertPwd}" == "null" ]; then
    echo "-- ERROR: 'tokenStoreCertPwd' not found"
    errorFound="true"
  fi
  if [ -z "${truststorePwd}" ] || [ "${truststorePwd}" == "null" ]; then
    echo "-- ERROR: 'truststorePwd' not found"
    errorFound="true"
  fi
  if [ -z "${file_properties}" ] || [ "${file_properties}" == "null" ]; then
    echo "-- ERROR: 'properties' not found"
    errorFound="true"
  else
    echo "-- Loading properties as variables"
    filename_tmp=${path_tmpFolder}/app.properties
    echo "${file_properties}" | base64 --decode > "${filename_tmp}"
    source "${filename_tmp}"
    echo "-- Done"
  fi
  if [ -z "${deploymentKey}" ] || [ "${deploymentKey}" == "null" ]; then
    echo "-- ERROR: 'deploymentKey' not found"
    errorFound="true"
  fi
  echo ""

  arrStrCertsPaths_REST=""${VAULT_CLIENT_PATH_TS}!${certAlias}" "${VAULT_CLIENT_PATH_RS}!repl-server""
  arrStrCertsPaths_k8s=""${DS_SECRETS}!${certAlias}" "${tmpRSsecretsPath}!repl-server""
  setupDS_TrustAndKeyStores "${VAULT_BASE_URL}" "${VAULT_TOKEN}" "${JAVA_CACERTS}" "${truststorePwd}" "${arrStrCertsPaths_REST}" "${certAlias}" "${path_keystoreFile}" "${tokenStoreCertPwd}" "${SECRETS_MODE}" "${arrStrCertsPaths_k8s}"

  startDS_ifInstalled
  # =======================================================================
  # Below code is only exectuted if directory server has not been installed
  # -----------------------------------------------------------------------
  echo "======================================"
  echo "Configuring a NEW Token Store instance"
  echo "======================================"
  echo ""
  prepareServerFolders # Must be executed before running first DS binary command on server
  optimizeJVMforPod

  if [ "${errorFound}" == "false" ]; then
    echo "-> Creating password files"
    echo "${rootUserPassword}" > "${path_rootUserPasswordFile}"
    echo "${monitorUserPassword}" > "${path_monitorUserPasswordFile}"
    echo "${tokenStoreCertPwd}" > "${path_keystorePinFile}"
    echo "-- Done"
    echo ""

    echo "Setting up Directory Server (DS) as Token Store"
    echo "----------------------------------------------"
    echo "-- Current Token Store service svc is ${svcURL_curr}"
    echo "-- Creating Token Store installation command"
    setupcommand=$( echo ${DS_APP}/setup \
      --rootUserDN "'${rootUserDN}'" \
      --deploymentKey "'${deploymentKey}'" \
      --deploymentKeyPasswordFile "'${path_rootUserPasswordFile}'" \
      --rootUserPasswordFile "'${path_rootUserPasswordFile}'" \
      --monitorUserPasswordFile "'${path_monitorUserPasswordFile}'" \
      --instancePath "'${DS_INSTANCE}'" \
      --hostname "'${svcURL_curr}'" \
      --serverId "'${HOSTNAME}'" \
      --certNickname "'${certAlias}'" --enableStartTLS \
      --usePkcs12keyStore "'${path_keystoreFile}'" \
      --keyStorePasswordFile "'${path_keystorePinFile}'" \
      --ldapPort ${ldapPort} --ldapsPort ${ldapsPort} \
      --httpsPort ${httpsPort} --httpPort ${httpPort} \
      --adminConnectorPort ${adminConnectorPort} \
      --start \
      --profile am-cts \
      --set am-cts/amCtsAdminPassword:${amCtsAdminPassword} \
      --set am-cts/baseDn:${DS_BASE_DN} \
      --set am-cts/backendName:tokenStore \ )

    if [ "${SELF_REPLICATE,,}" == "true" ]; then
      echo "-- SELF_REPLICATE is true"
      if [ "${podIndx}" -gt "0" ]; then
        svcURL_dest="${POD_BASENAME}-$((${podIndx}-1)).${POD_SERVICE_NAME}.${POD_NAMESPACE}.svc.${CLUSTER_DOMAIN}"
      else
        svcURL_dest="${POD_BASENAME}-$((${podIndx}+1)).${POD_SERVICE_NAME}.${POD_NAMESPACE}.svc.${CLUSTER_DOMAIN}"
      fi
      echo "-- Bootstrap Servers for Self Replication are:"
      echo "   > ${svcURL_curr}:${replicationPort}"
      echo "   > ${svcURL_dest}:${replicationPort}"
      setupcommand=${setupcommand}$( echo \
        --replicationPort ${replicationPort} \
        --bootstrapReplicationServer "'${svcURL_curr}:${replicationPort}'" \
        --bootstrapReplicationServer "'${svcURL_dest}:${replicationPort}'" \ )
    elif [ "${SELF_REPLICATE,,}" == "false" ]; then
      echo "-- SELF_REPLICATE is NOT true"
      echo "-- Replication Servers(RS) in the environment are:"
      echo "   NOTE: Atleast one Replication Server must be alive and working for replication to kick in"
      IFS=',' read -ra arrRS_SVC <<< "${RS_SVC}"
      for rsSVC  in "${arrRS_SVC[@]}"
      do
        echo "   > ${rsSVC}"
        setupcommand=${setupcommand}$( echo --bootstrapReplicationServer "'${rsSVC}'" \ )
      done
    fi

    setupcommand=${setupcommand}$(echo --acceptLicense)
    echo "${setupcommand}" > "${path_tmpScript}"
    echo "-- Command setup complete"
    echo ""
    echo "-> Executing setup command"
    bash "${path_tmpScript}"
    echo "-- Done"
    echo ""

    setupSelfRepl_ifEnabled "${SELF_REPLICATE,,}" "${rootUserDN}" "${path_rootUserPasswordFile}" ${httpsPort} ${adminConnectorPort} "${DS_BASE_DN}" "${diskLowThreshold}" "${diskFullThreshold}" "https"
    checkServerIsAlive errorFound "${svcURL_curr}" "https" "${httpsPort}"
    if [ "${errorFound}" == "false" ]; then
      allowTruststoreAccessByDS "${svcURL_curr}" ${adminConnectorPort} "${rootUserDN}" "${path_rootUserPasswordFile}" "${JAVA_CACERTS}" "${truststorePwd}"
      disableInsecureCommsDS  "${DISABLE_INSECURE_COMMS}" "${svcURL_curr}" ${adminConnectorPort} "${rootUserDN}" "${path_rootUserPasswordFile}"
      setupCustomJavaProperties  "${USE_CUSTOM_JAVA_PROPS}" "javaProperties" "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_CONFIGMAPS}" "${VAULT_CLIENT_PATH_TS}" "${VAULT_TOKEN}"
      getReplicationStatus "${svcURL_curr}" "${path_rootUserPasswordFile}" "${adminConnectorPort}" "${rootUserDN}"
      stopDS
      startDS "foreground"
    else
      echo "-- ERROR: Please check log above for reason for failure"
      echo "-- Exiting ..."
      exit 1
    fi
  else
    echo "-- ERROR: Some required Secrets and/or Configuration not retreived"
    echo "-- Exiting ..."
    exit 1
  fi
fi
