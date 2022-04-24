#!/bin/bash
# =====================================================================
# MIDSHIPS
# COPYRIGHT 2022
# This file contains scripts to configure the base scripts required by
# Midships ForgeRock Accelerator solution.
#
# NOTE: Don't check this file into source control with
#       any sensitive hard coded vaules.
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
# ---------------------------------------------------------------------
set +H #Disablng Historical Expansion to allow things like ! in varibles

# -------------------------------------------------------
# Function to install Python
# -------------------------------------------------------
installPython(){
	echo "-- installing Python"
	apt-get -y install python3
	echo "-- Done"
	echo ""
	echo "-- Making Python 3 Default (Sym Link for python)"
	update-alternatives --install /usr/bin/python python /usr/bin/python3 2
	echo "-- Done"
	echo ""
}

# -------------------------------------------------------
# Function to remove Python
# -------------------------------------------------------
removePython(){
	echo "-- Removing Python"
	apt-get remove -y python3
	rm -rf /usr/bin/python
	echo "-- Done"
	echo ""
	echo "-- Cleaning up packages"
	apt-get -y clean
	apt-get -y autoremove
	echo "-- Done"
	echo ""
}

# -------------------------------------------------------
# Function to install Cloud Agent (GCP, AWS, AZURE, etc.)

# Parameters:
# ${1} : The Cloud Provider. E.g. aws, gcp, azure, etc.
# ${2} : Temp folder for binary and GCP account access file
# -------------------------------------------------------
installCloudClient () {
	cloudProvider=${1}
	pathTmp=${2}
	echo "-> Entered installCloudClient"
	echo "-- [Inputs]"
	echo "   cloudProvider: ${cloudProvider}"
	echo ""
	mkdir -p "${pathTmp}"
	case ${cloudProvider,,} in
	  "gcp")
			installPython
			echo "-- Dwonloading zip"
			curl -k -o ${pathTmp}/google-cloud-sdk.zip https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.zip
			echo "-- Done"
			echo ""
	    echo "-- Unzipping zip"
	    unzip "${pathTmp}/google-cloud-sdk.zip" -d /opt/
			echo "-- Done"
			echo ""
			echo "-- Installing GOOGLE-CLOUD-SDK CLI"
	    /opt/google-cloud-sdk/install.sh --usage-reporting=true --path-update=true --bash-completion=true --rc-path=/opt/gcloud/.bashrc --disable-installation-options
			export PATH=/opt/google-cloud-sdk/bin:$PATH
			echo "-- Done"
			echo ""
	    echo "-- Updating GCloud components"
	    /opt/google-cloud-sdk/bin/gcloud --quiet components update app preview alpha beta app-engine-java app-engine-python kubectl bq core gsutil gcloud
			echo "-- Done"
			echo ""
	    echo "-- Authenticating with GCloud"
	    gcloud auth activate-service-account --key-file=${pathTmp}/gcp-gcs-service-account.json
			echo "-- Done"
			echo ""
		;;
	  "aws")
			# installPython
			echo "-- Installing AWS CLI"
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
	    # pip3 install awscli
      unzip awscliv2.zip
      ./aws/install --update
	    aws --version     
			echo "-- Done"
			echo ""
	  ;;
	  "azure")
	    echo ""
	    ;;
	  *)
			echo "-- Skipping client instalation"
			echo "-- Done"
			echo ""
		;;
	esac
}

# -------------------------------------------------------
# Function to remove Cloud Agent (GCP, AWS, AZURE, etc.)

