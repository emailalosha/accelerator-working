#!/bin/bash
# =====================================================================
# MIDSHIPS
# COPYRIGHT 2020
# This file contains scripts to configure the base Java image required
# by the Midships ForgeRock Accelerator solution.
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

source ${MIDSHIPS_SCRIPTS}/midshipscore.sh;

echo "-> Creating required folders";
mkdir -p ${MIDSHIPS_SCRIPTS} ${path_tmp} ${JVM_PATH}
echo "-- Done";
echo "";

echo "-> Key Variables";
echo "PATH is $PATH"
echo "JAVA_HOME is $JAVA_HOME"
echo "-- Done";
echo "";

echo "-> Updating all installed packages on OS";
apt-get -y update
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

downloadPath_JDK="${STORAGE_BUCKET_PATH_BIN}/${filename_java}";

if [ -n "${downloadPath_JDK}" ] && [ -n "${path_tmp}" ] && [ -n "${filename_java}" ]; then
  if [ "${cloud_type,,}" = "gcp" ]; then
    echo "-> Downloading JDK (${downloadPath_JDK}) from GCP";
    gsutil cp "${downloadPath_JDK}" "${path_tmp}/${filename_java}";
    echo "-- Done";
    echo "";
  elif [ "${cloud_type,,}" = "aws" ]; then
    echo "-> Downloading JDK (${downloadPath_JDK}) from AWS";
    aws s3 cp "${downloadPath_JDK}" "${path_tmp}/${filename_java}";
    echo "-- Done";
    echo "";
  elif [ "${cloud_type,,}" = "ftp" ]; then
    echo "-> Downloading JDK (${downloadPath_JDK}) from artifactory";
      curl "${downloadPath_JDK}" -o "${path_tmp}/${filename_java}"
  fi
  echo "-- Done";
  echo "";
else
  echo "-- ERROR: Required parameters NOT provided. Exiting ..."
  exit 1
fi

removeCloudClient ${cloud_type,,} ${path_tmp};

echo "-> Installing Java";
tar -xf ${path_tmp}/${filename_java} -C ${JVM_PATH}/
echo "-- Done";
echo "";

echo "-> Checking Java";
echo "-- JAVA_HOME is set to ${JAVA_HOME}";
java -version;
echo "-- Done";
echo ""

if (( ${JAVA_VERSION_MAJOR} <= 8 )); then
  echo "-> Removing vulnerable jetty-server (v8.1.14) to resolve CVE-2017-7657";
  find  ${JAVA_HOME}/lib/missioncontrol/plugins/ -name 'org.eclipse.jetty.*' -exec rm {} \;
  echo "-- Done";
  echo "";
fi

echo "-> Cleaning up";
rm -rf ${path_tmp};
echo "-- Done";
echo "";
