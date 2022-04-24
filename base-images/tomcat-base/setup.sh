#!/bin/bash
# =====================================================================
# MIDSHIPS
# COPYRIGHT 2022
# This file contains scripts to configure the base Tomcat image
# required by the Midships ForgeRock Accelerator.
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

echo "-> Creating required folders";
mkdir -p ${TOMCAT_HOME} ${path_tmp}
echo "-- Done";
echo "";

installCloudClient ${cloud_type,,} ${path_tmp};

downloadPath_Tomcat="${STORAGE_BUCKET_PATH_BIN}/apache/tomcat/apache-tomcat-${tomcat_version}.zip";

if [ -n "${downloadPath_Tomcat}" ] && [ -n "${path_tmp}" ]; then
  if [ "${cloud_type,,}" = "gcp" ]; then
    echo "-> Downloading Tomcat (${downloadPath_Tomcat}) from GCP";
    gsutil cp "${downloadPath_Tomcat}" "${path_tmp}/apache-tomcat-${tomcat_version}.zip";
  elif [ "${cloud_type,,}" = "aws" ]; then
    echo "-> Downloading Tomcat (${downloadPath_Tomcat}) from AWS";
    aws s3 cp "${downloadPath_Tomcat}" "${path_tmp}/apache-tomcat-${tomcat_version}.zip";
  elif [ "${cloud_type,,}" = "ftp" ]; then
    echo "-> Downloading Tomcat (${downloadPath_Tomcat}) from FTP";
    curl https://artifactory.global.standardchartered.com/artifactory/maven-release/org/apache/tomcat/tomcat/${tomcat_version}/tomcat-${tomcat_version}.zip -o ${path_tmp}/apache-tomcat-${tomcat_version}.zip
  fi
  echo "-- Done";
  echo "";
else
  echo "-- ERROR: Required parameters NOT provided. Exiting ..."
  exit 1
fi

removeCloudClient ${cloud_type,,} ${path_tmp};

echo "-> Installing Tomcat";
mkdir -p ${TOMCAT_HOME};
unzip ${path_tmp}/apache-tomcat-${tomcat_version}.zip -d ${TOMCAT_HOME};
export TOMCAT_HOME=${TOMCAT_HOME}/apache-tomcat-${tomcat_version}; #Remeber to set in Dockerfile or updated ENV Varible will be lost
echo "-- Updated TOMCAT_HOME to ${TOMCAT_HOME}"
echo "-- Done";
echo "";

echo "-> Creating User and Group";
groupadd -g 10001 tomcat
useradd -s /bin/nologin -g tomcat -m -d /home/tomcat tomcat -u 10001 -g 10001
echo "-- Done";
echo "";

echo "-> Setting permission(s)";
cd ${TOMCAT_HOME};
chgrp -R tomcat conf;
chmod g+rwx conf;
chmod g+r conf/*;
chown -R tomcat logs/ temp/ webapps/ work/;
chgrp -R tomcat bin;
chgrp -R tomcat lib;
chmod g+rwx bin;
chmod g+r bin/*;
chmod a+x bin/*;
echo "-- Done";
echo "";

echo "-> Removing unwanted web apps";
rm -fr ${TOMCAT_HOME}/webapps/manager
rm -fr ${TOMCAT_HOME}/webapps/host-manager
rm -fr ${TOMCAT_HOME}/webapps/examples
rm -fr ${TOMCAT_HOME}/webapps/docs
rm -fr ${TOMCAT_HOME}/webapps/ROOT
echo "-- Done";
echo "";

echo "-> Cleaning up";
rm -rf ${path_tmp};
echo "-- Done";
echo "";
