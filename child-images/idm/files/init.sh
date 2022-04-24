#!/bin/bash
# =======================================================
# Script to be executed by ForgeRock Access Management
# Kubernetes container on startup.
# Created 29/03/2018
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

function startIDM() {
  echo -n "Starting IDM"
  nohup "${IDM_HOME}/startup.sh" > "${path_serverstartlog}" 2>&1 </dev/null &
  tail -f -n 100 "${path_serverstartlog}"
}

echo "----------------------------------------------------------------"
echo "****************************************************************"
echo "[[               ForgeRock Identity Manager (IDM)             ]]"
echo "->                  Server Name: ${HOSTNAME}                    "
echo "->                     ENV_TYPE: ${ENV_TYPE}                    "
echo "->                     IDM Home: ${IDM_HOME}                    "
echo "->                 IDM Projects: ${IDM_PROJECTS}                "
echo "->                    NAMESPACE: ${NAMESPACE}               "
echo "->          DS_HOSTNAME_PRIMARY: ${DS_HOSTNAME_PRIMARY}         "
echo "->        DS_HOSTNAME_SECONDARY: ${DS_HOSTNAME_SECONDARY}       "
echo "->               VAULT_BASE_URL: ${VAULT_BASE_URL}              "
echo "->        VAULT_CLIENT_PATH_IDM: ${VAULT_CLIENT_PATH_IDM}       "
echo "->         VAULT_CLIENT_PATH_US: ${VAULT_CLIENT_PATH_US}        "
echo "->                  VAULT_TOKEN: ${VAULT_TOKEN}                 "
echo "->                 SECRETS_MODE: ${SECRETS_MODE}                "
echo "->                  IDM_PROFILE: ${IDM_PROFILE}                 "
echo "----------------------------------------------------------------"
echo ""

# Local Variables
# ---------------
errorFound="false"
path_tmpFolder="/tmp/idm"
path_setupcompleted="${IDM_HOME}/.setupcompleted"
path_serverstartlog="${IDM_HOME}/logs/serverstart.log"
path_repojson="${IDM_HOME}/conf/repo.ds.json"
tmpUSsecretsPath="/opt/us/secrets"
dsBindDNpwd=
truststorePwd=
keystorePwd=
us_certificate=
file_managed_json=
file_repo_ds_json=
file_startup_sh_bak=
file_sync_json=
file_system_properties=
file_boot_properties=
file_properties=

echo "============================="
echo "Setting up a NEW IDM instance"
echo "============================="
echo ""
echo "-> Loading ${MIDSHIPS_SCRIPTS}/midshipscore.sh"
source "${MIDSHIPS_SCRIPTS}/midshipscore.sh"
echo "-- Done"
echo ""

echo "Checking Environment variables"
echo "------------------------------"
if [ -z "${ENV_TYPE}" ]; then
  echo "-> ENV_TYPE is empty."
  echo "-- Please set environment variable to 'fat', 'fit', 'sit', 'uat', 'nft', etc."
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
    echo "-> VAULT_BASE_URL is empty."
    echo "-- Please set environment variable to the Kubernetes service url for the VAULT solution."
    echo "-- Format is {service-name}.{POD_NAMESPACE}.svc.cluster.local"
    errorFound="true"
  fi

  if [ -z "${VAULT_CLIENT_PATH_IDM}" ]; then
    echo "-> VAULT_CLIENT_PATH_IDM is empty."
    echo "-- Please set environment variable to the path for Client IDM secrets in Secrets Manager solution"
    errorFound="true"
  fi

  if [ -z "${VAULT_CLIENT_PATH_US}" ]; then
    echo "-> VAULT_CLIENT_PATH_US is empty."
    echo "-- Please set environment variable to the path for Client User Store secrets in Secres Manager solution"
    errorFound="true"
  fi

  if [ -z "${VAULT_TOKEN}" ]; then
    echo "-> VAULT_TOKEN is empty."
    echo "-- Please set environment variable to VAULT Token to use to access VAULT solution."
    errorFound="true"
  fi
