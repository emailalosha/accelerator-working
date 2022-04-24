# **SUMMARY**

This folder contains the ForgeRock `User Store` image for Midships ForgeRock accelerator.

## **PREREQUISITE**

#### [[ Hashicorp Vault ]]
- Ensure the Vault is accessible from the CICD and Kubernetes cluster
- The path to this image secrets in the Vault is of the format `{secrets-engine}/{environment-type}/user-store`. For instance `forgerock/sit/user-store`
- The below secrets must exists in the Vault. Speak with a Midships technical consultant for clarification if you have any queries:
  - amIdentityStoreAdminPassword
  - certificate
  - certificateKey
  - deploymentKey
  - file_dsconfig
  - file_schema
  - javaProperties
  - monitorUserPassword
  - properties
  - rootUserPassword
  - truststorePwd
  - userStoreCertPwd
- Note: <br/>
  When ding replication, ensure the deploymentKey is the same for all DS instances.

## **USAGE**

#### [[ Building locally ]]
_EXAMPLE COMMANDS_
```
docker build --no-cache --build-arg IMAGE_TAG=fr7 -t forgerock-user-store .
docker tag forgerock-user-store gcr.io/massive-dynamo-235117/forgerock-user-store:fr7
docker push gcr.io/massive-dynamo-235117/forgerock-user-store:fr7
```


#### [[ CICD ]]
_EXAMPLE COMMANDS (Self Replication)_
```
helm install \
  --kubeconfig "/root/.kube/config" \
  --set userstore.image="gcr.io/massive-dynamo-235117/forgerock-user-store:fr7" \
  --set userstore.pod_name="forgerock-user-store-blue" \
  --set userstore.service_name="forgerock-user-store" \
  --set userstore.replicas="2" \
  --set userstore.cluster_domain="cluster.local" \
  --set userstore.basedn="ou=users" \
  --set userstore.load_schema="true" \
  --set userstore.load_dsconfig="false" \
  --set vault.url="http://104.197.209.36:8200" \
  --set vault.token="s.0KKo0eJy1PKgqCRZsXCrpbPa" \
  --set vault.us_path="forgerock/data/sit/user-store" \
  --set vault.rs_path="" \
  --set userstore.namespace="forgerock" \
  --set userstore.use_javaProps="false" \
  --set userstore.self_replicate="true" \
  --set userstore.rs_svc='' \
  --set userstore.env_type="SIT" \
  --set userstore.disable_insecure_comms="true" \
  --namespace forgerock \
  forgerock-user-store user-store/
```

_EXAMPLE COMMANDS (using Replication Server)_
```
helm install \
  --kubeconfig "/root/.kube/config" \
  --set userstore.image="gcr.io/massive-dynamo-235117/forgerock-user-store:fr7" \
  --set userstore.pod_name="forgerock-user-store-green" \
  --set userstore.service_name="forgerock-user-store" \
  --set userstore.replicas="2" \
  --set userstore.cluster_domain="cluster.local" \
  --set userstore.basedn="ou=users" \
  --set userstore.load_schema="true" \
  --set userstore.load_dsconfig="true" \
  --set vault.url="http://104.197.209.36:8200" \
  --set vault.token="s.0KKo0eJy1PKgqCRZsXCrpbPa" \
  --set vault.us_path="forgerock/data/sit/user-store" \
  --set vault.rs_path="forgerock/data/sit/repl-server" \
  --set userstore.namespace="forgerock" \
  --set userstore.use_javaProps="false" \
  --set userstore.self_replicate="false" \
  --set userstore.rs_svc='forgerock-repl-server-blue-0.forgerock-repl-server.forgerock.svc.cluster.local:8989\,forgerock-repl-server-blue-1.forgerock-repl-server.forgerock.svc.cluster.local:8989' \
  --set userstore.env_type="SIT" \
  --set userstore.disable_insecure_comms="true" \
  --namespace forgerock \
  forgerock-user-store user-store/
```
