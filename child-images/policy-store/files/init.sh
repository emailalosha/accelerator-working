#!/bin/bash

# =======================================================
# Script to be executed by ForgeRock Directory Server(DS)
# Kubernetes container on startup to configure itself as
# a ForgeRock Directory Server (Policy Store).

# Created 10/07/2018
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

echo "--------------------------------------------------------"
echo "********************************************************"
echo "[[   ForgeRock Directory Server (DS) - Policy Store ]]"
echo "->           Server Name: ${HOSTNAME}"
echo "->               DS_HOME: ${DS_HOME}"
echo "->                DS_APP: ${DS_APP}"
echo "->              ENV_TYPE: ${ENV_TYPE}"
echo "->        SELF_REPLICATE: ${SELF_REPLICATE}"
echo "->            DS_BASE_DN: ${DS_BASE_DN}"
echo "->           DS_INSTANCE: ${DS_INSTANCE}"
echo "->            DS_SCRIPTS: ${DS_SCRIPTS}"
echo "->            DS_VERSION: ${DS_VERSION}"
echo "->        VAULT_BASE_URL: ${VAULT_BASE_URL}"
echo "->     VAULT_CLIENT_PATH: ${VAULT_CLIENT_PATH}"
echo "->           VAULT_TOKEN: ${VAULT_TOKEN}"
echo "-> USE_CUSTOM_JAVA_PROPS: ${USE_CUSTOM_JAVA_PROPS} "
echo "->         POD_NAMESPACE: ${POD_NAMESPACE}"
echo "->          POD_BASENAME: ${POD_BASENAME}"
echo "->      POD_SERVICE_NAME: ${POD_SERVICE_NAME}"
echo "->             JAVA_HOME: ${JAVA_HOME}"
echo "->          JAVA_CACERTS: ${JAVA_CACERTS}"
echo "->             Server IP: $(hostname --ip-address)"
echo "--------------------------------------------------------"
echo ""

# Local Variables
# ---------------
errorFound="false"
certName="policy-store"

path_tmpFolder="/tmp/ds"
path_keystoreFile="${DS_APP}/keystore.p12"
path_keystorePinFile="${DS_APP}/keystore.pin"
path_rootUserPasswordFile="${path_tmpFolder}/rootUserPassword.txt"
path_monitorUserPasswordFile="${path_tmpFolder}/monitorUserPassword.txt"

rootUserPassword=""
monitorUserPassword=""
amPolicyAdminPassword=""
policyStoreCertPwd=""
truststorePwd=""
properties=""
certificate=""
certificateKey=""

# Note that format for statefulset pod service URL is {hostname}.{service-name}.{POD_NAMESPACE}.svc.cluster.local
svcURL_ps_curr="${HOSTNAME}.${POD_SERVICE_NAME}.${POD_NAMESPACE}.svc.cluster.local"

echo "Setting up pre-requsite(s)"
echo "--------------------------"
mkdir -p ${path_tmpFolder}

echo "-> Loading ${DS_SCRIPTS}/forgerock-ds-shared-functions.sh"
source ${DS_SCRIPTS}/forgerock-ds-shared-functions.sh
echo "-- Done"
echo ""

echo "Checking Environment variables"
echo "------------------------------"
if [ -z "${ENV_TYPE}" ]; then
  echo "-> ENV_TYPE is empty."
  echo "-- Please set environment variable to 'fat', 'fit', 'sit', 'uat', 'nft', etc."
  errorFound=true
fi

if [ -z "${VAULT_BASE_URL}" ]; then
  echo "-> VAULT_BASE_URL is empty."
  echo "-- Please set environment variable to the Kubernetes service url for the VAULT solution."
  echo "-- Format is {service-name}.{POD_NAMESPACE}.svc.cluster.local"
  errorFound=true
fi

if [ -z "${VAULT_CLIENT_PATH}" ]; then
  echo "-> VAULT_CLIENT_PATH is empty."
  echo "-- Please set environment variable to the path for Client secrets in VAULT solution"
  errorFound=true
fi

if [ -z "${VAULT_TOKEN}" ]; then
  echo "-> VAULT_TOKEN is empty."
  echo "-- Please set environment variable to VAULT Token to use to access VAULT solution."
  errorFound=true
fi