else
  if [ -z "${IDM_CONFIGMAPS}" ]; then
    echo "-> WARN: IDM_CONFIGMAPS is empty."
    echo "-- Setting to /opt/idm/configmaps"
    export IDM_CONFIGMAPS="/opt/idm/configmaps"
  fi

  if [ -z "${IDM_SECRETS}" ]; then
    echo "-> WARN: IDM_SECRETS is empty."
    echo "-- Setting to /opt/idm/secrets"
    export IDM_CONFIGMAPS="/opt/idm/secrets"
  fi
fi

if [ -z "${DS_HOSTNAME_PRIMARY}" ]; then
  echo "-> ERROR: DS_HOSTNAME_PRIMARY is empty."
  echo "-- Please set environment variable to the HOSTNAME of the Directory Server (DS) hosting the IDM repository."
  errorFound="true"
fi

if [ -z "${DS_HOSTNAME_SECONDARY}" ]; then
  echo "-> WARN: DS_HOSTNAME_SECONDARY is empty."
  echo "-- Please set environment variable to the HOSTNAME of the secondary Directory Server (DS) hosting the IDM repository."
  echo "   No secondary LDAP Server will be setup."
fi

if [[ -z "${IDM_PROFILE}" ]] || [[ "${IDM_PROFILE,,}" != "ds" && "${IDM_PROFILE,,}" != "mysql" && "${IDM_PROFILE,,}" != "oracle" && "${IDM_PROFILE,,}" != "embeded" ]]; then
  echo "-> IDM_PROFILE is empty."
  echo "-- Please set environment variable to the either 'ds', 'mysql', or 'oracle' respectively for the IDM repository to be used."
  errorFound="true"
fi

echo "-- Check complete"
echo ""

