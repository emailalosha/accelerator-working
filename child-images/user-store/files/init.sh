#!/bin/bash
# =======================================================
# Script to be executed by ForgeRock Directory Server(DS)
# Kubernetes container on startup to configure itself as
# a ForgeRock Directory Server (User Store).

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
echo "[[ ForgeRock Directory Server (DS) - User Store ]]"
echo "->             Server Name: ${HOSTNAME}"
echo "->                 DS_HOME: ${DS_HOME}"
echo "->                  DS_APP: ${DS_APP}"
echo "->              DS_SECRETS: ${DS_SECRETS}"
echo "->           DS_CONFIGMAPS: ${DS_CONFIGMAPS}"
echo "->              DS_BASE_DN: ${DS_BASE_DN}"
echo "->          SELF_REPLICATE: ${SELF_REPLICATE}"
echo "->             LOAD_SCHEMA: ${LOAD_SCHEMA}"
echo "->    LOAD_CUSTOM_DSCONFIG: ${LOAD_CUSTOM_DSCONFIG}"
echo "->             DS_INSTANCE: ${DS_INSTANCE}"
echo "->              DS_SCRIPTS: ${DS_SCRIPTS}"
echo "->              DS_VERSION: ${DS_VERSION}"
echo "->          VAULT_BASE_URL: ${VAULT_BASE_URL}"
echo "->    VAULT_CLIENT_PATH_US: ${VAULT_CLIENT_PATH_US}"
echo "->    VAULT_CLIENT_PATH_RS: ${VAULT_CLIENT_PATH_RS}"
echo "->             VAULT_TOKEN: ${VAULT_TOKEN}"
echo "->           POD_NAMESPACE: ${POD_NAMESPACE}"
echo "->            POD_BASENAME: ${POD_BASENAME}"
echo "->        POD_SERVICE_NAME: ${POD_SERVICE_NAME}"
echo "->          CLUSTER_DOMAIN: ${CLUSTER_DOMAIN}"
echo "->               JAVA_HOME: ${JAVA_HOME}"
echo "->            JAVA_CACERTS: ${JAVA_CACERTS}"
echo "->   USE_CUSTOM_JAVA_PROPS: ${USE_CUSTOM_JAVA_PROPS}"
echo "->  DISABLE_INSECURE_COMMS: ${DISABLE_INSECURE_COMMS}"
echo "->                  RS_SVC: ${RS_SVC}"
echo "->            SECRETS_MODE: ${SECRETS_MODE}"
echo "->                ENV_TYPE: ${ENV_TYPE}"
echo "->            ADD_IDM_REPO: ${ADD_IDM_REPO}"
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
amIdentityStoreAdminPassword=
userStoreCertPwd=
truststorePwd=
file_properties=
deploymentKey=
file_schema=
file_dsconfig=
certAlias="user-store"
path_userSchemaFile="${DS_INSTANCE}/db/schema/schema.ldif"
path_DSconfigFile="${path_tmpFolder}/dsconfig_custom.sh"
path_tmpScript="${path_tmpFolder}/setupDS.sh"
# Note that format for statefulset pod service URL is {hostname}.{service-name}.{POD_NAMESPACE}.svc.{CLUSTER_DOMAIN}
svcURL_curr="${HOSTNAME}.${POD_SERVICE_NAME}.${POD_NAMESPACE}.svc.${CLUSTER_DOMAIN}"
tmpRSsecretsPath="/opt/rs/secrets"

echo "Setting up pre-requsite(s)"
echo "--------------------------"
mkdir -p "${path_tmpFolder}"
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
    echo ""
    errorFound="true"
  fi

  if [ -z "${VAULT_CLIENT_PATH_US}" ]; then
    echo "-> ERROR: VAULT_CLIENT_PATH_US is empty. Required when using Repication Server."
    echo "-- Please set environment variable to the path for User Store secrets in your Secrets Manager"
    echo ""
    errorFound="true"
  fi

  if [ -z "${VAULT_CLIENT_PATH_RS}" ]; then
    echo "-> ERROR: VAULT_CLIENT_PATH_RS is empty."
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
  echo "-- Please set to the required DS_BASE_DN for the User Store. E.g. 'ou=users'"
  echo ""
  errorFound="true"
fi

if [ -z "${SELF_REPLICATE}" ]; then
  echo "-> WARN: SELF_REPLICATE is empty."
  echo "-- Setting to 'true' as default. Please set in future to 'true' or 'false'"
  echo ""
  export SELF_REPLICATE="true"
fi

if [ -z "${LOAD_SCHEMA}" ]; then
  echo "-> WARN: LOAD_SCHEMA is empty."
  echo "-- Setting to 'false' as default. Please set in future to 'true' or 'false'"
  echo ""
  export LOAD_SCHEMA="false"
fi

