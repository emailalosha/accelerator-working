# ===========================================================
# COPYRIGHT 2017 MIDSHIPS
# Do not distribute without permission and this
# file is only usable with a valid license.

# Docker file to build ForgeRock Access Management Image.

# For more information visit www.midships.io

# Image recommended name: forgerock-am
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
ARG IMAGE_SRC="gcr.io/massive-dynamo-235117/am-base"
FROM ${IMAGE_SRC}:${IMAGE_TAG}

# Copy over configuration scripts
# -------------------------------
USER root
COPY files/forgerock-am-shared-functions.sh ${AM_HOME}/scripts/
COPY files/init.sh ${AM_HOME}/scripts/
COPY files/server.xml ${AM_HOME}/
RUN chown -R am:am ${AM_HOME}/
RUN chmod +x ${AM_HOME}/scripts/*.sh
RUN curl https://artifactory.global.standardchartered.com/artifactory/gradle-snapshot/com/sc/cpbb/ciam/customnode/ng-ciam-fr-custom-nodes/1.0.0-SNAPSHOT/ng-ciam-fr-custom-nodes-1.0.0-SNAPSHOT-all.jar -o ${AM_HOME}/ng-ciam-fr-custom-nodes-1.0.0-SNAPSHOT-all.jar

# Backing up all the AM/Tomcat files that will be copied later into a writable folder
# -------------------------------
RUN mkdir -p /opt/temp-am/ && \
    mkdir -p /opt/temp-tomcat/ && \
    cp -R ${AM_HOME}/* /opt/temp-am/ && \
    cp -R ${TOMCAT_HOME}/* /opt/temp-tomcat/

RUN chown -R am:am /opt/temp-am/
RUN chmod +x /opt/temp-am/scripts/*.sh

USER am
EXPOSE 8443 443

ENTRYPOINT ["bash", "/opt/temp-am/scripts/init.sh"]
