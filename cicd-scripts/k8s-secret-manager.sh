#!/usr/bin/env bash
set +x
### Usage:
# sh k8s-secret-manager.sh <create/delete> <secret name> <namespace> <secret key> <secret value>

# when create/update -> confirm before proceeding # TODO: Default is to or not to update?
# when delete -> confirm # TODO

# code flow
# check secret exist
# exist
# get current
# merge with new
# confirm
# update

# not exist
# use the kubectl create secret command with file approach

action=$1
secret_name=$2
namespace=$3
secret_key=$4
secret_value=$5

function createYamlStub() {
    echo "apiVersion: v1" > secret.yaml
    echo "kind: Secret" >> secret.yaml
    echo "metadata:" >> secret.yaml
    echo "  name: $secret_name" >> secret.yaml
    echo "type: Opaque" >> secret.yaml
    echo "data:" >> secret.yaml
}

function appendKeyValueToSecretYaml() {
  if [[ -f $2 ]]; then
    echo "  $(echo $1 | tr -d '\n\r'): \"$(cat $2 | tr -d '\n\r')\"" >> secret.yaml
  else
    echo "  $1: \"$2\"" >> secret.yaml
  fi
}

function removeFile() {
  if [[ -f $1 ]]; then
    rm -f $1
    echo "Removed $1"
  fi
}

function removeSecretFilesFromWorkspace() {
  removeFile current_secrets.txt
  removeFile secret.yaml
  removeFile $secret_value
}

# Secret management starts here.
if [[ "$action" == "create" ]]; then
  createYamlStub
  # check secret exists
  if [[ $(kubectl -n ${namespace} get secrets -o name ${secret_name} --ignore-not-found=true | wc -l) -eq 1 ]]; then
    echo "Secret $secret_name exists..."
    # Retrieve existing secret and filter out current secret key:value pairs
    kubectl -n ${namespace} get secret $secret_name -o json | jq -r '.data | to_entries|map("\(.key):\(.value|tostring)")|.[]' > current_secrets.txt
    # Iterate through the retrieved secrets
    # Check if any existing secret match with given secret key to the pipeline
    # If matches, update the secret to the given new value
    # If it does not match, add a new secret key-value pair
    for line in $(cat current_secrets.txt); do
      CURRENT_KEY=$( echo $line | cut -d: -f1 )
      CURRENT_VALUE=$( echo $line | cut -d: -f2 )
      if [[ "$CURRENT_KEY" == "$secret_key" ]]; then
        echo "Updating $CURRENT_KEY with new value."
        # Given secret key matches existing secret
        # Updating the secret value
        appendKeyValueToSecretYaml $secret_key $secret_value
        # Marker for the matched secret
        # TODO: change to something more robust when supporting multiple secret secret creation at once
        touch secret_found
      else
        echo "No change to $CURRENT_KEY"
        # Adding back unmatched pre-existed secret
        appendKeyValueToSecretYaml $CURRENT_KEY $CURRENT_VALUE
      fi
    done
    # secret_found marker exists if given secret was used to update existing one
    # If the marker does not exist, add the given secret key and value - append
    if [[ ! -f secret_found ]]; then
      echo "Adding $secret_key to $secret_name"
      appendKeyValueToSecretYaml $secret_key $secret_value
    fi
  else
    echo "Secret $secret_name does not exist and will be created."
    appendKeyValueToSecretYaml $secret_key $secret_value
  fi

  # Using kubectl apply to add secret(s)
  kubectl -n ${namespace} apply -f secret.yaml
fi

if [[ "$action" == "delete" ]]; then
  echo "Delete functionality not yet implemented..."
fi

removeSecretFilesFromWorkspace
