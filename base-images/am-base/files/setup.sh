#!/bin/bash
# =====================================================================
# MIDSHIPS
# COPYRIGHT 2022
# This file contains scripts to configure the ForgeRock Access Manager
# (AM) image required by the Midships ForgeRock Accelerator.
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

source "${MIDSHIPS_SCRIPTS}/midshipscore.sh"

echo "-> Updating all installed packages on OS";
yum -y update
echo "-- Done";
echo "";

echo "-> Installing required tools";
yum -y install openssl openssh-server curl unzip jq sed iputils hostname vim-common;
echo "-- Done";
echo "";

echo "-> Making copied scripts executable";
chmod 751 ${MIDSHIPS_SCRIPTS}/*.sh ${path_tmp}/*.sh;
echo "-- Done";
echo "";

echo "-> Creating required folders";
mkdir -p "${AM_HOME}/tools/amster";
mkdir -p "${AM_HOME}/scripts";
mkdir -p "${AM_HOME}/tools/amster/.ssh";
mkdir -p "${path_tmp}";
echo "-- Done";
echo "";

echo "-> Checking key ENV Variables";
echo "-- TOMCAT_HOME is ${TOMCAT_HOME}"
echo "-- JAVA_HOME is ${JAVA_HOME}"
echo "-- JAVA_CACERTS is ${JAVA_CACERTS}"
echo "-- AM_HOME is ${AM_HOME}"
echo "-- Done";
echo "";

installCloudClient ${cloud_type,,} ${path_tmp};
downloadPath_AM="https://artifactory.global.standardchartered.com/artifactory/generic-release/forgerock/am/7.1.1/${filename_am}";
downloadPath_Amster="https://artifactory.global.standardchartered.com/artifactory/generic-release/forgerock/amster/7.1.0/${filename_amster}";
downloadPath_Jars="${STORAGE_BUCKET_PATH_BIN}/forgerock/access-manager/midships/*.jar";
downloadPath_JarsFolder="${STORAGE_BUCKET_PATH_BIN}/forgerock/access-manager/midships/";

if [ -n "${downloadPath_AM}" ] && [ -n "${downloadPath_Amster}" ] && [ -n "${downloadPath_Jars}" ] && [ -n "${downloadPath_JarsFolder}" ] && [ -n "${path_tmp}" ]; then
  if [ "${cloud_type,,}" = "gcp" ]; then
    echo "-> Downloading components from GCP";
    echo "-- Downloading AM (${downloadPath_AM})";
    gsutil cp "${downloadPath_AM}" "${TOMCAT_HOME}/webapps/am.war";
    echo "-- Downloading Amster (${downloadPath_Amster})";
    gsutil cp "${downloadPath_Amster}" "${path_tmp}/${filename_amster}";
    echo "-- Downloading AM Jars (${downloadPath_Jars})";
    gsutil cp "${downloadPath_Jars}" "${AM_HOME}/";
    echo "-- Done"
    echo ""
  elif [ "${cloud_type,,}" = "aws" ]; then
    echo "-> Downloading components from AWS";
    echo "-- Downloading AM (${downloadPath_AM})";
    aws s3 cp "${downloadPath_AM}" "${TOMCAT_HOME}/webapps/am.war";
    echo "-- Downloading Amster (${downloadPath_Amster})";
    aws s3 cp "${downloadPath_Amster}" "${path_tmp}/${filename_amster}";
    echo "-- Downloading AM Jars (${downloadPath_Jars})";
    aws s3 cp "${downloadPath_Jars}" "${AM_HOME}/" --recursive --exclude "*" --include "*.jar";
    echo "-- Done"
    echo ""
  elif [ "${cloud_type,,}" = "ftp" ]; then
    echo "-> Downloading components from sFTP";
    curl ${ARTIFACTORY}/generic-release/forgerock/am/${am_version}/${filename_am} -o ${TOMCAT_HOME}/webapps/am.war;
    curl ${ARTIFACTORY}/generic-release/forgerock/amster/${amster_version}/${filename_amster} -o ${path_tmp}/${filename_amster};
    curl ${ARTIFACTORY}/maven-release/org/postgresql/postgresql/42.2.24/postgresql-42.2.24.jar -o ${AM_HOME}/postgresql-42.2.24.jar;
    curl ${ARTIFACTORY}/generic-temp_local/forgerock/am-treetool/1.0/am-treetool.zip -o ${path_tmp}/am-treetool.zip
  fi
else
  echo "-- ERROR: Required parameters NOT provided. Exiting ..."
  exit 1
fi
ls /opt/tomcat/apache-tomcat-9.0.52/webapps
removeCloudClient ${cloud_type,,} ${path_tmp};

echo "-> Creating User and Group";
groupadd -g 10002 am;
useradd -s /bin/nologin -g am -u 10002 -g 10002 -m -d /home/am am;
echo "-- Done";
echo "";

echo "-> Installing Access Manager (AM)";
tmpPath="${path_tmp}/${filename_am}"
# if [ -f "${tmpPath}" ] && [ -d "${TOMCAT_HOME}/webapps" ]; then
#   mv ${tmpPath} "${TOMCAT_HOME}/webapps/am.war";
#   echo "-- Done";
#   echo "";
# else
#   echo "Either AM file (${tmpPath}) or folder (${TOMCAT_HOME}/webapps) cannot be found. Exiting ..."
#   exit 1
# fi

echo "-> Installing Amster";
tmpPath="${path_tmp}/${filename_amster}"
if [ -f "${tmpPath}" ] && [ -d "${AM_HOME}/tools/amster" ]; then
  unzip ${tmpPath} -d ${AM_HOME}/tools/amster;
  echo "-- Done";
  echo "";
else
  echo "Either Tomcat file (${tmpPath}) or folder (${AM_HOME}/tools/amster) cannot be found. Exiting ..."
  exit 1
fi

echo "-> Backing up the ${JAVA_CACERTS} to ${AM_HOME}/cacerts";
cp "${JAVA_CACERTS}" "${AM_HOME}/cacerts"
echo "-- Done";
echo "";

echo "-> Setting permission(s)";
chown -R am:am ${AM_HOME} ${TOMCAT_HOME} ${MIDSHIPS_SCRIPTS} ${JAVA_CACERTS} ${path_tmp}
echo "-- Done";
echo "";

echo "-> Cleaning up";
rm -rf ${path_tmp};
echo "-- Done";
echo "";