if [ -z "${LOAD_CUSTOM_DSCONFIG}" ]; then
  echo "-> WARN: LOAD_CUSTOM_DSCONFIG is empty."
  echo "-- Setting to 'false' as default. Please set in future to 'true' or 'false'"
  echo ""
  export LOAD_CUSTOM_DSCONFIG="false"
fi

if [ -z "${USE_CUSTOM_JAVA_PROPS}" ]; then
  echo "-> WARN: USE_CUSTOM_JAVA_PROPS is empty."
  echo "-- Setting to 'false' as default. Please set in future to 'true' or 'false'"
  echo ""
  export USE_CUSTOM_JAVA_PROPS="false"
fi

if [ -z "${DISABLE_INSECURE_COMMS}" ]; then
  echo "-> WARN: DISABLE_INSECURE_COMMS is empty."
  echo "-- Setting to 'false' as default. Please set in future to 'true' or 'false'"
  echo ""
  export DISABLE_INSECURE_COMMS="false"
fi

if [ -z "${RS_SVC}" ]; then
  echo "-> WARN: RS_SVC is empty. Required when using Repication Server."
  export RS_SVC=""
  if [ "${SELF_REPLICATE}" != "true" ]; then
    echo "-- RS_SVC must be set to the comma separated list of Replication Servers (RS) SVC if SELF_REPLICATE is NOT true."
    echo "-- Format is {rs1-pod-name}.{service-name}.{POD_NAMESPACE}.svc.cluster.local,{rs2-pod-name}.{service-name}.{POD_NAMESPACE}.svc.cluster.local"
    errorFound="true"
  fi
fi
if [ -z "${ADD_IDM_REPO}" ]; then
  echo "-> WARN: ADD_IDM_REPO is empty."
  echo "-- Setting to 'false' as default. Please set in future to 'true' or 'false'"
  echo ""
  export ADD_IDM_REPO="false"
fi
echo "-- Done"
echo ""

