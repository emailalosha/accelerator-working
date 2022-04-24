# **SUMMARY**

This folder contains the ForgeRock `Ingress` image for Midships ForgeRock accelerator.

## **PREREQUISITE**

#### [[ Hashicorp Vault ]]
- Ensure the Vault is accessible from the CICD and Kubernetes cluster
- The path to this image secrets in the Vault is of the format `{secrets-engine}/{environment-type}/access-manager`. For instance `forgerock/sit/access-manager`
- The below secrets must exists in the Vault. Speak with a Midships technical consultant for clarification if you have any queries:
  - tomcatJKSPwd
  - amAdminPwd
  - cfgStoreDirMgrPwd
  - userStoreDirMgrPwd
  - truststorePwd
  - amPwdEncKey
  - properties
  - certificate
  - certificateKey
  - cert_es256
  - cert_es256Key
  - cert_es384
  - cert_es384Key
  - cert_es512
  - cert_es512Key
  - cert_general
  - cert_generalKey
  - cert_rsajwtsign
  - cert_rsajwtsignKey
  - cert_selfserviceenc
  - cert_selfserviceencKey
  - encKey_AmPwd
  - encKey_directenc
  - encKey_hmacsign
  - encKey_selfservicesign
- Note: <br/>
  You can also have keys with the prefix `amster_` and `autrees_` to store base64 encoded amster scripts and auth trees scripts.

## **USAGE**

#### [[ Building locally ]]
_EXAMPLE COMMANDS_
```
docker build --no-cache --build-arg IMAGE_TAG=fr7 -t forgerock-access-manager .<br/>
docker tag forgerock-access-manager gcr.io/massive-dynamo-235117/forgerock-access-manager:fr7<br/>
docker push gcr.io/massive-dynamo-235117/forgerock-access-manager:fr7
```


#### [[ CICD ]]
_EXAMPLE COMMANDS (with Config Store Self Replication)_
```
helm install \
  --kubeconfig "/root/.kube/config" \
  --set am.replicas="2" \
  --set am.pod_name="forgerock-access-manager-gcp" \
  --set am.service_name="forgerock-access-manager" \
  --set configstore.pod_name="forgerock-config-store" \
  --set configstore.use_javaProps="false" \
  --set configstore.self_replicate="true" \
  --set configstore.env_type="SIT" \
  --set configstore.cluster_domain="cluster.local" \
  --set configstore.basedn="ou=am-config" \
  --set configstore.disable_insecure_comms="false" \
  --set configstore.rs_svc='' \
  --set configstore.image="gcr.io/massive-dynamo-235117/forgerock-config-store:fr7" \
  --set am.image="gcr.io/massive-dynamo-235117/forgerock-access-manager:fr7" \
  --set vault.url="http://104.197.209.36:8200" \
  --set vault.token="s.0KKo0eJy1PKgqCRZsXCrpbPa" \
  --set vault.am_path="forgerock/data/sit/access-manager" \
  --set vault.cs_path="forgerock/data/sit/config-store" \
  --set vault.ts_path="forgerock/data/sit/token-store" \
  --set vault.us_path="forgerock/data/sit/user-store" \
  --set vault.rs_path="" \
  --set am.namespace="forgerock" \
  --set am.env_type="SIT" \
  --set am.cookie_name="iPlanetDirectoryPro" \
  --set am.lb_domain="am.d2portal.co.uk" \
  --set am.vault_client_path_runtime_am="forgerock/data/sit/runtime/access-manager" \
  --set am.cs_k8s_svc_url="cs.forgerock-access-manager.forgerock.svc.cluster.local" \
  --set am.us_k8s_svc_url="forgerock-user-store.forgerock.svc.cluster.local" \
  --set am.ts_k8s_svc_url="forgerock-token-store.forgerock.svc.cluster.local" \
  --set am.goto_urls='"https://url1.com/*"' \
  --set am.us_connstring_affinity='"forgerock-user-store-gcp-0.forgerock-user-store.forgerock.svc.cluster.local:1636"\,"forgerock-user-store-gcp-1.forgerock-user-store.forgerock.svc.cluster.local:1636"' \
  --set am.ps_connstring_affinity='forgerock-policy-store.forgerock.svc.cluster.local:1636' \
  --set am.ts_connstring_affinity='forgerock-token-store-gcp-0.forgerock-token-store.forgerock.svc.cluster.local:1636\,forgerock-token-store-gcp-1.forgerock-token-store.forgerock.svc.cluster.local:1636' \
  --set am.amster_files="amster_DefaultCtsDataStoreProperties\,amster_DefaultSecurityProperties\,amster_platform\,amster_AuthenticationGlobal\,amster_IdStore_OpenDJ\,amster_realm_customers\,amster_realm_internals" \
  --set am.auth_trees="authTrees_customers_register\,authTrees_customers_stepup\,authTrees_customers_login" \
  --namespace forgerock \
  forgerock-access-manager access-manager/
```
