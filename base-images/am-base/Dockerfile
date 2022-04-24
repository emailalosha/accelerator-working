# ===========================================================
# COPYRIGHT 2021 MIDSHIPS
# Do not distribute without permission and this
# file is only usable with a valid license.

# Docker file to build ForgeRock Access Management Base Image.

# For more information visit www.midships.io
# Image recommended name: forgerock-am-base
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
# ===========================================================

#ARG IMAGE_TAG="latest"
#ARG IMAGE_SRC="artifactory.global.standardchartered.com/forgerock-accelerator/tomcat-base"
FROM artifactory.global.standardchartered.com/forgerock-accelerator/tomcat-base:latest

# Arguments
# ---------

# Must be provided for access to AWS S3 bucket
ARG aws_access_key_id
ARG aws_secret_access_key
# Must be provided for sFTP access
ARG ftp_uname
ARG ftp_pword

# Defaults:
ARG cloud_type="ftp"
ARG am_version=7.1.1
ARG amster_version=7.1.0
ARG am_home=/opt/am
ARG am_uri=am
ARG path_tmp=/tmp/am
ARG STORAGE_BUCKET_PATH_BIN="https://artifactory.global.standardchartered.com"
ARG filename_am=AM-${am_version}.war
ARG filename_amster=Amster-${amster_version}.zip
ARG ARTIFACTORY=https://artifactory.global.standardchartered.com/artifactory
# Environment Variables
# ---------------------
ENV AM_HOME=${am_home} \
    AM_URI=${am_uri} \
    AM_SECRETS="${am_home}/secrets" \
    AM_CONFIGMAPS="${am_home}/configmaps" \
    AWS_ACCESS_KEY_ID=${aws_access_key_id} \
    AWS_SECRET_ACCESS_KEY=${aws_secret_access_key} \
    MIDSHIPS_SCRIPTS="/opt/midships/scripts" \
    JAVA_CACERTS="/etc/pki/ca-trust/extracted/java/cacerts"

# Copy over configuration scripts
# -------------------------------
COPY files/setup.sh ${path_tmp}/
COPY files/midshipscore.sh ${MIDSHIPS_SCRIPTS}/
COPY files/amtree.sh ${AM_HOME}/tools/

# Setting up the image
# --------------------
RUN chmod +x ${path_tmp}/setup.sh
RUN chmod -x ${MIDSHIPS_SCRIPTS}/*.sh
RUN chmod 775 ${AM_HOME}/tools/amtree.sh
RUN ${path_tmp}/setup.sh

USER am
RUN echo "" && echo "-> Starting Tomcat as AM user" && ${TOMCAT_HOME}/bin/startup.sh && \
  echo "" && echo "-> Listing ${TOMCAT_HOME}" && ls -ltra ${TOMCAT_HOME} && \
  echo "" && echo "-> Listing ${TOMCAT_HOME}/bin" && ls -ltra ${TOMCAT_HOME}/bin && \
  echo "" && echo "-> Listing ${TOMCAT_HOME}/logs" && ls -ltra ${TOMCAT_HOME}/logs
EXPOSE 8443 443

ENTRYPOINT ["bash", "/opt/am/scripts/init.sh"]
