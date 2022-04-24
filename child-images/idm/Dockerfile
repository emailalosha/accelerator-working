# ===========================================================
# COPYRIGHT 2021 MIDSHIPS
# Do not distribute without permission and this
# file is only usable with a valid license.

# Docker file to build ForgeRock Identity Manager (IDM) Image.

# For more information visit www.midships.io

# Image recommended name: forgerock-idm
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
ARG sftp_uname
ARG sftp_pword

# Defaults:
ARG cloud_type="sftp"
ARG idm_version=7.1.0
ARG idm_home=/opt/idm
ARG path_tmp=/tmp/idm
ARG filename_idm=IDM-${idm_version}.zip
ARG STORAGE_BUCKET_PATH_BIN="ftp://ruhle.drayddns.com"

# Environment Variables
# ---------------------
ENV IMAGE_NAME=forgerock-idm \
    IDM_HOME=${idm_home} \
    IDM_VERSION=${idm_version} \
    IDM_PROJECTS=${idm_home}/project \
    IDM_CONFIGMAPS=/opt/idm/configmaps \
    IDM_SECRETS=/opt/idm/secrets \
    IDM_KEYSTORE=${idm_home}/security/keystore.jceks \
    IDM_TRUSTSTORE=${idm_home}/security/truststore \
    AWS_ACCESS_KEY_ID=${aws_access_key_id} \
    AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}

# Setup default shell to Bash
# ---------------------------
SHELL ["/bin/bash", "-c"]

# Copy over files
# ---------------
COPY files/init.sh ${IDM_HOME}/scripts/
COPY files/setup.sh ${path_tmp}/
RUN chmod +x ${IDM_HOME}/scripts/init.sh
# Required for GCP only
# COPY files/gcp-gcs-service-account.json ${path_tmp}/

# Setting up the image
# --------------------
RUN chmod +x ${path_tmp}/setup.sh
RUN ${path_tmp}/setup.sh

EXPOSE 8443 443 8080 80

ENTRYPOINT ["bash", "/opt/idm/scripts/init.sh"]
