#!/bin/bash
# =====================================================================
# MIDSHIPS
# COPYRIGHT 2020
# This file contains scripts to configure the base ForgeRock Directory
# Services (DS) image required by the Midships ForgeRock Accelerator.
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

source ${MIDSHIPS_SCRIPTS}/midshipscore.sh

echo "-> Updating all installed packages on OS";
yum -y upgrade
echo "-- Done";
echo "";

echo "-> Installing required tools";
yum -y install openssl openssh-server curl unzip jq sed iputils hostname;
echo "-- Done";
echo "";

echo "-> Making copied scripts executable";
chmod 751 ${MIDSHIPS_SCRIPTS}/*.sh ${path_tmp}/*.sh;
echo "-- Done";
echo "";

installCloudClient ${cloud_type,,} ${path_tmp};

downloadPath_DS="https://artifactory.global.standardchartered.com/artifactory/generic-release/forgerock/ds/7.1.1/${filename_ds}";

if [ -n "${downloadPath_DS}" ] && [ -n "${path_tmp}" ] && [ -n "${filename_ds}" ]; then
  if [ "${cloud_type,,}" = "gcp" ]; then
    echo "-> Downloading DS (${downloadPath_DS}) from GCP";
    gsutil cp ${downloadPath_DS} ${path_tmp}/${filename_ds};
  elif [ "${cloud_type,,}" = "aws" ]; then
    echo "-> Downloading DS (${downloadPath_DS}) from AWS";
    aws s3 cp ${downloadPath_DS} ${path_tmp}/${filename_ds};
  elif [ "${cloud_type,,}" = "ftp" ]; then
    echo "-> Downloading DS from Artifactory";
    curl ${ARTIFACTORY}/generic-sc-release_local/forgerock/ds/${ds_version}/${filename_ds} -o ${path_tmp}/${filename_ds}
  fi
  echo "-- Done";
  echo "";
else
  echo "-- ERROR: Required parameters NOT provided. Exiting ..."
  exit 1
fi

removeCloudClient ${cloud_type,,} ${path_tmp};

echo "-> Creating User and Group";
groupadd -g 10002 ds;
useradd -m -s /bin/nologin -m -d /home/ds -u 10002 -g 10002 ds
echo "-- Done";
echo "";

echo "-> Creating required folders";
mkdir -p ${DS_APP} ${DS_INSTANCE} ${DS_SCRIPTS} ${path_tmp}
echo "-- Done";
echo "";

echo "-> Copying DS setup files";
unzip ${path_tmp}/${filename_ds} -d ${DS_HOME}
echo "-- Done";
echo "";

echo "-> Creating 'setupFiles' folder";
mv -f "${DS_HOME}/opendj" "${DS_HOME}/setupFiles"
echo "-- Files in ${DS_HOME}/setupFiles"
ls -A "${DS_HOME}/setupFiles"
echo "-- Done";
echo "";

echo "-> Backing up the ${JAVA_CACERTS} to ${DS_HOME}/cacerts";
cp "${JAVA_CACERTS}" "${DS_HOME}/cacerts"
echo "-- Done";
echo "";

echo "-> Setting permission(s)";
chown -R ds:ds ${MIDSHIPS_SCRIPTS} ${DS_HOME} ${JAVA_CACERTS} ${path_tmp};
chmod -R u=rwx,g=rx,o=r ${DS_HOME}/setupFiles;
echo "-- Done";
echo "";

echo "-> Cleaning up";
rm -rf ${path_tmp};
echo "-- Done";
echo "";
