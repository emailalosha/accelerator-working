# **SUMMARY**

This folder contains the ForgeRock `Replication Server` image for Midships ForgeRock accelerator.

## **PREREQUISITE**

#### [[ Hashicorp Vault ]]
- Ensure the Vault is accessible from the CICD and Kubernetes cluster
- The path to this image secrets in the Vault is of the format `{secrets-engine}/{environment-type}/repl-server`. For instance `forgerock/sit/repl-server`
- The below secrets must exists in the Vault. Speak with a Midships technical consultant for clarification if you have any queries:
  - certificate
  - certificateKey
  - deploymentKey
  - javaProperties
  - keystorePwd
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
docker build --build-arg IMAGE_TAG=fr7 --no-cache -t forgerock-repl-server .
docker tag forgerock-repl-server gcr.io/massive-dynamo-235117/forgerock-repl-server:fr7
docker push gcr.io/massive-dynamo-235117/forgerock-repl-server:fr7
```


#### [[ CICD ]]
_EXAMPLE COMMANDS (Cluster only Replication)_
```
helm install \
  --kubeconfig "/root/.kube/config" \
  --set replserver.image="gcr.io/massive-dynamo-235117/forgerock-repl-server:fr7" \
  --set replserver.pod_name="forgerock-repl-server-blue" \
  --set replserver.service_name="forgerock-repl-server" \
  --set replserver.cluster_domain="cluster.local" \
  --set replserver.replicas="2" \
  --set replserver.basedn_to_repl_us="ou=users" \
  --set replserver.basedn_to_repl_ts="ou=tokens" \
  --set replserver.basedn_to_repl_cs="ou=am-config" \
  --set replserver.srvs_to_repl_us="forgerock-user-store-gcp-0.forgerock-user-store.forgerock.svc.cluster.local\,forgerock-user-store-gcp-1.forgerock-user-store.forgerock.svc.cluster.local" \
  --set replserver.srvs_to_repl_ts="forgerock-token-store-gcp-0.forgerock-token-store.forgerock.svc.cluster.local\,forgerock-token-store-gcp-1.forgerock-token-store.forgerock.svc.cluster.local" \
  --set replserver.srvs_to_repl_cs="forgerock-access-manager-gcp-0.forgerock-access-manager.forgerock.svc.cluster.local\,forgerock-access-manager-gcp-1.forgerock-access-manager.forgerock.svc.cluster.local" \
  --set replserver.env_type="SIT" \
  --set replserver.use_javaProps="false" \
  --set replserver.global_repl_on="false" \
  --set replserver.global_repl_fqdns="" \
  --set vault.url="http://104.197.209.36:8200" \
  --set vault.token="s.0KKo0eJy1PKgqCRZsXCrpbPa" \
  --set vault.rs_path="forgerock/data/sit/repl-server" \
  --set vault.us_path="forgerock/data/sit/user-store" \
  --set vault.ts_path="forgerock/data/sit/token-store" \
  --set vault.cs_path="forgerock/data/sit/config-store" \
  --namespace forgerock \
  forgerock-repl-server repl-server/
```

_EXAMPLE COMMANDS (Global Replication : Multi-cluster Replication)_
```
helm install \
  --kubeconfig "/root/.kube/config" \
  --set replserver.image="gcr.io/massive-dynamo-235117/forgerock-repl-server:fr7" \
  --set replserver.pod_name="forgerock-repl-server-green" \
  --set replserver.service_name="forgerock-repl-server" \
  --set replserver.cluster_domain="cluster.local" \
  --set replserver.replicas="2" \
  --set replserver.basedn_to_repl_us="ou=users" \
  --set replserver.basedn_to_repl_ts="ou=tokens" \
  --set replserver.basedn_to_repl_cs="ou=am-config" \
  --set replserver.srvs_to_repl_us="forgerock-user-store-gcp-0.forgerock-user-store.forgerock.svc.cluster.local\,forgerock-user-store-gcp-1.forgerock-user-store.forgerock.svc.cluster.local" \
  --set replserver.srvs_to_repl_ts="forgerock-token-store-gcp-0.forgerock-token-store.forgerock.svc.cluster.local\,forgerock-token-store-gcp-1.forgerock-token-store.forgerock.svc.cluster.local" \
  --set replserver.srvs_to_repl_cs="forgerock-access-manager-gcp-0.forgerock-access-manager.forgerock.svc.cluster.local\,forgerock-access-manager-gcp-1.forgerock-access-manager.forgerock.svc.cluster.local" \
  --set replserver.env_type="SIT" \
  --set replserver.use_javaProps="false" \
  --set replserver.global_repl_on="true" \
  --set replserver.global_repl_fqdns="europe-north-1A.forgerock-repl-server.forgerock.svc.cluster.local\,europe-north-1B.forgerock-repl-server.forgerock.svc.cluster.local" \
  --set vault.url="http://104.197.209.36:8200" \
  --set vault.token="s.0KKo0eJy1PKgqCRZsXCrpbPa" \
  --set vault.rs_path="forgerock/data/sit/repl-server" \
  --set vault.us_path="forgerock/data/sit/user-store" \
  --set vault.ts_path="forgerock/data/sit/token-store" \
  --set vault.cs_path="forgerock/data/sit/config-store" \
  --namespace forgerock \
  forgerock-repl-server repl-server/
```
