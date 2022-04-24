# ===============================================
# COPYRIGHT 2017 MIDSHIPS

# Do not distribute without permission and this
# file is only usable with a valid license.

# For more information visit www.midships.io

# Image name: java-base
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
# ===============================================

FROM artifactory.global.standardchartered.com/gv-images-products/bi/ubi8/ubi:8.5-226

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
ARG STORAGE_BUCKET_PATH_BIN="https://artifactory.global.standardchartered.com/artifactory/technology-standard-release/application/application-development/languages-frameworks-build-tools-runtime/openjdk/redhat/11"
ARG path_tmp=/tmp/java
ARG midships_scripts_path="/opt/midships/scripts"
ARG java_version_major=11
ARG java_version_minor=11
ARG filename_java=java-11-openjdk-11.0.11.0.9-0.portable.jdk.el.x86_64.tar.xz

# Environment Variables
# ---------------------
ENV JAVA_VERSION_MAJOR=${java_version_major} \
    JAVA_VERSION_MINOR=${java_version_minor} \
    MIDSHIPS_SCRIPTS=${midships_scripts_path} \
    AWS_ACCESS_KEY_ID=${aws_access_key_id} \
    AWS_SECRET_ACCESS_KEY=${aws_secret_access_key} \
    JVM_PATH=/usr/lib/jvm
ENV JAVA_HOME=${JVM_PATH}/java-11-openjdk-11.0.11.0.9-0.portable.jdk.el.x86_64
ENV PATH="$JAVA_HOME/bin:$PATH" \
    JAVA_CACERTS=${JAVA_HOME}/lib/security/cacerts

# Setup default shell to Bash
# ---------------------------
SHELL ["/bin/bash", "-c"]

# Copy required files
# -------------------
COPY files/midshipscore.sh ${MIDSHIPS_SCRIPTS}/
COPY files/setup.sh ${path_tmp}/

# Required for GCP only
# COPY files/gcp-gcs-service-account.json ${path_tmp}/

# Setting up the base image
# -------------------------
RUN chmod +x ${path_tmp}/setup.sh
RUN ${path_tmp}/setup.sh

CMD ["java","-version"]