# Parameters:
# ${1} : The Cloud Provider. E.g. aws, gcp, azure, etc.
# ${2} : Temp folder for binary and GCP account access file
# -------------------------------------------------------
removeCloudClient () {
	cloudProvider=${1}
	pathTmp=${2}
	echo "-> Entered removeCloudClient"
	echo "-- [Inputs]"
	echo "   cloudProvider: ${cloudProvider}"
	echo ""
	mkdir -p "${pathTmp}"
	case ${cloudProvider,,} in
	  "gcp")
			echo "-- Deleting ${pathTmp}/google-cloud-sdk.zip"
      rm -rf "${pathTmp}/google-cloud-sdk.zip"
			echo "-- Done"
			echo ""
			echo "-- Deleting ${pathTmp}/gcp-gcs-service-account.json"
			rm -rf "${pathTmp}/gcp-gcs-service-account.json"
			echo "-- Done"
			echo ""
      echo "-- Deleting '/opt/google-cloud-sdk'"
      rm -drf /opt/google-cloud-sdk
			echo "-- Done"
			echo ""
      echo "-- Deleting '/opt/gcloud'"
      rm -drf /opt/gcloud
			echo "-- Done"
			echo ""
			echo "-- Deleting '~/.config/gcloud'"
      rm -drf '~/.config/gcloud'
			echo "-- Done"
			echo ""
			echo "-- Cleaning 'PATH'"
			export PATH=${PATH/'/opt/google-cloud-sdk/bin:'/}
			removePython
		;;
	  "aws")
			echo "-- Removing AWS CLI"
	    pip3 uninstall awscli
			echo "-- Done"
			echo ""
			echo "-- Clearing ENV variables"
	    export AWS_ACCESS_KEY_ID=""
	    export AWS_SECRET_ACCESS_KEY=""
			echo "-- Done"
			echo ""
			removePython
	  ;;
	  "azure")
	    echo ""
	  ;;
	  *)
			echo "-- Skipping client removal as none was installed."
			echo "-- Done"
			echo ""
	  ;;
	esac
}

# ------------------------------------------
# Function to get client secrets from Vault
# Parameters:
# ${1} : return_val
# ${2} : Protocol for API
# ${3} : the vault token to maken the call
# ${4} : key path
# ${5} : the name of the secret key
# -----------------------------------------
getSecretFromVault () {
	echo "-> Getting '${4}/${5}'"
	secret_info=$(curl -sk --header 'X-Vault-Token: '"${3}" \
		--header "X-Vault-Namespace: admin" \
		--request GET ${2}/v1/"${4}" | jq -r '.data.data.'"${5}")
	# Remove below comment when testing
  # echo "-- Value is $secret_info"
	eval "${1}='${secret_info}'"
  echo "-- Done"
	echo ""
}

# ------------------------------------------
# Function to get client secrets from AWS
# Parameters:
# ${1} : return_val
# ${2} : AWS Secret ID
# ${3} : the name of the secret key
# -----------------------------------------
getSecretFromAwsSecretsManager () {
  echo "AWS Authentication"
  aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
  aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
  aws configure set region eu-west-2
	echo "-> Getting '${2}/${3}'"
  secret_info=$(aws secretsmanager get-secret-value --secret-id ${2} | jq -r ".SecretString" | jq -r '.'"${3}")
	eval "${1}='${secret_info}'"
  echo "-- Done"
	echo ""
}

