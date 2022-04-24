#!/bin/bash
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
# ****************************************************************************

deployIDM="${DEPLOY_IDM}"
cs_sidecar_mode="${CS_SIDECAR_MODE}"
secrets_mode="${SECRETS_MODE}"
VAULT_BASE_URL="${VAULT_BASE_URL}"
VAULT_TOKEN="${VAULT_TOKEN}"
DEPLOY_RS="${DEPLOY_RS}"
DEPLOY_TS="${DEPLOY_TS}"
DEPLOY_US="${DEPLOY_US}"
DEPLOY_AM="${DEPLOY_AM}"
DEPLOY_INGRESS="${DEPLOY_INGRESS}"

echo "Deployment parameter deployIDM is ${deployIDM}"
echo "Deployment parameter cs_sidecar_mode is ${cs_sidecar_mode}"
echo "Deployment parameter secrets_mode is ${secrets_mode}"
echo "Deployment parameter VAULT_BASE_URL is ${VAULT_BASE_URL}"
echo "Deployment parameter VAULT_TOKEN is ${VAULT_TOKEN}"
echo "Deployment parameter REPLSERVER_VAULT_PATH is ${REPLSERVER_VAULT_PATH}"
echo "Deployment parameter USERSTORE_VAULT_PATH is ${USERSTORE_VAULT_PATH}"
echo "Deployment parameter TOKENSTORE_VAULT_PATH is ${TOKENSTORE_VAULT_PATH}"
echo "Deployment parameter CONFIGSTORE_VAULT_PATH is ${CONFIGSTORE_VAULT_PATH}"
echo "Deployment parameter PODNAME_RS is ${PODNAME_RS}"
echo "Deployment parameter DEPLOY_RS is ${DEPLOY_RS}"
echo "Deployment parameter DEPLOY_TS is ${DEPLOY_TS}"
echo "Deployment parameter DEPLOY_US is ${DEPLOY_US}"
echo "Deployment parameter DEPLOY_AM is ${DEPLOY_AM}"

if [ "${cs_sidecar_mode,,}" == "true" ]; then
  svcFQDN_CS="localhost"
else
  svcFQDN_CS="forgerock-config-store.${NAMESPACE}.svc.cluster.local"
fi

if [ "${DEPLOY_RS,,}" == "true" ]; then
  echo "-> Installing Replication Server"
  echo "   Will wait for it to be ready before installing next components (User and Token Stores)"
  helm upgrade --install --wait --timeout 10m0s \
    --set replserver.image="${CI_REGISTRY_URL}/repl-server:${DEPLOY_IMAGES_TAG}" \
    --set replserver.pod_name="$PODNAME_RS" \
    --set replserver.service_name="$SERVICENAME_RS" \
    --set replserver.cluster_domain="cluster.local" \
    --set replserver.replicas="1" \
    --set replserver.env_type="$ENV_TYPE" \
    --set replserver.use_javaProps="false" \
    --set replserver.global_repl_on="false" \
    --set replserver.global_repl_fqdns="europe-north-1A.forgerock-repl-server.'"${NAMESPACE}"'.svc.cluster.local\,europe-north-1B.forgerock-repl-server.'"${NAMESPACE}"'.svc.cluster.local" \
    --set vault.url="${VAULT_BASE_URL}" \
    --set vault.token="${VAULT_TOKEN}" \
    --set vault.rs_path="${REPLSERVER_VAULT_PATH}" \
    --set vault.us_path="${USERSTORE_VAULT_PATH}" \
    --set vault.ts_path="${TOKENSTORE_VAULT_PATH}" \
    --set vault.cs_path="${CONFIGSTORE_VAULT_PATH}" \
    --set configstore.pod_name="$PODNAME_CS" \
    --set userstore.pod_name="$PODNAME_US" \
    --set tokenstore.pod_name="$PODNAME_TS" \
    --set replserver.secrets_mode="${secrets_mode}" \
    --namespace "$NAMESPACE" \
    $PODNAME_RS child-images/repl-server/
  echo "-- Done"
  echo ""

  echo "-> Manually scaling Replication Server."
  echo "   Only one RS is required to intall reset of DS components"
  kubectl scale statefulsets $PODNAME_RS --replicas=$DS_REPLICAS_RS -n "$NAMESPACE"
  echo "-- Done"
  echo ""
