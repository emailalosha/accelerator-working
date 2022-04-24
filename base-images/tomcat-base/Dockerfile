# ===========================================================
# COPYRIGHT 2017 MIDSHIPS
# Do not distribute without permission and this
# file is only usable with a valid license.

# Docker file to build Tomcat Base Image.

# For more information visit www.midships.io

# Image recommended name: tomcat-base
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

ARG IMAGE_TAG="stable"
ARG IMAGE_SRC="gcr.io/massive-dynamo-235117/java-base"
FROM ${IMAGE_SRC}:${IMAGE_TAG}

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
ARG tomcat_version=8.5.57
ARG path_tmp=/tmp/tomcat
ARG tomcat_dir=/opt/tomcat
ONBUILD ARG tomcat_dir=/opt/tomcat
ARG STORAGE_BUCKET_PATH_BIN="ftp://ruhle.drayddns.com"

# Environment Variables
# ---------------------
ENV TOMCAT_HOME=${tomcat_dir} \
    IMAGE_NAME=tomcat-base \
    AWS_ACCESS_KEY_ID=${aws_access_key_id} \
    AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}

# Copy over configuration scripts
# -------------------------------
COPY setup.sh ${path_tmp}/

# Required for GCP only
# COPY gcp-gcs-service-account.json ${path_tmp}/

# Setting up the image
# --------------------
RUN chmod +x ${path_tmp}/setup.sh
RUN ${path_tmp}/setup.sh
# Ensures update to TOMCAT_HOME variable is saved to image as changes to Env Variables appears to be lost on shell termination
ENV TOMCAT_HOME=${tomcat_dir}/apache-tomcat-${tomcat_version}

RUN echo "" && echo "-> Starting Tomcat as tomcat user" && ${TOMCAT_HOME}/bin/startup.sh && \
  echo "" && echo "-> Listing ${TOMCAT_HOME}" && ls -ltra ${TOMCAT_HOME} && \
  echo "" && echo "-> Listing ${TOMCAT_HOME}/bin" && ls -ltra ${TOMCAT_HOME}/bin && \
  echo "" && echo "-> Listing ${TOMCAT_HOME}/logs" && ls -ltra ${TOMCAT_HOME}/logs && \
  rm ${TOMCAT_HOME}/logs/catalina.out

EXPOSE 8443
