# **SUMMARY**

This folder contains copies of the various client configuration stored in a Secrets Manager, required to use the Midships ForgeRock Accelerator. At present includes the export of the configuration for the below components:
- Access Manager
- Configuration Store
- User Store
- Token Store
- Replication Server
- Policy Store

#### [[ Hashicorp Vault ]]
The `hashicorp-valut` folder contains the export of secrets for a Hashicorp Vault secrets manager.


## **USAGE**

#### `post-deploy.sh`
_This script can be used to do creae a Secrets Engine in a Hashicorp Vault instance as well as add or updae secrets under the created Secrets Engine. Below is a summary of the parameters:_
- `${1}`  Script action. Can be:
  - `init` to initialize a Hashicorp Vault
  - `create-se` to create KV2 Secrets Engine
  - `add-secrets` add secrets to Hashicorp Vault Secrets Store
  - `del-secrets` to delete secrets from the Hashicorp Vault
- `${2}` The Hashicorp Vault URL
- `${3}` The Hashicorp Vault Token
- `${4}` The Name of the KV Secrets Engine to be created in the Vault
- `${5}` The ForgeRock Access Manafger Load Balancer domain name
- `${6}` A string of the Environment Type. For instance `DEV`, `SIT`, etc.
- `${7}` The namespace of the deployment in the Kubernetes cluster the ForgeRock Solution will be deployed inetOrgPerson
- `${8}` A `yes` or `no` string to decide if to add the Client Name to the secrets path. See script for details.
- `${9}` The Client name, ony used where you have multiple clients/customer saving to the same Vault Secrets Store
- `${10}` A `yes` or `no` string to decide if certificates show be regenerated

**SAMPLE For Creating A Secrets Engine called `forgerock`**
```
./post-deploy.sh \
create-se \
"https://midships-vault.vault.6ab12ea5-c7af-456f-81b5-e0aaa5c9df5e.aws.hashicorp.cloud:8200" \
"s.bLPQRSnS8Ht1rV9f00LfmZoO.MV86d" \
forgerock \
"am.d2portal.co.uk" \
sit \
forgerock \
no \
"" \
yes
```

**SAMPLE For Adding Secrets for `SIT` environment**
```
./post-deploy.sh \
add-secrets \
"https://midships-vault.vault.6ab12ea5-c7af-456f-81b5-e0aaa5c9df5e.aws.hashicorp.cloud:8200" \
"s.bLPQRSnS8Ht1rV9f00LfmZoO.MV86d" \
forgerock \
"am.d2portal.co.uk" \
SIT \
forgerock \
no \
"" \
no
```
