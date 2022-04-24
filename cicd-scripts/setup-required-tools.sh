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

apk update && apk add curl bash wget tar python py-pip
# Install kubectl
curl -L https://storage.googleapis.com/kubernetes-release/release/v1.15.1/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl
chmod u+x /usr/local/bin/kubectl 
mkdir -p $HOME/.kube/
echo ${FR_KUBE_CONFIG} | base64 -d > $HOME/.kube/config
chmod 600 $HOME/.kube/config
# Install helm
export VERIFY_CHECKSUM=false
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | /bin/bash
helm version
cd $HOME

echo "The K8S_LOCATION is set to ${K8S_LOCATION}"
if [ "${K8S_LOCATION}" == "gcp" ]; then
    echo "Download and install Google Cloud SDK"
    wget https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz    
    tar zxvf google-cloud-sdk.tar.gz
    ./google-cloud-sdk/install.sh --usage-reporting=false --path-update=true
    google-cloud-sdk/bin/gcloud --quiet components update
    echo "GCLOUD installed at $(google-cloud-sdk/bin/gcloud info --format="value(installation.sdk_root)")"
    echo "${GCP_SERVICE_KEY}" | base64 -d  >> ${HOME}/gcloud-service-key.json
    google-cloud-sdk/bin/gcloud auth activate-service-account --key-file ${HOME}/gcloud-service-key.json    
    #${gcloudPath}/bin/gcloud container clusters get-credentials ${GCP_CLUSTER_NAME} --zone ${GCP_ZONE} --project $GCP_PROJECTID
    echo ""
elif [ "${K8S_LOCATION}" == "aws" ]; then
    echo "Download and install AWS CLI"
    pip install awscli
    aws --version
    aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
    aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
fi
