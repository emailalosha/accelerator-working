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

echo "----------------------------------------------------------------"
echo "****************************************************************"
echo "[[                   ForgeRock Access Manager                 ]]"
echo "->                  Server Name: ${HOSTNAME}                    "
echo "->                     ENV_TYPE: ${ENV_TYPE}                    "
echo "->                      AM Home: ${AM_HOME}                     "
echo "->                   AM_SECRETS: ${AM_SECRETS}                  "
echo "->                AM_CONFIGMAPS: ${AM_CONFIGMAPS}               "
echo "->                 AM_LB_DOMAIN: ${AM_LB_DOMAIN}                "
echo "->                       AM URI: ${AM_URI}                      "
echo "->                POD_NAMESPACE: ${POD_NAMESPACE}               "
echo "->               VAULT_BASE_URL: ${VAULT_BASE_URL}              "
echo "->         VAULT_CLIENT_PATH_AM: ${VAULT_CLIENT_PATH_AM}        "
echo "->         VAULT_CLIENT_PATH_CS: ${VAULT_CLIENT_PATH_CS}        "
echo "->         VAULT_CLIENT_PATH_US: ${VAULT_CLIENT_PATH_US}        "
echo "->         VAULT_CLIENT_PATH_TS: ${VAULT_CLIENT_PATH_TS}        "
echo "->                  VAULT_TOKEN: ${VAULT_TOKEN}                 "
echo "-.               CS_K8s_SVC_URL: ${CS_K8s_SVC_URL}              "
echo "->               US_K8s_SVC_URL: ${US_K8s_SVC_URL}              "
echo "->               TS_K8s_SVC_URL: ${TS_K8s_SVC_URL}              "
echo "->                  COOKIE_NAME: ${COOKIE_NAME}                 "
echo "->       US_CONNSTRING_AFFINITY: ${US_CONNSTRING_AFFINITY}      "
echo "->       TS_CONNSTRING_AFFINITY: ${TS_CONNSTRING_AFFINITY}      "
echo "->                  TOMCAT_HOME: ${TOMCAT_HOME}                 "
echo "->                    GOTO_URLS: ${GOTO_URLS}                   "
echo "->                    JAVA_HOME: ${JAVA_HOME}                   "
echo "->                 JAVA_CACERTS: ${JAVA_CACERTS}                "
echo "->                 SECRETS_MODE: ${SECRETS_MODE}                "
echo "->              CS_SIDECAR_MODE: ${CS_SIDECAR_MODE}             "
echo "->                 AMSTER_FILES: ${AMSTER_FILES}                "
echo "->                   AUTH_TREES: ${AUTH_TREES}                  "
echo "->UPDATE_ALL_AUTHENTICATED_USERS_REALMS: ${UPDATE_ALL_AUTHENTICATED_USERS_REALMS}"
echo "->                    Server IP: $(hostname --ip-address)       "
echo "----------------------------------------------------------------"
echo ""

# Local Variables
# ---------------
errorFound=false
sharedFolder="/opt/shared"
path_sharedFile_am="${sharedFolder}/am_done"
path_sharedFile_cs="${sharedFolder}/cs_done"
path_amsterHome=${AM_HOME}/tools/amster
path_cfgDir=${AM_HOME}/config
path_amSecurityDir=${path_cfgDir}/security
path_amsterSecurityDir=${path_amSecurityDir}/keys/amster
path_RSAkey_AMgenerated=${path_amsterSecurityDir}/amster_rsa
path_tomcatJksFile="${TOMCAT_HOME}/tomcat.jks"
path_amPlugins="${TOMCAT_HOME}/webapps/${AM_URI}/WEB-INF/lib/"
path_tmpAMHome=/opt/temp-am
path_tmpTomcatHome=/opt/temp-tomcat
path_tmpFolder=/tmp/am
path_tmp_amsterConfigScript="${path_tmpFolder}/configureAM.amster"
path_tmp_authTreesJson="${path_tmpFolder}/amtree.json"
path_amTreeTool=${AM_HOME}/tools/amtree.sh
path_tmp_file=""
lbPrimaryUrl="https://${AM_LB_DOMAIN}/${AM_URI}"
tomcatJKSPwd=""
amAdminPwd=""
cfgStoreDirMgrPwd=""
userStoreDirMgrPwd=""
truststorePwd=""
amPwdEncKey=""
file_properties=""
certificate=""
certificateKey=""
filename_tmp=""
amster_temp=""
script_temp=""
serverUrl=""
amAlreadyConfigured=false
tmpUSsecretsPath="/opt/us/secrets"
tmpTSsecretsPath="/opt/ts/secrets"
tmpCSsecretsPath="/opt/cs/secrets"

echo "Setting up pre-requsite(s)"
echo "--------------------------"
ls -ltr /tmp
mkdir -p ${path_tmpFolder}
rm -rf "${sharedFolder:?}/*"
ls -ltr /tmp

