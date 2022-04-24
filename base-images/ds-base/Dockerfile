# ===========================================================
# COPYRIGHT 2017 MIDSHIPS
# Do not distribute without permission and this
# file is only usable with a valid license.

# Docker file to build ForgeRock Directory Server Base Image.

# For more information visit www.midships.io

# Image name: forgerock-ds-base
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

ARG IMAGE_TAG="latest"
ARG IMAGE_SRC="artifactory.global.standardchartered.com/forgerock-accelerator/java-base"
FROM artifactory.global.standardchartered.com/forgerock-accelerator/java-base:latest

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
ARG ds_version=7.1.1
ARG ds_home=/opt/ds
ARG path_tmp=/tmp/ds
ARG STORAGE_BUCKET_PATH_BIN="https://artifactory.global.standardchartered.com/"
ARG filename_ds=DS-${ds_version}.zip
ARG ARTIFACTORY=https://artifactory.global.standardchartered.com/artifactory
# Environment Variables
# ---------------------
ENV DS_HOME="${ds_home}" \
  	DS_APP="${ds_home}/app" \
    DS_INSTANCE="${ds_home}/app/instance" \
    DS_SCRIPTS="${ds_home}/scripts" \
    DS_SECRETS="${ds_home}/secrets" \
    DS_CONFIGMAPS="${ds_home}/configmaps" \
    DS_VERSION="${ds_version}" \
    OPENDJ_JAVA_HOME="${JAVA_HOME}" \
    IMAGE_NAME=forgerock-ds-base \
    AWS_ACCESS_KEY_ID=${aws_access_key_id} \
    AWS_SECRET_ACCESS_KEY=${aws_secret_access_key} \
    MIDSHIPS_SCRIPTS="/opt/midships/scripts" \
    JAVA_CACERTS="/etc/pki/ca-trust/extracted/java/cacerts"

# Setup default shell to Bash
# ---------------------------
SHELL ["/bin/bash", "-c"]

# Copy over scripts
# -----------------
COPY files/forgerock-ds-shared-functions.sh ${DS_SCRIPTS}/
COPY files/midshipscore.sh ${MIDSHIPS_SCRIPTS}/
COPY files/setup.sh ${path_tmp}/

# Required for GCP only
# COPY files/gcp-gcs-service-account.json ${path_tmp}/

# Setting up the image
# --------------------
RUN chmod +x ${path_tmp}/setup.sh
RUN chmod +x ${MIDSHIPS_SCRIPTS}/*.sh
RUN chmod +x ${DS_SCRIPTS}/*.sh
RUN ${path_tmp}/setup.sh

EXPOSE 8443 1636 4444