fi

if [ "${DEPLOY_TS,,}" == "true" ]; then
  echo "-> Installing Token Store"
  helm upgrade --install \
    --set tokenstore.image="${CI_REGISTRY_URL}/token-store:${DEPLOY_IMAGES_TAG}" \
    --set tokenstore.service_name="$SERVICENAME_TS" \
    --set tokenstore.pod_name="$PODNAME_TS" \
    --set replserver.pod_name="$PODNAME_RS" \
    --set tokenstore.secrets_mode="${secrets_mode}" \
    --set tokenstore.cluster_domain="cluster.local" \
    --set tokenstore.replicas="$DS_REPLICAS_TS" \
    --set tokenstore.basedn="ou=tokens" \
    --set tokenstore.self_replicate="false" \
    --set tokenstore.use_javaProps="false" \
    --set tokenstore.env_type="$ENV_TYPE" \
    --set tokenstore.disable_insecure_comms="true" \
    --set vault.url="${VAULT_BASE_URL}" \
    --set vault.token="${VAULT_TOKEN}" \
    --set vault.ts_path="${TOKENSTORE_VAULT_PATH}" \
    --set vault.rs_path="${REPLSERVER_VAULT_PATH}" \
    --set tokenstore.rs_svc='forgerock-repl-server-0.forgerock-repl-server.'"${NAMESPACE}"'.svc.cluster.local:8989\,forgerock-repl-server-1.forgerock-repl-server.'"${NAMESPACE}"'.svc.cluster.local:8989' \
    --namespace "$NAMESPACE" \
    $PODNAME_TS child-images/token-store/
  echo "-- Done"
  echo ""
fi

if [ "${cs_sidecar_mode,,}" == "false" ]; then
  echo "-> Installing Config Store"
  helm upgrade --install \
    --set configstore.image="${CI_REGISTRY_URL}/config-store:${DEPLOY_IMAGES_TAG}" \
    --set configstore.pod_name="${PODNAME_CS}" \
    --set replserver.pod_name="$PODNAME_RS" \
    --set configstore.secrets_mode="${secrets_mode}" \
    --set configstore.sidecar_mode="${cs_sidecar_mode}" \
    --set configstore.service_name="forgerock-config-store" \
    --set configstore.replicas="${DS_REPLICAS_CS}" \
    --set configstore.cluster_domain="cluster.local" \
    --set configstore.basedn="ou=am-config" \
    --set vault.url="${VAULT_BASE_URL}" \
    --set vault.token="${VAULT_TOKEN}" \
    --set vault.cs_path="${CONFIGSTORE_VAULT_PATH}" \
    --set vault.rs_path="${REPLSERVER_VAULT_PATH}" \
    --set configstore.namespace="$NAMESPACE" \
    --set configstore.use_javaProps="false" \
    --set configstore.self_replicate="false" \
    --set configstore.rs_svc='forgerock-repl-server-0.forgerock-repl-server.'"${NAMESPACE}"'.svc.cluster.local:8989\,forgerock-repl-server-1.forgerock-repl-server.'"${NAMESPACE}"'.svc.cluster.local:8989' \
    --set configstore.env_type="$ENV_TYPE" \
    --set configstore.disable_insecure_comms="true" \
    --namespace "${NAMESPACE}" \
    forgerock-config-store child-images/config-store/
  echo "-- Done"
  echo ""
fi

