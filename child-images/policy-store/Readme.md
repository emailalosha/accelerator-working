# **SUMMARY**

This folder contains the ForgeRock Directory Services `Policy Store` image for Midships IAM accelerator.

## **PREREQUISITE**

#### [[ Hashicorp Vault ]]
- Ensure the Vault is accessible from the CICD and Kubernetes cluster
- The path to this image secrets in the Vault is of the format `clients/{client-anme}/forgerock/{environment-type}/policy-store`. For instance `clients/client01/forgerock/sit/policy-store`
- The below secrets must exists in the Vault. Speak with a Midships technical consultant for clarification if you have any queries:
  - rootUserPassword
  - monitorUserPassword
  - amPolicyAdminPassword
  - policyStoreCertPwd
  - truststorePwd
  - properties
  - certificate
  - certificateKey

## **USAGE**

#### [[ Building locally ]]
TODO: Write instructions

#### [[ CICD ]]
TODO: Write instructions

## License

TODO: Write license

