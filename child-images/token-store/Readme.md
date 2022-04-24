# **SUMMARY**

This folder contains the ForgeRock `Token Store` image for Midships ForgeRock accelerator.

## **PREREQUISITE**

#### [[ Hashicorp Vault ]]
- Ensure the Vault is accessible from the CICD and Kubernetes cluster
- The path to this image secrets in the Vault is of the format `{secrets-engine}/{environment-type}/token-store`. For instance `forgerock/sit/token-store`
- The below secrets must exists in the Vault. Speak with a Midships technical consultant for clarification if you have any queries:
  - amCtsAdminPassword
  - certificate
  - certificateKey
  - deploymentKey
  - javaProperties
  - monitorUserPassword
  - properties
  - rootUserPassword
  - tokenStoreCertPwd
  - truststorePwd
- Note: <br/>
  When ding replication, ensure the deploymentKey is the same for all DS instances.

## **USAGE**

#### [[ Building locally ]]
_EXAMPLE COMMANDS_
```
docker build --no-cache --build-arg IMAGE_TAG=fr7 -t forgerock-token-store .
docker tag forgerock-token-store gcr.io/massive-dynamo-235117/forgerock-token-store:fr7
docker push gcr.io/massive-dynamo-235117/forgerock-token-store:fr7
```


#### [[ CICD ]]
_EXAMPLE COMMANDS (Self Replication)_
```
helm install \
  --kubeconfig "/root/.kube/config" \
  --set tokenstore.image="gcr.io/massive-dynamo-235117/forgerock-token-store:fr7" \
  --set tokenstore.pod_name="forgerock-token-store-blue" \
  --set tokenstore.service_name="forgerock-token-store" \
  --set tokenstore.cluster_domain="cluster.local" \
  --set tokenstore.replicas="2" \
  --set tokenstore.basedn="ou=tokens" \
  --set tokenstore.self_replicate="true" \
  --set tokenstore.use_javaProps="false" \
  --set tokenstore.env_type="SIT" \
  --set tokenstore.disable_insecure_comms="true" \
  --set vault.url="http://104.197.209.36:8200" \
  --set vault.token="s.0KKo0eJy1PKgqCRZsXCrpbPa" \
  --set vault.ts_path="forgerock/data/sit/token-store" \
  --set vault.rs_path="" \
  --set tokenstore.rs_svc='' \
  --namespace forgerock \
  forgerock-token-store token-store/
```

_EXAMPLE COMMANDS (using Replication Server)_
```
helm install \
  --kubeconfig "/root/.kube/config" \
  --set tokenstore.image="gcr.io/massive-dynamo-235117/forgerock-token-store:fr7" \
  --set tokenstore.pod_name="forgerock-token-store-green" \
  --set tokenstore.service_name="forgerock-token-store" \
  --set tokenstore.cluster_domain="cluster.local" \
  --set tokenstore.replicas="2" \
  --set tokenstore.basedn="ou=tokens" \
  --set tokenstore.self_replicate="false" \
  --set tokenstore.use_javaProps="false" \
  --set tokenstore.env_type="SIT" \
  --set tokenstore.disable_insecure_comms="true" \
  --set vault.url="http://104.197.209.36:8200" \
  --set vault.token="s.0KKo0eJy1PKgqCRZsXCrpbPa" \
  --set vault.ts_path="forgerock/data/sit/token-store" \
  --set vault.rs_path="forgerock/data/sit/repl-server" \
  --set tokenstore.rs_svc='forgerock-repl-server-blue-0.forgerock-repl-server.forgerock.svc.cluster.local:8989\,forgerock-repl-server-blue-1.forgerock-repl-server.forgerock.svc.cluster.local:8989' \
  --namespace forgerock \
  forgerock-token-store token-store/
```
