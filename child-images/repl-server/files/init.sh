#!/bin/bash
# =======================================================
# Script to be executed by forgerock Directory Server(DS)
# Kubernetes container on startup to configure itself as
# a forgerock Directory Server (Replication Server).

# Created 23/08/2018
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
echo "[[ forgerock Directory Server (DS) - Replication Server ]]"
echo "->               Server Name: ${HOSTNAME}"
echo "->                   DS_HOME: ${DS_HOME}"
echo "->                    DS_APP: ${DS_APP}"
echo "->                DS_SECRETS: ${DS_SECRETS}"
echo "->             DS_CONFIGMAPS: ${DS_CONFIGMAPS}"
echo "->                  ENV_TYPE: ${ENV_TYPE}"
echo "->               DS_INSTANCE: ${DS_INSTANCE}"
echo "->                DS_SCRIPTS: ${DS_SCRIPTS}"
echo "->                DS_VERSION: ${DS_VERSION}"
echo "->            VAULT_BASE_URL: ${VAULT_BASE_URL}"
echo "->      VAULT_CLIENT_PATH_RS: ${VAULT_CLIENT_PATH_RS}"
echo "->      VAULT_CLIENT_PATH_US: ${VAULT_CLIENT_PATH_US}"
echo "->      VAULT_CLIENT_PATH_TS: ${VAULT_CLIENT_PATH_TS}"
echo "->      VAULT_CLIENT_PATH_CS: ${VAULT_CLIENT_PATH_CS}"
echo "->               VAULT_TOKEN: ${VAULT_TOKEN}"
echo "->            GLOBAL_REPL_ON: ${GLOBAL_REPL_ON}"
echo "->         GLOBAL_REPL_FQDNS: ${GLOBAL_REPL_FQDNS}"
echo "->             POD_NAMESPACE: ${POD_NAMESPACE}"
echo "->              POD_BASENAME: ${POD_BASENAME}"
echo "->          POD_SERVICE_NAME: ${POD_SERVICE_NAME}"
echo "->            CLUSTER_DOMAIN: ${CLUSTER_DOMAIN}"
echo "->                 JAVA_HOME: ${JAVA_HOME}"
echo "->              JAVA_CACERTS: ${JAVA_CACERTS}"
echo "->     USE_CUSTOM_JAVA_PROPS: ${USE_CUSTOM_JAVA_PROPS}"
echo "->              SECRETS_MODE: ${SECRETS_MODE}"
echo "->                  ENV_TYPE: ${ENV_TYPE}"
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
certAlias="repl-server"
path_tmpScript="${path_tmpFolder}/setupDS.sh"
rootUserPassword=
monitorUserPassword=
keystorePwd=
truststorePwd=
deploymentKey=
properties=
tmpUSsecretsPath="/opt/us/secrets"
tmpTSsecretsPath="/opt/ts/secrets"
tmpCSsecretsPath="/opt/cs/secrets"

echo "Setting up pre-requsite(s)"
echo "--------------------------"
mkdir -p ${path_tmpFolder}
echo "-- podIndx is ${podIndx}"
echo "-- Done"
echo ""

echo "Checking Environment variable"
echo "-----------------------------"
if [ -z "${ENV_TYPE}" ]; then
  echo "-> ENV_TYPE is empty."
  echo "-- Please set environment variable to 'fat', 'fit', 'sit', 'uat', 'nft', etc."
  errorFound="true"
  echo ""
fi

if [ -z "${SECRETS_MODE}" ]; then
  echo "-> SECRETS_MODE is empty."
  echo "-- Setting to 'k8s' as default. Please set in future to 'k8s' or 'REST'"
  echo "   Former where secrets and config are stored in K8s, later in a REST secrets manager."
  export SECRETS_MODE="k8s"
fi