if [ "${errorFound}" == "false" ]; then
  echo "Getting Secrets and Configuration"
  echo "---------------------------------"
  echo ""
  # Getting Secrets
  getSecretAndConfig rootUserPassword "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_SECRETS}" "rootUserPassword" "${VAULT_CLIENT_PATH_US}" "${VAULT_TOKEN}"
  getSecretAndConfig monitorUserPassword "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_SECRETS}" "monitorUserPassword" "${VAULT_CLIENT_PATH_US}" "${VAULT_TOKEN}"
  getSecretAndConfig amIdentityStoreAdminPassword "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_SECRETS}" "amIdentityStoreAdminPassword" "${VAULT_CLIENT_PATH_US}" "${VAULT_TOKEN}"
  getSecretAndConfig userStoreCertPwd "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_SECRETS}" "userStoreCertPwd" "${VAULT_CLIENT_PATH_US}" "${VAULT_TOKEN}"
  getSecretAndConfig truststorePwd "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_SECRETS}" "truststorePwd" "${VAULT_CLIENT_PATH_US}" "${VAULT_TOKEN}"
  getSecretAndConfig deploymentKey "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_SECRETS}" "deploymentKey" "${VAULT_CLIENT_PATH_US}" "${VAULT_TOKEN}"
  # Getting Configuation
  getSecretAndConfig file_properties "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_CONFIGMAPS}" "properties" "${VAULT_CLIENT_PATH_US}" "${VAULT_TOKEN}" "true"
  getSecretAndConfig file_schema "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_CONFIGMAPS}" "file_schema" "${VAULT_CLIENT_PATH_US}" "${VAULT_TOKEN}" "true"
  getSecretAndConfig file_dsconfig "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_CONFIGMAPS}" "file_dsconfig" "${VAULT_CLIENT_PATH_US}" "${VAULT_TOKEN}" "true"

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
  if [ -z "${amIdentityStoreAdminPassword}" ] || [ "${amIdentityStoreAdminPassword}" == "null" ]; then
    echo "-- ERROR: 'amIdentityStoreAdminPassword' not found"
    errorFound="true"
  fi
  if [ -z "${userStoreCertPwd}" ] || [ "${userStoreCertPwd}" == "null" ]; then
    echo "-- ERROR: 'userStoreCertPwd' not found"
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

  arrStrCertsPaths_REST=""${VAULT_CLIENT_PATH_US}!${certAlias}" "${VAULT_CLIENT_PATH_RS}!repl-server""
  arrStrCertsPaths_k8s=""${DS_SECRETS}!${certAlias}" "${tmpRSsecretsPath}!repl-server""
  setupDS_TrustAndKeyStores "${VAULT_BASE_URL}" "${VAULT_TOKEN}" "${JAVA_CACERTS}" "${truststorePwd}" "${arrStrCertsPaths_REST}" "${certAlias}" "${path_keystoreFile}" "${userStoreCertPwd}" "${SECRETS_MODE}" "${arrStrCertsPaths_k8s}"

  startDS_ifInstalled
  # =======================================================================
  # Below code is only exectuted if directory server has not been installed
  # -----------------------------------------------------------------------
  echo "====================================="
  echo "Configuring a NEW User Store instance"
  echo "====================================="
  echo ""
  prepareServerFolders # Must be executed before running first DS binary command on server
  optimizeJVMforPod

  if [ "${errorFound}" == "false" ]; then
    echo "-> Creating password files"
    echo "${rootUserPassword}" > "${path_rootUserPasswordFile}"
    echo "${monitorUserPassword}" > "${path_monitorUserPasswordFile}"
    echo "${userStoreCertPwd}" > "${path_keystorePinFile}"
    echo "-- Done"
    echo ""

    echo "Setting up Directory Server (DS) as User Store"
    echo "----------------------------------------------"
    echo "-- Current User Store service svc is ${svcURL_curr}"
    echo "-- Creating User Store installation command"
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
      --httpPort ${httpPort} --httpsPort ${httpsPort} \
      --adminConnectorPort ${adminConnectorPort} \
      --profile am-identity-store \
      --set am-identity-store/amIdentityStoreAdminPassword:${amIdentityStoreAdminPassword} \
      --set am-identity-store/baseDn:${DS_BASE_DN} \
      --set am-identity-store/backendName:userStore \ )

    if [ "${ADD_IDM_REPO}" == "true" ]; then
      if [ -n "${idmCompanyDomain}" ]; then
        echo "-- Adding IDM Repo profile to command"
          setupcommand=${setupcommand}$( echo \
            --profile idm-repo \
            --set idm-repo/domain:${idmCompanyDomain} \
            --set idm-repo/backendName:idmRepo \ )
      else
        echo ""
        echo "-- ERROR: Domain for IDM Repo is empty."
        echo "   User Store will NOT be setup with an IDM Repo."
        echo "   Please correct and try again."
        echo ""
      fi
    fi

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
      echo "-- SELF_REPLICATE is false"
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

    if [ "${LOAD_SCHEMA,,}" == "true" ] && [ "${file_schema}" != "null" ] && [ "${file_schema}" != "" ]; then
      echo "-> Loading schema file"
      echo "-- LOAD_SCHEMA set to '${LOAD_SCHEMA}'"
      if [ -z "${file_schema}" ] || [ "${file_schema}" == "null" ]; then
        echo "-- ERROR: 'file_schema' not found"
        errorFound="true"
      else
        echo "-- Decoding Base64 string and saving to file"
        echo "${file_schema}" | base64 --decode > "${path_userSchemaFile}"
        echo "-- Updating the file execution"
        chmod +x "${path_userSchemaFile}"
      fi
      echo "-- Done"
      echo ""
    fi

    echo "--- copy custom schema to ds ---"
    cp ${DS_HOME}/setupFiles/*.ldif ${DS_INSTANCE}/db/schema/

    startDS "background"
    setupSelfRepl_ifEnabled "${SELF_REPLICATE,,}" "${rootUserDN}" "${path_rootUserPasswordFile}" ${httpsPort} ${adminConnectorPort} "${DS_BASE_DN}" "${diskLowThreshold}" "${diskFullThreshold}" "https"
    checkServerIsAlive errorFound "${svcURL_curr}" "https" "${httpsPort}"
    if [ "${errorFound}" == "false" ]; then
      if [ "${LOAD_CUSTOM_DSCONFIG,,}" == "true" ] && [ "${LOAD_CUSTOM_DSCONFIG}" != "null" ]; then
        echo "-> User defined DS configuration"
        echo "-- LOAD_CUSTOM_DSCONFIG set to '${LOAD_CUSTOM_DSCONFIG}'"
        if [ -z "${file_dsconfig}" ] || [ "${file_dsconfig}" == "null" ] || [ "${file_dsconfig}" == "" ]; then
          echo "-- WARN: 'file_dsconfig' empty or not found"
          errorFound="true"
        else
          echo ""
          echo "-> Processing rerieved DS config script"
          echo "-- Decoding Base64 string and saving to file"
          echo "${file_dsconfig}" | base64 --decode > "${path_DSconfigFile}"
          echo "-- Updating the file permission for execution"
          chmod +x "${path_DSconfigFile}"
          echo "-- Executing ..."
          source "${path_DSconfigFile}"
        fi
        echo "-- Done"
        echo ""
      fi
      allowTruststoreAccessByDS "${svcURL_curr}" ${adminConnectorPort} "${rootUserDN}" "${path_rootUserPasswordFile}" "${JAVA_CACERTS}" "${truststorePwd}"
      disableInsecureCommsDS  "${DISABLE_INSECURE_COMMS}" "${svcURL_curr}" ${adminConnectorPort} "${rootUserDN}" "${path_rootUserPasswordFile}"
      setupCustomJavaProperties  "${USE_CUSTOM_JAVA_PROPS}" "javaProperties" "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${DS_CONFIGMAPS}" "${VAULT_CLIENT_PATH_US}" "${VAULT_TOKEN}"
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