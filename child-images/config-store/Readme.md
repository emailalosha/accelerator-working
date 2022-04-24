# **SUMMARY**

This folder contains the ForgeRock `Configuration Store` image for Midships ForgeRock accelerator. Used by the ForgeRock Access Management component.

## **PREREQUISITE**

#### [[ Hashicorp Vault ]]
- Ensure the Vault is accessible from the CICD and Kubernetes cluster
- The path to this image secrets in the Vault is of the format `{secrets-engine}/{environment-type}/config-store`. For instance `forgerock/sit/config-store`
- The below secrets must exists in the Vault. Speak with a Midships technical consultant for clarification if you have any queries:
  - amConfigAdminPassword
  - certificate
  - certificateKey
  - configStoreCertPwd
  - deploymentKey
  - javaProperties
  - monitorUserPassword
  - properties
  - rootUserPassword
  - truststorePwd
- Note: <br/>
  When ding replication, ensure the deploymentKey is the same for all DS instances.

## **USAGE**

#### [[ Building locally ]]
_EXAMPLE COMMANDS_
```
docker build --no-cache --build-arg IMAGE_TAG=fr7 -t forgerock-config-store .
docker tag forgerock-config-store gcr.io/massive-dynamo-235117/forgerock-config-store:fr7
docker push gcr.io/massive-dynamo-235117/forgerock-config-store:fr7
```


#### [[ CICD ]]
_EXAMPLE COMMANDS (Self Replication)_
```
helm install \
  --kubeconfig "/root/.kube/config" \
  --set configstore.image="gcr.io/massive-dynamo-235117/forgerock-config-store:fr7" \
  --set configstore.pod_name="forgerock-config-store-blue" \
  --set configstore.service_name="forgerock-config-store" \
  --set configstore.replicas="2" \
  --set configstore.cluster_domain="cluster.local" \
  --set configstore.basedn="ou=users" \
  --set configstore.load_schema="true" \
  --set configstore.load_dsconfig="false" \
  --set vault.url="http://104.197.209.36:8200" \
  --set vault.token="s.0KKo0eJy1PKgqCRZsXCrpbPa" \
  --set vault.us_path="forgerock/data/sit/config-store" \
  --set vault.rs_path="" \
  --set configstore.namespace="forgerock" \
  --set configstore.use_javaProps="false" \
  --set configstore.self_replicate="true" \
  --set configstore.rs_svc='' \
  --set configstore.env_type="SIT" \
  --set configstore.disable_insecure_comms="true" \
  --namespace forgerock \
  forgerock-config-store config-store/
```

_EXAMPLE COMMANDS (using Replication Server)_
```
helm install \
  --kubeconfig "/root/.kube/config" \
  --set configstore.image="gcr.io/massive-dynamo-235117/forgerock-config-store:fr7" \
  --set configstore.pod_name="forgerock-config-store-green" \
  --set configstore.service_name="forgerock-config-store" \
  --set configstore.replicas="2" \
  --set configstore.cluster_domain="cluster.local" \
  --set configstore.basedn="ou=users" \
  --set vault.url="http://104.197.209.36:8200" \
  --set vault.token="s.0KKo0eJy1PKgqCRZsXCrpbPa" \
  --set vault.cs_path="forgerock/data/sit/config-store" \
  --set vault.rs_path="forgerock/data/sit/repl-server" \
  --set configstore.namespace="forgerock" \
  --set configstore.use_javaProps="false" \
  --set configstore.self_replicate="false" \
  --set configstore.rs_svc='forgerock-repl-server-blue-0.forgerock-repl-server.forgerock.svc.cluster.local:8989\,forgerock-repl-server-blue-1.forgerock-repl-server.forgerock.svc.cluster.local:8989' \
  --set configstore.env_type="SIT" \
  --set configstore.disable_insecure_comms="true" \
  --namespace forgerock \
  forgerock-config-store config-store/
```