if [ "${SECRETS_MODE,,}" != "k8s" ]; then
  if [ -z "${VAULT_BASE_URL}" ]; then
    echo "-> ERROR: VAULT_BASE_URL is empty."
    echo "-- Please set environment variable to the Kubernetes service url for the VAULT solution."
    echo "-- Format is {service-name}.{POD_NAMESPACE}.svc"
    echo ""
    errorFound="true"
  fi

  if [ -z "${VAULT_CLIENT_PATH_RS}" ]; then
    echo "-> ERROR: VAULT_CLIENT_PATH_RS is empty."
    echo "-- Please set environment variable to the path for Replication Server secrets solution"
    echo ""
    errorFound="true"
  fi

  if [ -z "${VAULT_CLIENT_PATH_US}" ]; then
    echo "-> ERROR: VAULT_CLIENT_PATH_US is empty."
    echo "-- Please set environment variable to the path for User Store secrets solution"
    echo ""
    errorFound="true"
  fi

  if [ -z "${VAULT_CLIENT_PATH_TS}" ]; then
    echo "-> ERROR: VAULT_CLIENT_PATH_TS is empty."
    echo "-- Please set environment variable to the path for Token Store secrets solution"
    echo ""
    errorFound="true"
  fi

  if [ -z "${VAULT_CLIENT_PATH_CS}" ]; then
    echo "-> WARN: VAULT_CLIENT_PATH_CS is empty."
    echo "-- Please set environment variable to the path for Config Store secrets solution if this is required"
    echo ""
  fi
  
  if [ -z "${VAULT_TOKEN}" ]; then
    echo "-> ERROR: VAULT_TOKEN is empty."
    echo "-- Please set environment variable to VAULT Token to use to access VAULT solution."
    echo ""
    errorFound="true"
  fi
  
else
  echo "-> Skipping Secrets and Config REST details checking"
  echo "-- Done"
  echo ""
fi

if [ -z "${POD_SERVICE_NAME}" ]; then
  echo "-> POD_SERVICE_NAME is empty."
  echo "-- Please set to the name of kubernetes service used to access the POD"
  echo ""
  errorFound="true"
fi

if [ -z "${CLUSTER_DOMAIN}" ]; then
  echo "-> CLUSTER_DOMAIN is empty."
  echo "-- Please set to the kubernetes cluster domain. E.g. cluster.local"
  echo ""
  errorFound="true"
fi

if [ -z "${POD_BASENAME}" ]; then
  echo "-> POD_BASENAME is empty."
  echo "-- Please set to the metadata.name from the deploy.yaml"
  echo ""
  errorFound="true"
fi

if [ -z "${DS_INSTANCE}" ]; then
  echo "-> ERROR: DS_INSTANCE is empty. "
  echo "-- Please set to the path of the DS instance directory. E.g. /opt/ds/instance"
  echo ""
  errorFound="true"
fi

if [ -z "${GLOBAL_REPL_ON}" ]; then
  echo "-> ERROR: GLOBAL_REPL_ON is empty. "
  echo "-- Setting to 'false' as default. Please set to 'true' or 'false' to enable Global Replication across Region/Cloud Service Proivder/Cluster/Namespace."
  echo ""
  export GLOBAL_REPL_ON="false"
fi

if [ -z "${GLOBAL_REPL_FQDNS}" ] && [ "${GLOBAL_REPL_ON,,}" == "true" ]; then
  echo "-> ERROR: GLOBAL_REPL_FQDNS is empty. "
  echo "-- Please set to the FQDN/IP of the destination Global Replication Server. E.g. 80.100.0.10"
  echo ""
  errorFound="true"
fi

if [ -z "${USE_CUSTOM_JAVA_PROPS}" ]; then
  echo "-> WARN: USE_CUSTOM_JAVA_PROPS is empty."
  echo "-- Setting to 'false' as default. Please set in future to 'true' or 'false' "
  echo ""
  export USE_CUSTOM_JAVA_PROPS="false"
fi
echo "-- Done"
echo ""

