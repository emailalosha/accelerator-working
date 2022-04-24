# ===========================================================
# COPYRIGHT 2017 MIDSHIPS
# Do not distribute without permission and this
# file is only usable with a valid license.

# Docker file to build ForgeRock User Store Directory Server
# container image.

# For more information visit www.midships.io

# Image recommended name: forgerock-user-store
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
ARG IMAGE_SRC="gcr.io/massive-dynamo-235117/forgerock-ds-base"
FROM ${IMAGE_SRC}:${IMAGE_TAG}

# Setup configuration scripts
# ---------------------------
COPY files/*.sh ${DS_SCRIPTS}/
RUN chown ds:ds ${DS_SCRIPTS}/init.sh
RUN chmod +x ${DS_SCRIPTS}/*.sh
RUN ls -ltr ${DS_SCRIPTS}/

COPY --chown=ds:ds config/schema/*.ldif  ${DS_HOME}/setupFiles/

ENTRYPOINT ["bash", "/opt/ds/scripts/init.sh"]
