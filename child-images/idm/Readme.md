# **SUMMARY**

This folder contains the ForgeRock `IDM` image for Midships ForgeRock accelerator.

## **PREREQUISITE**

#### [[ Secrets Manager ]]
- Ensure the Secrets Manager is accessible from the CICD and Kubernetes cluster as required
- The path to this image secrets in the Vault is of the format `{secrets-engine}/{environment-type}/idm`. For instance `forgerock/sit/idm`
- The below secrets must exists in the Vault. Speak with a Midships technical consultant for clarification if you have any queries:
  - dsBindDNpwd
  - certificate
  - certificateKey

## **USAGE**

#### [[ Building locally ]]
_EXAMPLE COMMANDS_
```
docker build --no-cache --build-arg IMAGE_TAG=fr7 -t forgerock-idm .
docker tag forgerock-config-store gcr.io/massive-dynamo-235117/forgerock-config-store:fr7
docker push gcr.io/massive-dynamo-235117/forgerock-config-store:fr7
```


#### [[ CICD/Deployment ]]
_EXAMPLE COMMANDS_
```
helm install \
  --kubeconfig "/root/.kube/config" \
  --set idm.image="gcr.io/massive-dynamo-235117/forgerock-idm:fr7" \
  --set idm.pod_name="forgerock-idm" \
  --set idm.service_name="forgerock-idm" \
  --set idm.secrets_mode="k8s" \
  --set idm.replicas="2" \
  --set idm.ds_bind_dn="ou=users" \
  --set idm.ds_hostname_primary="forgerock-user-store-0.forgerock-user-store.forgerock.svc.cluster.local" \
  --set idm.ds_hostname_secondary="forgerock-user-store-1.forgerock-user-store.forgerock.svc.cluster.local" \
  --set vault.url="https://midships-vault.vault.6ab12ea5-c7af-456f-81b5-e0aaa5c9df5e.aws.hashicorp.cloud:8200" \
  --set vault.token="s.lvsd4kRuQmUfwY3m4glZ19km.MV86d" \
  --set vault.idm_path="forgerock/data/sit/idm" \
  --set idm.namespace="forgerock" \
  --set idm.ds_port=1636 \
  --set idm.idm_profile="ds" \
  --set idm.env_type="SIT" \
  --set idm.secrets_mode="k8s" \
  --namespace forgerock \
  forgerock-idm idm/
  forgerock-config-store config-store/
```
