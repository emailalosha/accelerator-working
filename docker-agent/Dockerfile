### This is to make base docker agent image with all pre-requisite ###
FROM registry.access.redhat.com/ubi8/ubi
######### Setting bash SHELL #################
SHELL [ "/bin/bash" ,"-c" ]
###########################
# COPY files/setup1.sh /opt/scripts/setup1.sh
# RUN chmod +x /opt/scripts/setup1.sh
# RUN sh /opt/scripts/setup1.sh
COPY files/setup.sh /opt/scripts/setup.sh
RUN chmod +x /opt/scripts/setup.sh
RUN sh /opt/scripts/setup.sh