# ----------------------------------------------------------------------
# This function adds a file to a specific location with provided string
#
# Parameters:
#  - ${1}: The full path of the file to create
#  - ${2}: the string content for the file
# ----------------------------------------------------------------------
function addSharedFile() {
  echo "-> Entered function addSharedFile"
  sharedFolder=${1%/*}
  echo "-- Shared folder is ${sharedFolder}"
  echo "-- Shared file is ${1}"
  mkdir -p ${sharedFolder}
  echo "${2}" > ${1}
  echo "-- Done"
  echo ""
}

# ----------------------------------------------------------------------
# This function checks if a check if a file exists end exits once found.
#
# Parameters:
#  - ${1}: The full path of the file
#  - ${2}: This is a multipler for the ${checkFrequency}
# ----------------------------------------------------------------------
function checkIfFileExists() {
  filePathToFind=${1}
  fileEsistsCounter=1
  checkFrequency=10
  if [ -z ${2} ] || [ "${2}" == "null" ]; then
    noOfChecks=30
  else
    noOfChecks=${2}
  fi
  sharedFolder=${filePathToFind%/*}
  echo ""
  echo "-> Entered function checkIfFileExists"
  echo "   Shared Folder: ${sharedFolder}"
  echo "    File to Find: ${filePathToFind}"
  mkdir -p ${sharedFolder}
  while [ ! -f ${filePathToFind} ];
  do
    echo "-- (${fileEsistsCounter}/${noOfChecks}) Waiting ${checkFrequency} seconds ..."
    sleep ${checkFrequency}

    if [ ${fileEsistsCounter} == ${noOfChecks} ]; then
      secondsWaitedFor=$((${checkFrequency} * ${noOfChecks}))
      echo "-- Waited for ${secondsWaitedFor} seconds and no response"
      echo "config-store" > ${filePathToFind}
      echo "-- Exiting"
    fi
    fileEsistsCounter=$((${fileEsistsCounter} + 1))
  done
  echo "-- File (${filePathToFind}) found"
  echo "-- Done"
  echo ""
}

# ****************************************************************************
# This function gets Secres and Configuration from a Secrets Manager or Kubernetes
# Cluster Secrets and Config-Maps
#
# Parameters:
#  - ${1}: Return Value. The secret value returned
#  - ${2}: Secrets Source/Mode. Accepted k8s and REST
#  - ${3}: Secrets Manager Base URL
#  - ${4}: Folder Path to Secret
#  - ${5}: Secret Key name to retreive
#  - ${6}: Secret name to retreive
#  - ${7}: Secrets Manager Token
#  - ${8}: Encode returnd value. Accepts 'true' or 'false'
# ****************************************************************************
function getSecretAndConfig() {
  echo "[ Entered function getSecretAndConfig() ]"
  tmpSecretMode="${2}"
  secretsMngrBaseURL="${3}"
  secretsMngrFolder="${4}"
  secretKeyName="${5}"
	secretKeyURL="${6}"
  secretsMngrToken="${7}"
  encodeRetVal="${8}"
  tmpVal=
  [ -z "${encodeRetVal}" ] && encodeRetVal="false"
  if [ -n "${tmpSecretMode}" ] && [ -n "${secretsMngrBaseURL}" ]; then
    if [ "${tmpSecretMode^^}" == "REST" ]; then
      if [ -n "${secretsMngrToken}" ] && [ -n "${secretKeyName}" ] && [ -n "${secretKeyURL}" ]; then
        getSecretFromVault tmpVal "${secretsMngrBaseURL}" "${secretsMngrToken}" "${secretKeyURL}" "${secretKeyName}"
        # getSecretFromAwsSecretsManager tmpVal "${secretKeyURL}" "${secretKeyName}"
        echo "-- Secret ${secretKeyName} retrieved"
      else
        echo "-- ERROR: One of the below required input variables were EMPTY:"
        echo "   > {5} secretKeyName is ${secretKeyName}"
        echo "   > {6} secretKeyURL is ${secretKeyURL}"
        echo "   > {7} secretsMngrToken length is ${#secretsMngrToken}"
        echo "-- Exiting ...."
        exit 1
      fi
    elif [ "${tmpSecretMode,,}" == "k8s" ]; then
      if [ -n "${secretKeyName}" ] && [ -n "${secretsMngrFolder}" ]; then
        echo "-> Getting '${secretKeyName}' from ${secretsMngrFolder}"
				tmpPathToSecretKey="${secretsMngrFolder}/${secretKeyName}"
				if [ -d "${secretsMngrFolder}" ] && [ -f "${tmpPathToSecretKey}" ]; then
	        tmpVal=$(cat "${secretsMngrFolder}/${secretKeyName}")
	        if [ -n "${tmpVal}" ] && [ "${encodeRetVal,,}" == "true" ]; then
	          tmpVal=$(echo "${tmpVal}" | base64)
	        fi
				else
					echo "-- ERROR: Either the required Folder of File below could not be found:"
					echo "   > Folder requiired is ${secretsMngrFolder}"
					echo "   > File required is ${secretKeyName}"
					echo "-- Exiting ...."
					exit 1
				fi
        echo "-- Done"
        echo ""
      else
        echo "-- ERROR: One of the below required input variables were EMPTY:"
        echo "   > {4} secretsMngrFolder is ${secretsMngrFolder}"
        echo "   > {5} secretKeyName is ${secretKeyName}"
        echo "-- Exiting ...."
        exit 1
      fi
    fi
    eval "${1}='${tmpVal}'"
  else
    echo "-- ERROR: One of the below required input variables were EMPTY:"
    echo "   > {2} tmpSecretMode is ${tmpSecretMode}"
    echo "   > {3} secretsMngrBaseURL is ${tmpServerUrl}"
    echo "-- Exiting ...."
    exit 1
  fi
}

# ****************************************************************************
# This functions changes the password fo a Java TrustStore
#
# Parameters:
#  - ${path_truststoreFile}: The path to the truststore file
#  - ${pwd_old}: Truststore current password
#  - ${pwd_new}: Truststore new password
# ****************************************************************************
function changeTrustStorePassword() {
  path_truststoreFile=${1}
  pwd_old=${2}
	pwd_new=${3}
  echo "-> Entered changeTrustStorePassword"
  echo "-- Changing password for '${path_truststoreFile}'"
	keytool -storepasswd -new "${pwd_new}" -storepass "${pwd_old}" -keystore "${path_truststoreFile}"
  echo "-- Done"
  echo ""
}

# ****************************************************************************
# This functions creates a PKCS12 keystore from Certificate (.pem) and
# certificateKey (.pem)
#
# Parameters:
#  - ${certName}: The certificate alias
#  - ${certificate}: The .pem (base64 encoded) of the certificate public key
#  - ${certificateKey}: The .pem (base64 encoded)  of the certificate private key
#  - ${path_keystoreFile}: The path to the pkcs12 keystore file to be created
#  - ${pwd_keystore}: pkcs12 keystore password
# ****************************************************************************
function createPKCS12fromCerts() {
  certName=${1}
  certificate=${2}
  certificateKey=${3}
  path_keystoreFile=${4}
  pwd_keystore=${5}
  echo "-> Entered createPKCS12fromCerts"
  echo "-- Decoding Base64 encoded pem certificate"
  echo "${certificate}" | base64 --decode > /tmp/allcerts.pem
  echo "-- Decoding Base64 encoded pem certificate key"
  echo "${certificateKey}" | base64 --decode > /tmp/certPrivateKey.pem
  echo "-- Creaking pkcs12 keystore from pem files"
  openssl pkcs12 -export -name "${certName}" \
    -inkey /tmp/certPrivateKey.pem \
    -in /tmp/allcerts.pem -passin pass:"${pwd_keystore}" \
    -out "${path_keystoreFile}"  -passout pass:"${pwd_keystore}"
  if [ -f "${path_keystoreFile}" ]; then
  	echo "-- '${path_keystoreFile}' created successfully"
  	echo "-- Cleaning up"
  	rm -f /tmp/allcerts.pem /tmp/certPrivateKey.pem
    echo "-- Done"
    echo ""
  else
    echo "-- ERROR: ${path_keystoreFile} NOT created. Exiting ..."
    echo "-- Done"
    echo ""
    exit 1
  fi
}

# ****************************************************************************
# This functions add a certificate (.pem) to the Java TrustStore
#
# Parameters:
#  - ${certName}: The certificate alias
#  - ${certificate}: The .pem (base64 encoded) of the certificate public key
#  - ${path_truststoreFile}: The path to the truststore file
#  - ${pwd_truststore}: Truststore password
# ****************************************************************************
function importCertIntoTrustStore() {
  certName=${1}
  certificate=${2}
  path_truststoreFile=${3}
  pwd_truststore=${4}
  echo "-> Entered importCertIntoTrustStore"
  echo "-- Extracting Certificate (pem) ..."
  echo "${certificate}" | base64 --decode > /tmp/allcerts.pem
  echo "-- Adding cert to JVM truststore"
  keytool -importcert -trustcacerts -file /tmp/allcerts.pem -keystore ${path_truststoreFile} -alias "${certName}" -storepass "${pwd_truststore}" -noprompt
	echo "-- Cleaning up"
	rm -f /tmp/allcerts.pem
  echo "-- Done"
  echo ""
}

function importPKCS12IntoKeyStore() {
  echo "-> Creating JKS from Pem files"
  certName=${1}
  path_keystoreFile_source=${2}
  path_keystoreFile_dest=${3}
	pwd_key=${4}
  pwd_keystore=${5}
	storeTyp=${6}
  echo "-- Importing '${path_keystoreFile_source}' into '${path_keystoreFile_dest}'"
	keytool -importkeystore -alias "${certName}" \
    -deststorepass "${pwd_keystore}" -destkeypass "${pwd_key}" -destkeystore ${path_keystoreFile_dest} \
    -srckeystore "${path_keystoreFile_source}" -srcstoretype pkcs12 -srcstorepass "${pwd_key}" \
    -storetype "${storeTyp}"
  echo "-- Done"
  echo ""
}

# ----------------------------------------------
# Function to create self-signed certificate
# ${1} : Certificate Name
# ${2} : Certificate Key Name
# ${3} : Cert save location
# -----------------------------------------------
# createSelfSignedCert () {
#   echo "> Entered createSelfSignedCert ()"
#   echo ""
#   if [ -z "${1}" ]
#   then
#     echo "-- {1} is Empty. This should be Certificate Name"
#     ${1}="certName"
#     echo "-- {1} Set to ${1}"
#     echo ""
#   fi
#
#   if [ -z "${2}" ]
#   then
#     echo "-- {3} is Empty. This should be Certificate save folder location"
#     ${3}="/tmp/certs"
#     echo "-- {3} Set to ${3}"
#     echo ""
#   fi
#
#   if [ -z "${3}" ]
#   then
#     echo "-- {4} is Empty. This should be Certificate CN (Common Name)"
#     echo "-- Exiting ..."
#     echo ""
#     exit
#   fi
#
#   certName=${1}
#   certSaveFolder=${2}
#   certCN=${3}
#
#   rm -rf ${certSaveFolder}
#   mkdir -p ${certSaveFolder}
# 	echo "--> Creating certificate"
#   mkdir -p ${certSaveFolder}
#
# # Creating self signed cert details file
# cat << EOF >> ${certSaveFolder}/certdetails.txt
# [req]
# default_bits = 2048
# prompt = no
# default_md = sha256
# req_extensions = req_ext
# distinguished_name = dn
#
# [ dn ]
# C = UK
# ST = London
# L = London
# O = Midships
# OU = Midships
# emailAddress = admin@Midships.io
# CN = ${certCN}
#
# [ req_ext ]
# subjectAltName = @otherCNs
#
# [ otherCNs ]
# DNS.1 = ${certCN}
# DNS.2 = *.${certCN}
# DNS.3 = *.${certCN#*.}
# EOF
#
#   echo "---- Cert folder created at ${certSaveFolder}"
#   openssl req -newkey rsa:2048 -nodes -keyout "${certSaveFolder}/${certName}-key.pem" -x509 -days 365 -out "${certSaveFolder}/${certName}.pem" -config <( cat "${certSaveFolder}/certdetails.txt" )
# 	echo "-- Exiting function"
#   echo ""
# }

# -----------------------------------------------
# Function to generate random string
# ${1} : Encoding: E.g base64
# ${2} : String length
# -----------------------------------------------
generateRandomString(){
  rndstr=$(openssl rand -${1} ${2})
  echo "$rndstr"
}

# -----------------------------------------------
# Function to add secrets to Vault from json file
# ${1} : return_val
# ${2} : VAULT URL
# ${3} : VAULT TOKEN
# ${4} : secrets path in Vault
# ${5} : json file path with data
# -----------------------------------------------
addSecretsToVault(){
  echo "-- Adding secrets to VAULT section '${4}'"
	secret_info=$(curl -sk --header 'X-Vault-Token: '${3} \
		--header "X-Vault-Namespace: admin" \
    --request POST --data @${5} \
    ${2}/v1/${4} | jq -r '.data.destroyed')
	if [ "${errorFound}" == "false" ]; then
  	eval "${1}='true'"
	else
		eval "${1}='false'"
	fi
  echo "-- Done"
  echo ""
}

#-------------------------------------------------
# Function to delete All vesion of secrets from Vault
# ${1} : VAULT URL
# ${2} : VAULT TOKEN
# ${3} : secrets path in Vault
# ${4} : Name of Secrets Engine
# -----------------------------------------------
deleteSecretsFromVault_AllVersions(){
  echo "-- Deleting ${3}"
  curl \
    --header 'X-Vault-Token: '${2} \
		--header "X-Vault-Namespace: admin" \
    --request DELETE \
     "${1}/v1/${4}/metadata/${3}"
  echo "-- Done"
  echo ""
}

# -----------------------------------------------
# Function to delete All vesion of secrets from Vault
# ${1} : VAULT URL
# ${2} : VAULT TOKEN
# ${3} : secrets path in Vault
# ${4} : Name of Secrets Engine
# -----------------------------------------------
deleteSecretsFromVault_LatestVersion(){
  echo "-- Deleting ${3}"
  curl \
    --header 'X-Vault-Token: '${2} \
		--header "X-Vault-Namespace: admin" \
    --request DELETE \
    "${1}/v1/${4}/data/${3}"
  echo "-- Done"
  echo ""
}

# ----------------------------------------------------------------------
# This function checks if a check if a file exists end exits once found.
#
# Parameters:
#  - ${1}: The full path of the file
#  - ${2}: This is a multipler for the ${checkFrequency}
# ----------------------------------------------------------------------
function checkIfFileExists() {
  filePathToFind=${1}
  fileEsistsCounter=1
  checkFrequency=10
  if [ -z "${2}" ] || [ "${2}" == "null" ]; then
    noOfChecks=30
  else
    noOfChecks=${2}
  fi
  sharedFolder=${filePathToFind%/*}
  echo ""
  echo "-> Entered function checkIfFileExists"
  echo "   Shared Folder: ${sharedFolder}"
  echo "    File to Find: ${filePathToFind}"
  mkdir -p ${sharedFolder}
  while [ ! -f "${filePathToFind}" ];
  do
    echo "-- (${fileEsistsCounter}/${noOfChecks}) Waiting ${checkFrequency} seconds ..."
    sleep ${checkFrequency}

    if [ ${fileEsistsCounter} == ${noOfChecks} ]; then
      secondsWaitedFor=$((checkFrequency * noOfChecks))
      echo "-- Waited for ${secondsWaitedFor} seconds and no response"
      echo "config-store" > "${filePathToFind}"
      echo "-- Exiting"
      exit 1
    fi
    fileEsistsCounter=$((fileEsistsCounter + 1))
  done
  echo "-- File (${filePathToFind}) found"
  echo "-- Done"
  echo ""
}

# ----------------------------------------------------------------------
# This function adds a file to a specific location with provided string
#
# Parameters:
#  - ${1}: The full path of the file to create
#  - ${2}: the string content for the file
# ----------------------------------------------------------------------
function addSharedFile() {
  echo "-> Entered function addSharedFile"
  sharedFolder=${1%/*}
  echo "-- Shared folder is ${sharedFolder}"
  echo "-- Shared file is ${1}"
  mkdir -p ${sharedFolder}
  echo "${2}" > ${1}
  echo "-- Done"
  echo ""
}

# ----------------------------------------------------------------------
# This function deletes a file from a specific location
#
# Parameters:
#  - ${1}: The full path of the file to delete
# ----------------------------------------------------------------------
function removeSharedFile() {
  echo "-> Entered function removeSharedFile"
  rm -f ${1}
  echo "-- Done"
  echo ""
}