if [ "${DEPLOY_US,,}" == "true" ]; then
  echo "-> Installing User Store"
  echo "   Will wait for it to be ready before installing next component (Access Manager)"
  helm upgrade --install --wait --timeout 10m0s \
    --set userstore.image="${CI_REGISTRY_URL}/user-store:${DEPLOY_IMAGES_TAG}" \
    --set userstore.pod_name="$PODNAME_US" \
    --set userstore.service_name="$SERVICENAME_US" \
    --set replserver.pod_name="$PODNAME_RS" \
    --set userstore.secrets_mode="${secrets_mode}" \
    --set userstore.replicas="1" \
    --set userstore.cluster_domain="cluster.local" \
    --set userstore.basedn="ou=users" \
    --set userstore.load_schema="$USERSTORE_LOAD_SCHEMA" \
    --set userstore.load_dsconfig="$USERSTORE_LOAD_DSCONFIG" \
    --set vault.url="${VAULT_BASE_URL}" \
    --set vault.token="${VAULT_TOKEN}" \
    --set vault.us_path="${USERSTORE_VAULT_PATH}" \
    --set vault.rs_path="${REPLSERVER_VAULT_PATH}" \
    --set userstore.namespace="${NAMESPACE}" \
    --set userstore.use_javaProps="false" \
    --set userstore.self_replicate="false" \
    --set userstore.add_idm_repo="${deployIDM}" \
    --set userstore.rs_svc='forgerock-repl-server-0.forgerock-repl-server.'"${NAMESPACE}"'.svc.cluster.local:8989\,forgerock-repl-server-1.forgerock-repl-server.'"${NAMESPACE}"'.svc.cluster.local:8989' \
    --set userstore.env_type="$ENV_TYPE" \
    --set userstore.disable_insecure_comms="true" \
    --namespace "$NAMESPACE" \
    $PODNAME_US child-images/user-store/
  echo "-- Done"
  echo ""

  echo "-> Manually scaling User Store"
  echo "   Only one US and TS is required to intall Access Manager"
  kubectl scale statefulsets $PODNAME_US --replicas=$DS_REPLICAS_US -n "$NAMESPACE"
  echo "-- Done"
  echo ""
fi

if [ "${deployIDM,,}" == "true" ]; then
  echo "-> Installing IDM"
  helm upgrade --install \
    --set idm.image="${CI_REGISTRY_URL}/idm:${DEPLOY_IMAGES_TAG}" \
    --set idm.pod_name="$PODNAME_IDM" \
    --set userstore.pod_name="$PODNAME_US" \
    --set idm.service_name="$SERVICENAME_IDM" \
    --set idm.secrets_mode="${secrets_mode}" \
    --set idm.replicas="$IDM_REPLICAS" \
    --set idm.ds_hostname_primary="$PODNAME_US-0.forgerock-user-store."${NAMESPACE}".svc.cluster.local" \
    --set idm.ds_hostname_secondary="$PODNAME_US-1.forgerock-user-store."${NAMESPACE}".svc.cluster.local" \
    --set idm.namespace="${NAMESPACE}" \
    --set idm.idm_profile="ds" \
    --set idm.env_type="fr7" \
    --set vault.url="${VAULT_BASE_URL}" \
    --set vault.token="${VAULT_TOKEN}" \
    --set vault.idm_path="${IDM_VAULT_PATH}" \
    --namespace "$NAMESPACE" \
    $PODNAME_IDM child-images/idm/
  echo "-- Done"
  echo ""
fi