echo ""
echo "-- Setup AM_HOME .."
echo "-----------------------------------------------------------------"
echo ""

#The original AM files were located in the read-only file system, hence we need to migrated all the AM files into a location that has read write access
echo "-- Copying AM file from ${path_tmpAMHome} to ${AM_HOME} .."
cp -R "${path_tmpAMHome}"/* "${AM_HOME}"/
echo "-- Checking ${AM_HOME} by ls -ltr"
ls -ltr "${AM_HOME}"
echo "-- Done .."

echo "-> Loading ${AM_HOME}/scripts/forgerock-am-shared-functions.sh"
source "${AM_HOME}/scripts/forgerock-am-shared-functions.sh"
echo "-- Done"
echo ""

echo "Checking Environment variables"
echo "------------------------------"
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
    echo "-- Please set environment variable to the Kubernetes service url for the VAULT solution."
    echo "-- Format is {service-name}.{POD_NAMESPACE}.svc.cluster.local"
    echo ""
    errorFound="true"
  fi

  if [ -z "${VAULT_CLIENT_PATH_AM}" ]; then
    echo "-> ERROR: VAULT_CLIENT_PATH_AM is empty."
    echo "-- Please set environment variable to the path for Client Access Manager secrets solution"
    echo ""
    errorFound="true"
  fi

  if [ -z "${VAULT_CLIENT_PATH_CS}" ]; then
    echo "-> ERROR: VAULT_CLIENT_PATH_CS is empty."
    echo "-- Please set environment variable to the path for Client Config Store secrets solution"
    echo ""
    errorFound="true"
  fi

  if [ -z "${VAULT_CLIENT_PATH_US}" ]; then
    echo "-> ERROR: VAULT_CLIENT_PATH_US is empty."
    echo "-- Please set environment variable to the path for Client User Store secrets solution"
    echo ""
    errorFound="true"
  fi

  if [ -z "${VAULT_CLIENT_PATH_TS}" ]; then
    echo "-> ERROR: VAULT_CLIENT_PATH_TS is empty."
    echo "-- Please set environment variable to the path for Client Token Store secrets solution"
    echo ""
    errorFound="true"
  fi

  if [ -z "${VAULT_TOKEN}" ]; then
    echo "-> ERROR: VAULT_TOKEN is empty."
    echo "-- Please set environment variable to VAULT Token to use to access VAULT solution."
    echo ""
    errorFound="true"
  fi
fi

if [ -z "${AM_LB_DOMAIN}" ]; then
  echo "-- WARN: AM_LB_DOMAIN is empty. Setting to localhost."
  echo ""
  export AM_LB_DOMAIN=localhost
fi

if [ -z "${POD_NAMESPACE}" ]; then
  echo "-> ERROR: POD_NAMESPACE is empty."
  echo "-- Please set to the namespace the Forgerock Access Manager pod will be running under in K8s cluster."
  echo ""
  errorFound="true"
fi

if [ -z "${CS_SIDECAR_MODE}" ] || [ "${CS_SIDECAR_MODE,,}" != "true" ] && [ "${CS_SIDECAR_MODE,,}" != "false" ]; then
  echo "-> WARN: CS_SIDECAR_MODE is empty or not set to 'true' or 'false'."
  echo "-- Setting to 'true' as default. Please set in future to 'true' when running the Config Store (CS) as a sidecar with the Access Manager. Or 'false' when when running the Config Store (CS) as an external Directory Server."
  export CS_SIDECAR_MODE="true"
fi

if [ "${CS_SIDECAR_MODE,,}" == "true" ]; then
  echo "-- Updating CS_K8s_SVC_URL to 'localhost' as Access Manager (AM) and Config Store (CS) are in the same Pod."
  export CS_K8s_SVC_URL="localhost"
fi

if [ -z "${CS_K8s_SVC_URL}" ]; then
  echo "-- ERROR: CS_K8s_SVC_URL is empty. Please set to the Forgerock Config Store K8s service url. For instance, 'forgerock-config-store.default.svc.cluster.local'"
  echo ""
  errorFound="true"
fi

if [ -z "${US_K8s_SVC_URL}" ]; then
  echo "-- ERROR: US_K8s_SVC_URL is empty. Please set to the Forgerock User Store K8s service url. For instance, 'forgerock-user-store.default.svc.cluster.local'"
  echo ""
  errorFound="true"
fi

if [ -z "${TS_K8s_SVC_URL}" ]; then
  echo "-- ERROR: TS_K8s_SVC_URL is empty. Please set to the Forgerock Token Store K8s service url. For instance, 'forgerock-token-store.default.svc.cluster.local'"
  echo ""
  errorFound="true"
fi

if [ -z "${ENV_TYPE}" ]; then
  echo "-> ERROR: ENV_TYPE is empty."
  echo "-- Please set environment variable to 'fat', 'fit', 'sit', 'uat', 'nft', etc."
  echo ""
  errorFound="true"
fi

if [ -z "${US_CONNSTRING_AFFINITY}" ]; then
  echo "-- ERROR: US_CONNSTRING_AFFINITY is empty. Please set to a comma separated string of the k8s User Store pods svc URL."
  echo '-- For instance "forgerock-user-store-0.forgerock-user-store.forgerock.svc.cluster.local:1636,forgerock-user-store-1.forgerock-user-store.forgerock.svc.cluster.local:1636"'
  echo "-- The format is <pod-name>.<pod-service-name>.<namespace>.svc.cluster.local"
  echo ""
  errorFound="true"
fi

if [ -z "${TS_CONNSTRING_AFFINITY}" ]; then
  echo "-- ERROR: TS_CONNSTRING_AFFINITY is empty. Please set to a comma separated string of the k8s Token Store pods svc URL."
  echo '-- For instance "forgerock-token-store-0.forgerock-token-store.forgerock.svc.cluster.local:1636,forgerock-token-store-1.forgerock-token-store.forgerock.svc.cluster.local:1636"'
  echo "-- The format is <pod1-name>.<pod-service-name>.<namespace>.svc.<cluster-domain>:<ldaps-port>,<pod2-name>.<pod-service-name>.<namespace>.svc.<cluster-domain>:<ldaps-port>"
  echo ""
  errorFound="true"
fi

if [ -z "${COOKIE_NAME}" ]; then
  echo "-- ERROR: COOKIE_NAME is empty. Please set to the required name for the Cookie."
  echo ""
  errorFound="true"
fi

if [ -z "${SECRETS_MODE}" ] || [ "${SECRETS_MODE,,}" != "k8s" ] && [ "${SECRETS_MODE^^}" != "REST" ]; then
  echo "-> SECRETS_MODE is empty or invalid."
  echo "-- Setting to 'k8s' as default. Please set in future to 'k8s' or 'REST'"
  echo "   Former where secrets and config are stored in K8s, later in a REST secrets manager."
  echo ""
  export SECRETS_MODE="k8s"
fi
echo "-- Done"
echo ""

if [ "${errorFound}" == "false" ]; then
  echo "Getting Secrets and Configuration over REST"
  echo "-------------------------------------------"
  echo ""
  # Getting Secrets
  getSecretAndConfig tomcatJKSPwd "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${AM_SECRETS}" "tomcatJKSPwd" "${VAULT_CLIENT_PATH_AM}" "${VAULT_TOKEN}"
  getSecretAndConfig amAdminPwd "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${AM_SECRETS}" "amAdminPwd" "${VAULT_CLIENT_PATH_AM}" "${VAULT_TOKEN}"
  getSecretAndConfig cfgStoreDirMgrPwd "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${AM_SECRETS}" "cfgStoreDirMgrPwd" "${VAULT_CLIENT_PATH_AM}" "${VAULT_TOKEN}"
  getSecretAndConfig userStoreDirMgrPwd "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${AM_SECRETS}" "userStoreDirMgrPwd" "${VAULT_CLIENT_PATH_AM}" "${VAULT_TOKEN}"
  getSecretAndConfig ctsDirMgrPwd "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${AM_SECRETS}" "ctsDirMgrPwd" "${VAULT_CLIENT_PATH_AM}" "${VAULT_TOKEN}"
  getSecretAndConfig truststorePwd "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${AM_SECRETS}" "truststorePwd" "${VAULT_CLIENT_PATH_AM}" "${VAULT_TOKEN}"
  getSecretAndConfig amPwdEncKey "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${AM_SECRETS}" "encKey_AmPwd" "${VAULT_CLIENT_PATH_AM}" "${VAULT_TOKEN}"
  # Getting Configuation
  getSecretAndConfig file_properties "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${AM_CONFIGMAPS}" "properties" "${VAULT_CLIENT_PATH_AM}" "${VAULT_TOKEN}" "true"

  echo "Verifying Secrets and Configuration"
  echo "-----------------------------------"
  echo ""
  if [ -z "${tomcatJKSPwd}" ] || [ "${tomcatJKSPwd}" == "null" ]; then
    echo "-- ERROR: 'tomcatJKSPwd' not found"
    errorFound="true"
  fi
  if [ -z "${amAdminPwd}" ] || [ "${amAdminPwd}" == "null" ]; then
    echo "-- ERROR: 'amAdminPwd' not found"
    errorFound="true"
  fi
  if [ -z "${cfgStoreDirMgrPwd}" ] || [ "${cfgStoreDirMgrPwd}" == "null" ]; then
    echo "-- ERROR: 'cfgStoreDirMgrPwd' not found"
    errorFound="true"
  fi
  if [ -z "${userStoreDirMgrPwd}" ] || [ "${userStoreDirMgrPwd}" == "null" ]; then
    echo "-- ERROR: 'userStoreDirMgrPwd' not found"
    errorFound="true"
  fi
  if [ -z "${ctsDirMgrPwd}" ] || [ "${ctsDirMgrPwd}" == "null" ]; then
    echo "-- ERROR: 'ctsDirMgrPwd' not found"
    errorFound="true"
  fi
  if [ -z "${truststorePwd}" ] || [ "${truststorePwd}" == "null" ]; then
    echo "-- ERROR: 'truststorePwd' not found"
    errorFound="true"
  fi
  if [ -z "${amPwdEncKey}" ] || [ "${amPwdEncKey}" == "null" ]; then
    echo "-- ERROR: 'amPwdEncKey' not found"
    errorFound="true"
  fi
  if [ -z "${file_properties}" ] || [ "${file_properties}" == "null" ]; then
    echo "-- ERROR: 'properties' not found"
    echo ""
    errorFound="true"
  else
    echo "-- Loading properties as variables"
    filename_tmp=${path_tmpFolder}/app.properties
    echo "${file_properties}" | base64 --decode > ${filename_tmp}
    source "${filename_tmp}"
    echo "-- Done"
  fi
  echo ""

  if [ "${errorFound}" == "false" ]; then
    serverUrl="https://${AM_LB_DOMAIN}:${amHttpsPort}/${AM_URI}" # Must be set after loading propertioes file due to variables in properties file

    echo "-- Checking JAVA_CACERTS by: ls -ltr $JAVA_CACERTS"
    ls -ltr $JAVA_CACERTS
    echo "-- Copying the JAVA_CACERTS from ${AM_HOME}/cacerts to ${JAVA_CACERTS} .."
    cp "${AM_HOME}/cacerts" "${JAVA_CACERTS}"
    chmod 644 $JAVA_CACERTS
    echo "-- Checking JAVA_CACERTS by: ls -ltr $JAVA_CACERTS"
    ls -ltr $JAVA_CACERTS
    echo "-- Done .."

    echo ""
    echo "Setup TOMCAT_HOME"
    echo "-----------------------------------------------------------------"
    echo ""

    #The original tomcat files were located in the read-only file system, hence we need to migrated all the tomcat files into a location that has read write access
    echo "-- Copying TOMCAT files from ${path_tmpTomcatHome} to ${TOMCAT_HOME} .."
    mkdir -p "${TOMCAT_HOME}"
    cp -R "${path_tmpTomcatHome}"/* "${TOMCAT_HOME}"/
    echo "-- Checking ${TOMCAT_HOME} by ls -ltr"
    ls -ltr "${TOMCAT_HOME}"
    echo "-- Done .."

    echo ""
    echo "Retrieving certificates (user-store, token-store, tomcat) details"
    echo "-----------------------------------------------------------------"
    echo ""
    changeTrustStorePassword "${JAVA_CACERTS}" "changeit" "${truststorePwd}"
    if [ "${CS_SIDECAR_MODE,,}" == "true" ]; then
      arrStrCertsPaths_REST=( "${VAULT_CLIENT_PATH_AM}!tomcat" "${VAULT_CLIENT_PATH_US}!user-store" "${VAULT_CLIENT_PATH_TS}!token-store" )
      arrStrCertsPaths_k8s=( "${AM_SECRETS}!tomcat" "${tmpUSsecretsPath}!user-store" "${tmpTSsecretsPath}!token-store" )
    else
      arrStrCertsPaths_REST=( "${VAULT_CLIENT_PATH_AM}!tomcat" "${VAULT_CLIENT_PATH_US}!user-store" "${VAULT_CLIENT_PATH_TS}!token-store" "${VAULT_CLIENT_PATH_CS}!config-store" )
      arrStrCertsPaths_k8s=( "${AM_SECRETS}!tomcat" "${tmpUSsecretsPath}!user-store" "${tmpTSsecretsPath}!token-store" "${tmpCSsecretsPath}!config-store" )
    fi
    tmpK8sSecretsPathIndx=0
    for certPath in "${arrStrCertsPaths_REST[@]}"
    do
      tmpURL=""
      tmpPath=""
      echo "   ****************"
      echo "=> Request Details:"
      if [ "${SECRETS_MODE^^}" == "REST" ]; then
        IFS=' !' read -ra pathDetails <<< "${certPath}"
        tmpURL=${pathDetails[0]}
        alias=${pathDetails[1]}
        echo " > ${VAULT_BASE_URL}"
        echo " > ${urlOrPath} : ${alias}"
      elif [ "${SECRETS_MODE,,}" == "k8s" ]; then
        currK8scretsPathAndAlias=${arrStrCertsPaths_k8s[${tmpK8sSecretsPathIndx}]}
        IFS=' !' read -ra pathDetails <<< "${currK8scretsPathAndAlias}"
        tmpPath=${pathDetails[0]}
        alias=${pathDetails[1]}
        echo " > ${tmpPath}"
        echo " > ${alias}"
      fi
      echo ""
      getSecretAndConfig certificate "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${tmpPath}" "certificate" "${tmpURL}" "${VAULT_TOKEN}" "true"
      getSecretAndConfig certificateKey "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${tmpPath}" "certificateKey" "${tmpURL}" "${VAULT_TOKEN}" "true"
      if [ -z "${certificate}" ] || [ -z "${certificateKey}" ] || [ "${certificate}" == "null" ] || [ "${certificateKey}" == "null" ]; then
        echo "-- ERROR: Could not retrieve Cert and/or Key"
        errorFound="true"
        exit
      else
        importCertIntoTrustStore "${alias}" "${certificate}" "${JAVA_CACERTS}" "${truststorePwd}"
        if [[ ( "${tmpURL}" == "${VAULT_CLIENT_PATH_AM}" && "${tmpURL}" != "" ) || ( "${tmpPath}" == "${AM_SECRETS}" && "${tmpPath}" != "" ) ]]; then
          createPKCS12fromCerts "${alias}" "${certificate}" "${certificateKey}" "${path_tomcatJksFile}" "${tomcatJKSPwd}" "JKS"
        fi
        echo "-- Done"
        echo ""
      fi
      tmpK8sSecretsPathIndx=$((tmpK8sSecretsPathIndx + 1))
    done

    if [ "${errorFound}" == "false" ]; then
      echo "Setting up Tomcat server.xml"
      echo "----------------------------"
      echo "-- Moving Tomcat server.xml template to ${TOMCAT_HOME}/conf"
      mv ${AM_HOME}/server.xml ${TOMCAT_HOME}/conf/server.xml
      echo "-- Updating ${TOMCAT_HOME}/conf/server.xml with keystore information"
      sed -i "s+%TOMCAT_JKS%+${path_tomcatJksFile}+g" ${TOMCAT_HOME}/conf/server.xml
      sed -i "s+%TOMCAT_JKS_PWD%+${tomcatJKSPwd}+g" ${TOMCAT_HOME}/conf/server.xml
      echo "-- Done"
      echo ""

      echo "Starting configuration of new AM instance"
      echo "-----------------------------------------"
      echo ""

      echo "-> Setting Tomcat heap and perm settings"
      echo  export JAVA_OPTS=\"-Xms128m -Xmx2048m -Dfile.encoding=UTF-8 -Dcom.sun.identity.idm.cache.enabled=false -Dcom.iplanet.am.sdk.caching.enabled=false -Dcom.sun.identity.sm.cache.enabled=true \" \
            > ${TOMCAT_HOME}/bin/setenv.sh
      echo "-- Done"
      echo ""

      manageTomcat "start-debug" "${amHttpsPort}" "${AM_URI}"

      echo "-> Java Experimental VM Settings"
      java -XX:+UseContainerSupport -XshowSettings:vm -version
      echo ""

      if [ "${errorFound}" == "false" ]; then
        echo "Installing Access Manager"
        echo "-------------------------"
        echo ""

        echo "[ Checking that the Forgerock User and Token Stores are all up and running ]"
        echo ""
        checkServerIsAlive --svc "${US_K8s_SVC_URL}" --type "ds" --channel "https" --port "${userStoreHttpsPort}"
        checkServerIsAlive --svc "${TS_K8s_SVC_URL}" --type "ds" --channel "https" --port "${ctsHttpsPort}"

        echo "[ Checking that AM is ready for configuration ]"
        echo ""
        checkURLisAlive errorFound "${serverUrl}" "302"

        if [ "${errorFound}" != "true" ]; then
          echo "[ Waiting for Config Store to confirm readiness for AM installation ]"
          if [ "${CS_SIDECAR_MODE,,}" == "true" ]; then
          ls -ltr ${sharedFolder}
            checkIfFileExists "${path_sharedFile_cs}" 60
            removeSharedFile ${path_sharedFile_cs}
            cfgStorePort=${cfgStoreLdapPort}
            if [ "${cfgStoreSsl^^}" == "SSL" ]; then
              cfgStoreSsl="SIMPLE"
            fi
          else
            checkServerIsAlive --svc "${CS_K8s_SVC_URL}" --type "ds" --channel "https" --port "${cfgStoreHttpsPort}"
            cfgStorePort=${cfgStoreLdapsPort}
            if [ "${cfgStoreSsl^^}" == "SIMPLE" ]; then
              cfgStoreSsl="SSL"
            fi
          fi
          echo install-openam \
            --serverUrl "${serverUrl}" \
            --lbPrimaryUrl "${lbPrimaryUrl}" \
            --lbSiteName "${lbSiteName}" \
            --cookieDomain "${AM_LB_DOMAIN}" \
            --pwdEncKey "${amPwdEncKey}" \
            --adminPwd "${amAdminPwd}" \
            --cfgDir "${path_cfgDir}" \
            --cfgStore "${cfgStore}" \
            --cfgStoreDirMgr "${cfgStoreDirMgr}" \
            --cfgStoreDirMgrPwd "${cfgStoreDirMgrPwd}" \
            --cfgStoreHost "${CS_K8s_SVC_URL}" \
            --cfgStoreAdminPort ${cfgStoreAdminPort} \
            --cfgStorePort ${cfgStorePort} \
            --cfgStoreRootSuffix "${cfgStoreRootSuffix}" \
            --cfgStoreSsl "${cfgStoreSsl}" \
            --userStoreRootSuffix "${userStoreRootSuffix}" \
            --userStoreDirMgr "${userStoreDirMgr}" \
            --userStoreDirMgrPwd  "${userStoreDirMgrPwd}" \
            --userStoreHost "${US_K8s_SVC_URL}" \
            --userStoreAdminPort "${userStoreAdminPort}" \
            --userStorePort ${userStorePort} \
            --userStoreType "${userStoreType}" \
            --userStoreSsl "${userStoreSsl}" \
            --acceptLicense \
            :exit > ${path_tmp_amsterConfigScript}
        else
          echo "- Error found. Check log above. Exiting ..."
          echo ""
        fi
      fi

      if [ -f ${path_tmp_amsterConfigScript} ]; then
        echo "-- Installation script (${path_tmp_amsterConfigScript}) created."
        echo ""

        echo "-> Executing Amster installation script"
        ${path_amsterHome}/amster ${path_tmp_amsterConfigScript}
        echo "-- Script execution completed"
        echo ""

        echo "-> Checking if Access Manager was successfully Installed"
        if [ ! -d "${path_cfgDir}" ]; then
          echo "-- ERROR: Access Manager was NOT installed."
          echo "-- Printing out ${path_cfgDir}/var/install.log"
          cat ${path_cfgDir}/var/install.log
          echo "          See above log for more details"
          exit 1
        else
          echo "-- Access Manager(AM) installed SUCCESSFULLY."
          echo ""

          if [ "$(ls -A ${AM_HOME} | grep -i \\.jar\$)" ]; then
            echo "-> Installing AM plugins"
            echo "-- Copying to ${path_amPlugins}"
            mv -f ${AM_HOME}/*.jar ${path_amPlugins}
            echo "-- Done"
            echo ""
          fi

          echo "Creating Access Manager(AM) Keystore and Secrets"
          echo "------------------------------------------------"
          echo ""
          # NOTE: This needs to be done right after AM is first installed before any configuration
          createAMkeystoreAndSecrets "${serverUrl}" "${amAdminPwd}" "${tomcatJKSPwd}" "${amHttpsPort}"

          echo "Applying Access Manager(AM) default hardening"
          echo "---------------------------------------------"
          echo ""
          applyAMDefaultHardening "${serverUrl}" "${amAdminPwd}" \
            "${TS_CONNSTRING_AFFINITY}" "${ctsRootSuffix}" "${ctsDirMgr}" "${ctsDirMgrPwd}" \
            "${userStoreRootSuffix}" "${userStoreDirMgr}" "${userStoreDirMgrPwd}" "${US_CONNSTRING_AFFINITY}" \
            "${AM_LB_DOMAIN}"

          echo "Checking if Access Manager(AM) is already configured by Customer"
          echo "----------------------------------------------------------------"
          echo ""
          getNumberOfRealms totalRealms "${COOKIE_NAME}" "${serverUrl}" "${amAdminPwd}"
          if (( totalRealms > 1 )); then
            amAlreadyConfigured="true"
            echo "-- AM is already configured."
            echo "-- Skipping all Customer bespoke confgurations."
          else
            echo "-- AM NOT configured by customer."
            echo "-- Preparing to apply all Customer bespoke confgurations."
          fi
          echo "-- Done"
          echo ""

          if [ "${amAlreadyConfigured}" == "false" ] && [ "${errorFound}" == "false" ]; then
            # Applying custom Amster scripts
            arr_amsterFilenames=($(echo "${AMSTER_FILES}" | tr ',' '\n'))
            tmp_ArrLen=${#arr_amsterFilenames[@]}
            if (( tmp_ArrLen > 0 )); then
              echo "Applying custom Amster scripts"
              echo "------------------------------"
              echo ""
              echo "** [ STEP 01/02 Creating Amster script to execute ] **"
              echo ""
              echo "connect --private-key ${path_RSAkey_AMgenerated} ${serverUrl}" > ${path_tmp_amsterConfigScript}

              for amsterFilename in ${arr_amsterFilenames[@]}; do
                case $amsterFilename in
                  "amster_ValidationServiceURL")
                    echo "-> Validation Service URL(s) (file: ${amsterFilename})"
                    echo "-- Getting template from vault"
                    getSecretAndConfig amster_valserurl "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${AM_CONFIGMAPS}" "${amsterFilename}" "${VAULT_CLIENT_PATH_AM}" "${VAULT_TOKEN}" "true"
                    if [ -z "${amster_valserurl}" ] || [ "${amster_valserurl}" == "null" ]; then
                      echo "-- ERROR: Could NOT retrieve ${amsterFilename} from Vault"
                      echo "-- Done"
                      echo ""
                      errorFound="true"
                    else
                      echo "-- Decoding Base64 string"
                      amster_valserurl=$(echo "${amster_valserurl}" | base64 --decode)
                      path_tmp_file=${path_tmpFolder}/${amsterFilename}.amster
                      echo "${amster_valserurl}" > "${path_tmp_file}"
                      echo "-- Adding Validation URL(s) to be whitelisted"
                      if [ -z "${GOTO_URLS}" ] || [ "${GOTO_URLS}" == "null" ]; then
                        GOTO_URLS="https://"+${AM_LB_DOMAIN}+"/*"
                        echo "-- GOTO_URLS was blank. now set to ${GOTO_URLS}"
                      fi
                      sed -i "s !!GOTOURLS!! ${GOTO_URLS} g" "${path_tmp_file}"
                      echo "-- Adding to amster script"
                      cat "${path_tmp_file}" >> "${path_tmp_amsterConfigScript}"
                      echo "-- Done"
                      echo ""
                    fi
                  ;;
                  *)
                    echo "-> Processing file: ${amsterFilename}"
                    echo "-- Getting template from vault"
                    getSecretAndConfig amster_temp "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${AM_CONFIGMAPS}" "${amsterFilename}" "${VAULT_CLIENT_PATH_AM}" "${VAULT_TOKEN}" "true"
                    if [ -z "${amster_temp}" ] || [ "${amster_temp}" == "null" ]; then
                      echo "-- ERROR: Could NOT retrieve ${amsterFilename} from Vault"
                      echo "-- Done"
                      echo ""
                      errorFound="true"
                    else
                      echo "-- Decoding Base64 string"
                      amster_temp=$(echo "${amster_temp}" | base64 --decode)
                      echo "-- Adding to amster script"
                      echo "${amster_temp}" >> "${path_tmp_amsterConfigScript}"
                      echo "-- Done"
                      echo ""
                    fi
                  ;;
                esac
              done
              echo :exit >> ${path_tmp_amsterConfigScript}
              echo "-- ${path_tmp_amsterConfigScript} created."
              echo ""

              if [ "${errorFound}" == "false" ]; then
                echo "** [ STEP 02/02 Executing created Amster script ] **"
                echo ""
                # Required to make sure AM is alive before connecting via Amster
                checkServerIsAlive --svc "${AM_LB_DOMAIN}" --type "am" --channel "https" --port "${amHttpsPort}"
                echo "-- Running the Amster script ..."
                ${path_amsterHome}/amster ${path_tmp_amsterConfigScript}
                echo ""
                echo "-- Removing the executed Amster script ..."
                rm ${path_tmp_amsterConfigScript}
                echo "- Custom Amster script processing COMPLETED!"
                echo ""
              else
                echo "-- ERROR: An error occurred during the creationg of the custom Amster scripts"
                echo "--        Check logs above to confirm and resolve. Exiting ..."
                exit 1
              fi
            else
              echo "-- There are no Amster files/Scripts provided by Customer for execution"
              echo "-- Moving on as there is nothing to do here"
              echo "-- Done"
              echo ""
            fi

            # Loading Authentication Trees
            arr_authTrees=($(echo "${AUTH_TREES}" | tr ',' '\n'))
            arr_authTrees_len=${#arr_authTrees[@]}

            if [ "${arr_authTrees_len}" -gt "0" ]; then
              echo "Loading Authentication Trees"
              echo "----------------------------"
              arr_authTreeDetails=
              authTreeName=
              authTreeRealm=
              for tmp_authTreeDetails in ${arr_authTrees[@]}; do
                IFS=' _' read -ra arr_authTreeDetails <<< "${tmp_authTreeDetails}"
                arr_authTreeDetails_len=${#arr_authTreeDetails[@]}
                if [ "${arr_authTreeDetails_len}" -gt "1" ]; then
                  authTreeRealm="/${arr_authTreeDetails[0]}"
                  authTreeName=${arr_authTreeDetails[1]}
                elif [ "${arr_authTreeDetails_len}" -eq "1" ]; then
                  authTreeName=${arr_authTreeDetails[0]}
                  authTreeRealm="/"
                fi
                echo "-> Processing tree: ${authTreeName}"
                echo "   For Realm: ${authTreeRealm}"
                echo ""
                if [ -n "${authTreeName}" ] && [ -n "${authTreeRealm}" ]; then
                  tmp_authTree=
                  getSecretAndConfig tmp_authTree "${SECRETS_MODE}" "${VAULT_BASE_URL}" "${AM_CONFIGMAPS}" "${tmp_authTreeDetails}" "${VAULT_CLIENT_PATH_AM}" "${VAULT_TOKEN}" "true"
                  if [ -z "${tmp_authTree}" ] || [ "${tmp_authTree}" == "null" ]; then
                    echo "-- ERROR: Could NOT retrieve ${tmp_authTreeDetails}"
                    errorFound="true"
                  else
                    echo "-- Decoding Base64 Auth Tree"
                    echo "${tmp_authTree}" | base64 --decode > ${path_tmp_authTreesJson}
                    tmp_treeName=$(jq -r .tree._id ${path_tmp_authTreesJson})
                    echo "-- Importing tree: ${tmp_treeName} ..."
                    echo "-- am tree tool path: ${path_amTreeTool} ..."
                    # Passing default cookie name as custom cookie name requires restart and will only be active after that is done.
                    ${path_amTreeTool} -i -h "${serverUrl}" -u "amadmin"  -p "${amAdminPwd}" -m Classic \
                      -f ${path_tmp_authTreesJson} -r "${authTreeRealm}" -t ${tmp_treeName}
                    echo "-- Done"
                    echo ""
                  fi
                else
                  echo "-- ERROR: Invalid AuthTree and/or Realm info"
                  echo "    Full Filename: ${tmp_authTreeDetails}"
                  echo "        Auth Tree: ${authTreeName}"
                  echo "       Realm info: ${authTreeRealm}"
                  errorFound="true"
                fi
              done            
            fi

            # update AllAuthenticatedUsers For AM
            arr_am_realms=($(echo "${UPDATE_ALL_AUTHENTICATED_USERS_REALMS}" | tr ',' '\n'))
            arr_am_realms_len=${#arr_am_realms[@]}
            echo "UPDATE_ALL_AUTHENTICATED_USERS_REALMS -> ${arr_am_realms}"
            if [ "${arr_am_realms_len}" -gt "0" ]; then
              echo "Updating AllAuthenticatedUsers For AM"
              echo "----------------------------"
              for tmp_am_realm in ${arr_am_realms[@]}; do
                updateAllAuthenticatedUsersForAM "${serverUrl}" "${amAdminPwd}" "${tmp_am_realm}"
              done
            fi
          else
            echo "AM already configured"
            echo "---------------------"
            echo "-- Skipping any bespoke customisation"
            echo "-- Done"
            echo ""
          fi

          if [ "${CS_SIDECAR_MODE,,}" == "true" ]; then
            addSharedFile ${path_sharedFile_am} "access-manager" # Notify CS that AM is done configuring
            echo "[ Waiting for Config Store to finish replication setup ]"
            checkIfFileExists "${path_sharedFile_cs}" 60
            removeSharedFile ${path_sharedFile_cs}
          fi

          manageTomcat "stop" "${amHttpsPort}" "${AM_URI}"

          echo "Cleaning up"
          echo "-----------"
          echo "-> Clearing ${path_tmpFolder} folder"
          rm -rf ${path_tmpFolder}
          echo "-- Done"
          echo ""

          echo "[ Waiting for Config Store to start-up before starting the Access Manager ]"
          echo ""
          if [ "${CS_SIDECAR_MODE,,}" == "true" ]; then
            checkServerIsAlive --svc "${CS_K8s_SVC_URL}" --type "ds" --channel "http" --port "${cfgStoreHttpPort}" --iterations 24 # Waitig for config-store to start successfully
            checkDSisHealthy "${CS_K8s_SVC_URL}" "http" "${cfgStoreHttpPort}" # REQUIRED: Config Store needs to be helathly before stating AM/Tomcat
          else
            checkServerIsAlive --svc "${CS_K8s_SVC_URL}" --type "ds" --channel "https" --port "${cfgStoreHttpsPort}" # Waitig for config-store to start successfully
            checkDSisHealthy "${CS_K8s_SVC_URL}" "https" "${cfgStoreHttpsPort}" # REQUIRED: Config Store needs to be helathly before stating AM/Tomcat
          fi
          manageTomcat "start" "${amHttpsPort}" "${AM_URI}"
        fi
      else
        echo "  - ERROR: ${path_tmp_amsterConfigScript} Not created. Exiting ..."
        echo ""
        errorFound="true"
      fi
    fi
  fi
fi