if [ -z "${POD_BASENAME}" ]; then
  echo "-> POD_BASENAME is empty."
  echo "-- Please set to the kubernetes statefulset POD name in deployment yaml"
  errorFound=true
fi

if [ -z "${POD_SERVICE_NAME}" ]; then
  echo "-> POD_SERVICE_NAME is empty."
  echo "-- Please set to the name of kubernetes service used to access the POD"
  errorFound=true
fi

if [ -z "${DS_BASE_DN}" ]; then
  echo "-> DS_BASE_DN is empty."
  echo "-- Please set to the required DS_BASE_DN for the Policy Store. E.g. 'ou=am-config'"
  errorFound=true
fi

if [ -z "${SELF_REPLICATE}" ]; then
  echo "-> SELF_REPLICATE is empty."
  echo "-- Setting to 'true' as default. Please set in future to 'true' or 'false'"
  export SELF_REPLICATE="true"
  errorFound=true
fi

if [ -z "${USE_CUSTOM_JAVA_PROPS}" ]; then
  echo "-> USE_CUSTOM_JAVA_PROPS is empty. "
  echo "-- Setting to 'false' as default. Please set in future to 'true' or 'false' "
  export USE_CUSTOM_JAVA_PROPS="false"
  errorFound=true
fi

if [ "${errorFound}" == "false" ]; then
  echo ""

  if [ -f "${DS_INSTANCE}/locks/server.lock" ]; then
    echo "-> Removing ${DS_INSTANCE}/locks/server.lock to potential pod termination"
    echo "-- Done"
    echo ""
  fi

  if [ -d "${DS_INSTANCE}/db" ]; then
    echo "Directory Server (Policy Store) already configured"
    echo "--------------------------------------------------"
    echo "-- ${DS_INSTANCE}/db found. Proceeding to start DS ..."
    echo ""

    echo "-> Starting DS in foreground"
    ${DS_APP}/bin/start-ds --nodetach
    echo ""
  else
    echo "Configuring a NEW Policy Store instance"
    echo "---------------------------------------"
    echo ""
	  prepareServerFolders # Must be executed before running first DS binary command on server

    echo "-> Java Experimental VM Settings"
    java -XX:+UnlockExperimentalVMOptions -XshowSettings:vm -version
    echo ""

    echo "Getting Secrets from VAULT"
    echo "--------------------------"
    getSecretFromVault rootUserPassword "${VAULT_BASE_URL}" "${VAULT_TOKEN}" "${VAULT_CLIENT_PATH}" "rootUserPassword"
    if [ -z "${rootUserPassword}" ]; then
      echo "-- rootUserPassword not found in VAULT"
      errorFound=true
    fi

    getSecretFromVault monitorUserPassword "${VAULT_BASE_URL}" "${VAULT_TOKEN}" "${VAULT_CLIENT_PATH}" "monitorUserPassword"
    if [ -z "${monitorUserPassword}" ]; then
      echo "-- monitorUserPassword not found in VAULT"
      errorFound=true
    fi

    getSecretFromVault amPolicyAdminPassword "${VAULT_BASE_URL}" "${VAULT_TOKEN}" "${VAULT_CLIENT_PATH}" "amPolicyAdminPassword"
    if [ -z "${amPolicyAdminPassword}" ]; then
      echo "-- amPolicyAdminPassword not found in VAULT"
      errorFound=true
    fi

    getSecretFromVault policyStoreCertPwd "${VAULT_BASE_URL}" "${VAULT_TOKEN}" "${VAULT_CLIENT_PATH}" "policyStoreCertPwd"
    if [ -z "${policyStoreCertPwd}" ]; then
      echo "-- policyStoreCertPwd not found in VAULT"
      errorFound=true
    fi

    getSecretFromVault truststorePwd "${VAULT_BASE_URL}" "${VAULT_TOKEN}" "${VAULT_CLIENT_PATH}" "truststorePwd"
    if [ -z "${truststorePwd}" ]; then
      echo "-- truststorePwd not found in VAULT"
      errorFound=true
    fi

    getSecretFromVault properties "${VAULT_BASE_URL}" "${VAULT_TOKEN}" "${VAULT_CLIENT_PATH}" "properties"
    if [ -z "${properties}" ]; then
      echo "-- properties not found in VAULT"
      echo "-- Exiting ..."
      echo ""
      errorFound="true"
    else
      echo "-- Loading properties as variables"
      filename_tmp=${path_tmpFolder}/app.properties
      echo "${properties}" | base64 --decode > ${filename_tmp}
      source ${filename_tmp}
      echo "-- Done"
      echo ""
    fi

    if [ "${errorFound}" == "false" ]; then
      echo "Retrieving certificate(s) from VAULT"
      echo "------------------------------------"
      echo ""
      getSecretFromVault certificate "${VAULT_BASE_URL}" "${VAULT_TOKEN}" "${VAULT_CLIENT_PATH}" "certificate"
      getSecretFromVault certificateKey "${VAULT_BASE_URL}" "${VAULT_TOKEN}" "${VAULT_CLIENT_PATH}" "certificateKey"

      if [ ! -z "${certificate}" ] && [ ! -z "${certificateKey}" ]; then
        setupCertsForDS "${certName}" "${certificate}" "${certificateKey}" "${path_keystoreFile}" "${JAVA_CACERTS}" "${policyStoreCertPwd}" "${truststorePwd}"

        echo "-> Password files setup"
        echo "-- Creating password files"
        echo "${rootUserPassword}" > ${path_rootUserPasswordFile}
        echo "${monitorUserPassword}" > ${path_monitorUserPasswordFile}
        echo "${policyStoreCertPwd}" > ${path_keystorePinFile}
        echo "-- Done"
        echo ""

        echo "Setting up DS as Policy Store"
        echo "-----------------------------"
        ${DS_APP}/setup directory-server \
          --rootUserDN "${rootUserDN}" \
          --rootUserPasswordFile "${path_rootUserPasswordFile}" \
          --monitorUserPasswordFile "${path_monitorUserPasswordFile}" \
          --instancePath "${DS_INSTANCE}" \
          --hostname "${svcURL_ps_curr}" \
          --certNickname "${certName}" \
          --enableStartTLS \
          --usePkcs12keyStore "${path_keystoreFile}" \
          --keyStorePasswordFile "${path_keystorePinFile}" \
          --ldapPort ${ldapPort} \
          --ldapsPort ${ldapsPort} \
          --httpsPort ${httpsPort} \
          --httpPort ${httpPort} \
          --adminConnectorPort ${adminConnectorPort} \
          --profile am-config \
          --set am-config/amConfigAdminPassword:${amPolicyAdminPassword} \
          --set am-config/baseDn:${DS_BASE_DN} \
          --set am-config/backendName:policyStore \
          --productionMode \
          --doNotStart \
          --acceptLicense
        echo "-- Configuration process complete"
        echo ""

        echo "Starting Policy Store"
        echo "---------------------"
        echo "-- Server starting ..."
        nohup ${DS_APP}/bin/start-ds > ${path_tmpFolder}/serverstart.log 2>&1 </dev/null &
        echo "-- Waiting 10secs"
        sleep 10
        cat ${path_tmpFolder}/serverstart.log
        echo "-- Done"
        echo ""

        # Allowing DS access to the required truststore
        allowTruststoreAccessByDS "${svcURL_ps_curr}" ${adminConnectorPort} "${rootUserDN}" "${path_rootUserPasswordFile}" "${JAVA_CACERTS}" "${truststorePwd}"
        setDSHandlerStatus  "${svcURL_ps_curr}" ${adminConnectorPort} "${rootUserDN}" "${path_rootUserPasswordFile}" "LDAP" "false"
        setDSHandlerStatus  "${svcURL_ps_curr}" ${adminConnectorPort} "${rootUserDN}" "${path_rootUserPasswordFile}" "HTTP" "false"
        # Setting up Custom java.properties
        setupCustomJavaProperties  "${USE_CUSTOM_JAVA_PROPS}" "java.properties"
        # Setting up Self Replication
        setupSelfReplication

        echo "-- Stopping server ..."
        ${DS_APP}/bin/stop-ds
        echo ""

        echo "cleaning up"
        echo "-----------"
        rm -rf ${path_tmpFolder}/*
        echo "-- Done"
        echo ""

        echo "Starting DS in foreground"
        echo "-------------------------"
        ${DS_APP}/bin/start-ds --nodetach
      else
        echo "-- No certificate retrieved from Vault."
      fi
    fi
  fi
fi
