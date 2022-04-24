echo "We are good to start..."
yum -y install openssl openssh-server curl unzip jq sed iputils hostname;
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# yum makecache 
yum install docker-ce docker-ce-cli containerd.io -y
echo "You cannot start docker service until/unless system is up, this is just image setup...."
# systemctl start docker
echo "Below command also doesnt make any sense..."
# docker run hello-world
echo "About to enable docker service..."
systemctl enable docker
echo "Below command also doesnt make sense as system needs to be UP..."
# systemctl status docker
echo "About to find docker version..."
docker version
####### Now lets install kubernetes ###################
echo "About to install kebectl...."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
######################
echo "About to install helm...."
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
sh get_helm.sh
#########################
echo "About to install aws-cli...."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
#### to run as container