if [ "${errorFound}" == "false" ]; then
  echo "Getting Secrets and Configuration"
  echo "---------------------------------"
  echo ""
  # Getting Secrets
  getSecretAndConfig rootUserPassword "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_SECRETS}" "rootUserPassword" "${VAULT_CLIENT_PATH_RS}" "${VAULT_TOKEN}"
  getSecretAndConfig monitorUserPassword "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_SECRETS}" "monitorUserPassword" "${VAULT_CLIENT_PATH_RS}" "${VAULT_TOKEN}"
  getSecretAndConfig keystorePwd "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_SECRETS}" "keystorePwd" "${VAULT_CLIENT_PATH_RS}" "${VAULT_TOKEN}"
  getSecretAndConfig truststorePwd "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_SECRETS}" "truststorePwd" "${VAULT_CLIENT_PATH_RS}" "${VAULT_TOKEN}"
  getSecretAndConfig deploymentKey "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_SECRETS}" "deploymentKey" "${VAULT_CLIENT_PATH_RS}" "${VAULT_TOKEN}"
  # Getting Configuation
  getSecretAndConfig properties "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_CONFIGMAPS}" "properties" "${VAULT_CLIENT_PATH_US}" "${VAULT_TOKEN}" "true"

  echo "Verifying Secrets and Configuration"
  echo "-----------------------------------"
  echo ""
  if [ -z "$rootUserPassword" ] || [ "${rootUserPassword}" == "null" ]; then
    echo "-- rootUserPassword not found in response"
    errorFound="true"
  fi
  if [ -z "$monitorUserPassword" ] || [ "${monitorUserPassword}" == "null" ]; then
    echo "-- monitorUserPassword not found in response"
    errorFound="true"
  fi
  if [ -z "${keystorePwd}" ] || [ "${keystorePwd}" == "null" ]; then
    echo "-- keystorePwd not found"
    errorFound="true"
  fi
  if [ -z "${truststorePwd}" ] || [ "${truststorePwd}" == "null" ]; then
    echo "-- truststorePwd not found"
    errorFound="true"
  fi
  if [ -z "${properties}" ] || [ "${properties}" == "null" ]; then
    echo "-- properties not found"
    echo "-- Exiting ..."
    echo ""
    errorFound="true"
  else
    echo "-- Loading properties as variables"
    filename_tmp=${path_tmpFolder}/app.properties
    echo "${properties}" | base64 --decode > "${filename_tmp}"
    source "${filename_tmp}"
    echo "-- Done"
  fi
  if [ -z "${deploymentKey}" ] || [ "${deploymentKey}" == "null" ]; then
    echo "-- ERROR: 'deploymentKey' not found"
    errorFound="true"
  fi
  echo ""

  arrStrCertsPaths_REST=""${VAULT_CLIENT_PATH_RS}!${certAlias}" "${VAULT_CLIENT_PATH_US}!user-store" "${VAULT_CLIENT_PATH_TS}!token-store" "${VAULT_CLIENT_PATH_CS}!config-store""
  arrStrCertsPaths_k8s=""${DS_SECRETS}!${certAlias}" "${tmpUSsecretsPath}!user-store" "${tmpTSsecretsPath}!token-store" "${tmpCSsecretsPath}!config-store""
  setupDS_TrustAndKeyStores "${VAULT_BASE_URL}" "${VAULT_TOKEN}" "${JAVA_CACERTS}" "${truststorePwd}" "${arrStrCertsPaths_REST}" "${certAlias}" "${path_keystoreFile}" "${keystorePwd}" "${SECRETS_MODE}" "${arrStrCertsPaths_k8s}"

  startDS_ifInstalled
  # =======================================================================
  # Below code is only exectuted if directory server has not been installed
  # -----------------------------------------------------------------------
  echo "============================================="
  echo "Configuring a NEW Replication Server instance"
  echo "============================================="
  echo ""
  prepareServerFolders # Must be executed before running first DS binary command on server
  optimizeJVMforPod

  if [ "${errorFound}" == "false" ]; then
    echo "-> Creating password files"
    echo "${rootUserPassword}" > "${path_rootUserPasswordFile}"
    echo "${monitorUserPassword}" > "${path_monitorUserPasswordFile}"
    echo "${keystorePwd}" > "${path_keystorePinFile}"
    echo "-- Done"
    echo ""

    echo "Setting up Directory Server (DS) as Replication Server"
    echo "------------------------------------------------------"
    # Note that format for statefulset pod service URL is {hostname}.{service-name}.{POD_NAMESPACE}.svc.cluster.local
    svcURL_RS="${POD_BASENAME}-${podIndx}.${POD_SERVICE_NAME}.${POD_NAMESPACE}.svc.${CLUSTER_DOMAIN}"
    echo "-- Current Replication Server service svc is ${svcURL_RS}"
    if [ "${podIndx}" -gt "0" ]; then
      svcURL_dest="${POD_BASENAME}-$((podIndx - 1)).${POD_SERVICE_NAME}.${POD_NAMESPACE}.svc.${CLUSTER_DOMAIN}"
    else
      svcURL_dest="${POD_BASENAME}-$((podIndx + 1)).${POD_SERVICE_NAME}.${POD_NAMESPACE}.svc.${CLUSTER_DOMAIN}"
    fi
    echo "-- Bootstrap Replication Server will be ${svcURL_dest}:${replicationPort}"
    echo ""
    echo "-> Creating Replication Server installation command"
    setupcommand=$( echo ${DS_APP}/setup \
     --rootUserDN "'${rootUserDN}'" \
     --deploymentKey "'${deploymentKey}'" \
     --deploymentKeyPasswordFile "'${path_rootUserPasswordFile}'" \
     --rootUserPasswordFile "'${path_rootUserPasswordFile}'" \
     --monitorUserPasswordFile "'${path_monitorUserPasswordFile}'" \
     --hostname "'${svcURL_RS}'" \
     --serverId "'${HOSTNAME}'" \
     --instancePath "'${DS_INSTANCE}'" \
     --adminConnectorPort ${adminConnectorPort} \
     --httpsPort ${httpsPort} \
     --start \
     --certNickname "'${certAlias}'" \
     --usePkcs12keyStore "'${path_keystoreFile}'" \
     --keyStorePasswordFile "'${path_keystorePinFile}'" \
     --replicationPort ${replicationPort} \
     --bootstrapReplicationServer "'${svcURL_RS}:${replicationPort}'" \
     --bootstrapReplicationServer "'${svcURL_dest}:${replicationPort}'" \ )
    echo ""
    if [ "${GLOBAL_REPL_ON,,}" == "true" ]; then
      echo "-- Global Replication has been requested. The Servers are:"
      if [[ "${GLOBAL_REPL_FQDNS}" != "" ]]; then
        IFS=',' read -ra fqdns <<< "${GLOBAL_REPL_FQDNS}"
        # Note that format for statefulset pod service URL is {hostname}.{service-name}.{POD_NAMESPACE}.svc.cluster.local
        fqdnCount=${#fqdns[@]}
        if [[ ${fqdnCount} -gt 0 ]]; then
          echo "   NOTE: Atleast one Replication Server must be alive and working for replication to kick in"
          for (( i=0; i<${fqdnCount}; i++ ))
          do
            fqdnGbl="${fqdns[${i}]}"
            echo "   > ${fqdnGbl}"
            setupcommand=${setupcommand}$( echo --bootstrapReplicationServer "'${fqdnGbl}'" \ )
          done
        else
          echo "-- No FQDN foud for Global Replication Server(s)."
          echo "-- Please check variable GLOBAL_REPL_FQDNS"
          echo "-- Expected format '{global-fqdn}:{replication-port},{global-fqdn}:{replication-port}'"
          errorFound="true"
          echo ""
        fi
      else
        echo "-- GLOBAL_REPL_FQDNS is empty"
        echo "-- Please set to comma separated Global RS FQDNs"
        echo "-- Expected format '{global-fqdn}:{replication-port},{global-fqdn}:{replication-port}'"
        errorFound="true"
        echo ""
      fi
    fi
    setupcommand=${setupcommand}$( echo --acceptLicense )
    echo "${setupcommand}" > "${path_tmpScript}"
    echo "-- Command setup complete"
    echo ""
    echo "-> Executing setup command"
    bash ${path_tmpScript}
    echo "-- Done"
    echo ""
    allowTruststoreAccessByDS "${svcURL_RS}" ${adminConnectorPort} "${rootUserDN}" "${path_rootUserPasswordFile}" "${JAVA_CACERTS}" "${truststorePwd}"
    configureReplicationThreshold "${svcURL_RS}" ${adminConnectorPort} "${rootUserDN}" "${path_rootUserPasswordFile}" "${diskLowThreshold}" "${diskFullThreshold}"
    setupCustomJavaProperties  "${USE_CUSTOM_JAVA_PROPS}" "javaProperties" "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_CONFIGMAPS}" "${VAULT_CLIENT_PATH_RS}" "${VAULT_TOKEN}"
    stopDS
    startDS "foreground" ${adminConnectorPort}
  else
    echo "-- ERROR: Some required Secrets and/or Configuration not retreived"
    echo "-- Exiting ..."
    exit 1
  fi
fi