if [ "${DEPLOY_AM,,}" == "true" ]; then
  echo "-> Installing Access Manager"
  helm upgrade --install \
    --set am.replicas="$AM_REPLICAS" \
    --set am.pod_name="$PODNAME_AM" \
    --set am.service_name="$SERVICENAME_AM" \
    --set configstore.pod_name="$PODNAME_CS" \
    --set configstore.use_javaProps="false" \
    --set configstore.self_replicate="true" \
    --set configstore.env_type="$ENV_TYPE" \
    --set configstore.cluster_domain="cluster.local" \
    --set configstore.basedn="ou=am-config" \
    --set configstore.disable_insecure_comms="false" \
    --set configstore.rs_svc='' \
    --set am.secrets_mode="${secrets_mode}" \
    --set am.cs_sidecar_mode="${cs_sidecar_mode}" \
    --set userstore.pod_name="$PODNAME_US" \
    --set tokenstore.pod_name="$PODNAME_TS" \
    --set replserver.pod_name="$PODNAME_RS" \
    --set configstore.image="${CI_REGISTRY_URL}/config-store:${DEPLOY_IMAGES_TAG}" \
    --set am.image="${CI_REGISTRY_URL}/openam:${DEPLOY_IMAGES_TAG}" \
    --set vault.url="${VAULT_BASE_URL}" \
    --set vault.token="${VAULT_TOKEN}" \
    --set vault.am_path="${AM_VAULT_PATH}" \
    --set vault.cs_path="${CONFIGSTORE_VAULT_PATH}" \
    --set vault.ts_path="${TOKENSTORE_VAULT_PATH}" \
    --set vault.us_path="${USERSTORE_VAULT_PATH}" \
    --set vault.rs_path="${REPLSERVER_VAULT_PATH}" \
    --set am.namespace="$NAMESPACE" \
    --set am.env_type="$ENV_TYPE" \
    --set am.cookie_name="$AM_COOKIE_NAME" \
    --set am.lb_domain="$AM_LB_DOMAIN" \
    --set am.vault_client_path_runtime_am="${AM_VAULT_RUNTIME_PATH}" \
    --set am.cs_k8s_svc_url="${svcFQDN_CS}" \
    --set am.us_k8s_svc_url="forgerock-user-store."${NAMESPACE}".svc.cluster.local" \
    --set am.ts_k8s_svc_url="forgerock-token-store."${NAMESPACE}".svc.cluster.local" \
    --set am.goto_urls='"https://url1.com/*"' \
    --set am.us_connstring_affinity='"forgerock-user-store-0.forgerock-user-store.'"${NAMESPACE}"'.svc.cluster.local:1636"\,"forgerock-user-store-1.forgerock-user-store.'"${NAMESPACE}"'.svc.cluster.local:1636"' \
    --set am.ps_connstring_affinity='forgerock-policy-store.'"${NAMESPACE}"'.svc.cluster.local:1636' \
    --set am.ts_connstring_affinity='forgerock-token-store-0.forgerock-token-store.'"${NAMESPACE}"'.svc.cluster.local:1636\,forgerock-token-store-1.forgerock-token-store.'"${NAMESPACE}"'.svc.cluster.local:1636' \
    --set am.amster_files='amster_global_advanced_properties\,amster_global_default_advanced_properties\,amster_global_session\,amster_realms\,amster_scripting_engine_configuration_oauth_oidc\,amster_sg_external_oauth2clients\,amster_sg_external_oauth2provider\,amster_sg_external_policies\,amster_sg_external_scripts\,amster_sg_external_webhookservice\,amster_sg_internal_oauth2clients\,amster_sg_internal_oauth2provider' \
    --set am.auth_trees='sg-external_subtree-sms-otp.json\,sg-external_activate-soft-token-test.json\,sg-external_register-soft-token-test.json\,sg-external_2fa-login.json\,sg-external_customer-login.json\,sg-external_customer-login-test.json\,sg-external_customer-logout.json\,sg-external_customer-registration.json\,sg-external_login-encryption.json\,sg-external_otp-test.json\,sg-external_register-soft-token.json\,sg-external_test-login.json' \
    --set am.update_all_authenticated_users_realms='sg-external\,sg-internal' \
    --namespace "$NAMESPACE" \
    $PODNAME_AM child-images/access-manager/
  echo "-- Done"
  echo ""
fi





if [ "${DEPLOY_INGRESS,,}" == "true" ]; then
  echo "-> Deploying Ingress"
  helm upgrade --install \
    --set am.service_name="$SERVICENAME_AM" \
    --set am.namespace="$NAMESPACE" \
    --set am.env_type="$ENV_TYPE" \
    --set certificate_arn="$certificate_arn" \
    --namespace "$NAMESPACE" \
    $PODNAME_INGRESS child-images/ingress/
  echo "-- Done"
  echo ""
fi