if [ "${errorFound}" == "false" ]; then
  echo "Setting up pre-requsite(s)"
  echo "--------------------------"
  mkdir -p "${path_tmpFolder}" "${IDM_PROJECTS}"
  echo "-- Done"
  echo ""

  echo "-> Loading ${MIDSHIPS_SCRIPTS}/midshipscore.sh"
  source "${MIDSHIPS_SCRIPTS}/midshipscore.sh"
  echo "-- Done"
  echo ""

  echo "Getting Secrets and Configuration"
  echo "---------------------------------"
  echo ""
  # Getting Secrets
  getSecretAndConfig dsBindDNpwd "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${IDM_SECRETS}" "dsBindDNpwd" "${VAULT_CLIENT_PATH_IDM}" "${VAULT_TOKEN}"
  getSecretAndConfig truststorePwd "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${IDM_SECRETS}" "truststorePwd" "${VAULT_CLIENT_PATH_IDM}" "${VAULT_TOKEN}"
  getSecretAndConfig keystorePwd "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${IDM_SECRETS}" "keystorePwd" "${VAULT_CLIENT_PATH_IDM}" "${VAULT_TOKEN}"
  getSecretAndConfig us_certificate "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${tmpUSsecretsPath}" "certificate" "${VAULT_CLIENT_PATH_IDM}" "${VAULT_TOKEN}" "true"

  # Getting Configuation
  getSecretAndConfig file_repo_ds_json "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${IDM_CONFIGMAPS}" "repo_ds_json" "${VAULT_CLIENT_PATH_IDM}" "${VAULT_TOKEN}" "true"
  getSecretAndConfig file_startup_sh_bak "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${IDM_CONFIGMAPS}" "startup_sh_bak" "${VAULT_CLIENT_PATH_IDM}" "${VAULT_TOKEN}" "true"
  getSecretAndConfig file_sync_json "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${IDM_CONFIGMAPS}" "sync_json" "${VAULT_CLIENT_PATH_IDM}" "${VAULT_TOKEN}" "true"
  getSecretAndConfig file_managed_json "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${IDM_CONFIGMAPS}" "managed_json" "${VAULT_CLIENT_PATH_IDM}" "${VAULT_TOKEN}" "true"
  getSecretAndConfig file_system_properties "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${IDM_CONFIGMAPS}" "system_properties" "${VAULT_CLIENT_PATH_IDM}" "${VAULT_TOKEN}" "true"
  getSecretAndConfig file_boot_properties "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${IDM_CONFIGMAPS}" "boot_properties" "${VAULT_CLIENT_PATH_IDM}" "${VAULT_TOKEN}" "true"
  getSecretAndConfig file_properties "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${IDM_CONFIGMAPS}" "properties" "${VAULT_CLIENT_PATH_IDM}" "${VAULT_TOKEN}" "true"

  echo "Verifying Secrets and Configuration"
  echo "-----------------------------------"
  echo ""
  if [ -z "${file_repo_ds_json}" ] || [ "${file_repo_ds_json}" == "null" ]; then
    echo "-- ERROR: 'file_repo_ds_json' not found"
    errorFound="true"
  fi
  if [ -z "${file_startup_sh_bak}" ] || [ "${file_startup_sh_bak}" == "null" ]; then
    echo "-- ERROR: 'file_startup_sh_bak' not found"
    errorFound="true"
  fi
  if [ -z "${file_sync_json}" ] || [ "${file_sync_json}" == "null" ]; then
    echo "-- ERROR: 'file_sync_json' not found"
    errorFound="true"
  fi
  if [ -z "${file_managed_json}" ] || [ "${file_managed_json}" == "null" ]; then
    echo "-- ERROR: 'file_managed_json' not found"
    errorFound="true"
  fi
  if [ -z "${file_system_properties}" ] || [ "${file_system_properties}" == "null" ]; then
    echo "-- ERROR: 'file_system_properties' not found"
    errorFound="true"
  fi
  if [ -z "${file_boot_properties}" ] || [ "${file_boot_properties}" == "null" ]; then
    echo "-- ERROR: 'file_boot_properties' not found"
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
  if [ -z "${dsBindDNpwd}" ] || [ "${dsBindDNpwd}" == "null" ]; then
    echo "-> ERROR: dsBindDNpwd is empty."
    echo "-- Please set to the PASSWORD for the BIND-DN provided for the Directory Server (DS) hosting the IDM repository."
    errorFound="true"
  fi
  if [ -z "${truststorePwd}" ] || [ "${truststorePwd}" == "null" ]; then
    echo "-> ERROR: truststorePwd is empty."
    echo "-- Please set to the PASSWORD for the IDM truststore."
    errorFound="true"
  fi
  if [ -z "${keystorePwd}" ] || [ "${keystorePwd}" == "null" ]; then
    echo "-> ERROR: keystorePwd is empty."
    echo "-- Please set to the PASSWORD for the IDM keystore."
    errorFound="true"
  fi
  if [ -z "${us_certificate}" ] || [ "${us_certificate}" == "null" ]; then
    echo "-> ERROR: us_certificate is empty."
    echo "-- Please nsure the User Store Public Certificate is retreived."
    errorFound="true"
  fi
  if [ ! -f "${IDM_KEYSTORE}" ] || [ ! -f "${IDM_TRUSTSTORE}" ]; then
    echo "-> ERROR: Either IDM_KEYSTORE (${IDM_KEYSTORE}) or IDM_TRUSTSTORE (${IDM_TRUSTSTORE}) cannot be found."
    echo "-- These are required to setup the IDM certificates. Exiting ..."
    errorFound="true"
    exit 1
  fi
  echo ""

  if [ "${errorFound}" == "false" ]; then
    echo "[ Adding USer Store Public Cert to IDM Trust Store]"
    importCertIntoTrustStore "user-store" "${us_certificate}" "${IDM_TRUSTSTORE}" "${truststorePwd}"

    case ${IDM_PROFILE} in
      "ds")
        echo "Setting up DS repo file"
        echo "-----------------------"
        echo "-- Loading variable into file"
        echo "${file_repo_ds_json}" | base64 --decode > "${path_repojson}"
        if [ -n "${dsBindDN}" ] && [ -n "${dsPort}" ]; then
          echo "-- Adding DS_HOSTNAME_PRIMARY"
          tmpstr="{\"hostname\":\"${DS_HOSTNAME_PRIMARY}\",\"port\":${dsPort}}"
          sed -i "s/!!PRIMARY_LDAP_SERVERS!!/${tmpstr}/g" "${path_repojson}"
          echo "-- Adding SECONDARY_LDAP_SERVERS"
          if [ -n "${DS_HOSTNAME_SECONDARY}" ]; then
            tmpstr="{\"hostname\":\"${DS_HOSTNAME_SECONDARY}\",\"port\":${dsPort}}"
            sed -i "s/!!SECONDARY_LDAP_SERVERS!!/${tmpstr}/g" "${path_repojson}"
          else
            tmpstr=
            sed -i "s/!!SECONDARY_LDAP_SERVERS!!/${tmpstr}/g" "${path_repojson}"
          fi
          echo "-- Adding DS BIND DN"
          sed -i "s/!!DS_BIND_DN!!/${dsBindDN}/g" "${path_repojson}"
          echo "-- Adding DS BIND DN PWD"
          sed -i "s/!!DS_BIND_PWD!!/${dsBindDNpwd}/g" "${path_repojson}"
        else
          echo "-- ERROR: dsBindDN (${dsBindDN}) and/ dsPort (${dsPort}) is/are empty."
          echo "   This is required. Please correct and retry. Exiting ..."
          exit 1
        fi
        echo "-- Done"
        echo ""
        ;;
      "mysql")
        echo -n "MYSQL repo"
        ;;
      "oracle")
        echo -n "Oracle DB repo"
        ;;
      "embeded")
        echo "-- IDM will be started with an Embedded Directory Services (DS) as repository. Do NOT use for production."
        echo ""
        ;;
      *)
        errorFound="true"
        echo "-- Invalid IDM_PROFILE provided."
        echo ""
        ;;
    esac

    echo "Moving over setup file(s)"
    echo "-------------------------"
    echo "-> system.properties:"
    path_to="${IDM_HOME}/conf/system.properties"
    echo "   From: In memory variable"
    echo "     To: ${path_to}"
    echo "-- Loading variable into file"
    echo "${file_system_properties}" | base64 --decode > "${path_to}"
    echo "-- Done"
    echo ""

    echo "-> boot.properties:"
    path_to="${IDM_HOME}/resolver/boot.properties"
    echo "   From: In memory variable"
    echo "     To: ${path_to}"
    echo "-- Loading variable into file"
    echo "${file_boot_properties}" | base64 --decode > "${path_to}"
    echo "-- Updating placeholders"
    sed -i "s/!!HOSTNAME!!/${HOSTNAME}/g" "${path_to}"
    sed -i "s/!!NODE_ID!!/${HOSTNAME}/g" "${path_to}"
    if [ -n "${httpsPort}" ]; then
      sed -i "s/!!HTTPS_PORT!!/${httpsPort}/g" "${path_to}"
    else
      echo "-- ERROR: httpsPort is required but it is empty."
      echo "   Please resolved and redeploy. Exiting ..."
      exit 1
    fi
    cat "${path_to}"
    echo "-- Done"
    echo ""

    echo "-> startup.sh:"
    path_to="${IDM_HOME}/startup.sh"
    echo "   From: In memory variable"
    echo "     To: ${path_to}"
    echo "-- Loading variable into file"
    echo "${file_startup_sh_bak}" | base64 --decode > "${path_to}"
    echo "-- Done"
    echo ""

    echo "-> sync.json:"
    path_to=${IDM_HOME}/conf/sync.json
    echo "   From: In memory variable"
    echo "     To: ${path_to}"
    echo "-- Loading variable into file"
    echo "${file_sync_json}" | base64 --decode > "${path_to}"
    echo "-- Done"
    echo ""

    echo "-> managed.json:"
    path_to=${IDM_HOME}/conf/managed.json
    echo "   From: In memory variable"
    echo "     To: ${path_to}"
    echo "-- Loading variable into file"
    echo "${file_managed_json}" | base64 --decode > "${path_to}"
    echo "-- Done"
    echo ""

    if ls "${IDM_HOME}/*.json" &> /dev/null; then
      echo "Moving over other configuration file(s)"
      echo "---------------------------------------"
      path_from="${IDM_HOME}/*.json"
      path_to="${IDM_HOME}/conf/"
      echo "-> Copying over below files:"
      echo "   From: ${path_from}"
      echo "   To: ${path_to}"
      ls -ltr "${path_from}"
      mv "${path_from}" "${path_to}"
      echo "-- Done"
      echo ""
    fi
    echo "Process Complete" > "${path_setupcompleted}"
    echo ""
    startIDM
  fi
else
  echo "-- ERROR found. See previous messages for details."
  echo ""
fi
