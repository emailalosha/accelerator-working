#!/bin/bash
#
# shell script which will export an AM authentication tree to standard output and re-import
# from standard input (optionally renaming the tree).
#
# Uncomment the following line for debug:
# set -x

OOTBNODETYPES_6=( "AbstractSocialAuthLoginNode" "AccountLockoutNode" "AgentDataStoreDecisionNode" "AnonymousUserNode" "AuthLevelDecisionNode" "ChoiceCollectorNode" "CookiePresenceDecisionNode" "CreatePasswordNode" "DataStoreDecisionNode" "InnerTreeEvaluatorNode" "LdapDecisionNode" "MessageNode" "MetadataNode" "MeterNode" "ModifyAuthLevelNode" "OneTimePasswordCollectorDecisionNode" "OneTimePasswordGeneratorNode" "OneTimePasswordSmsSenderNode" "OneTimePasswordSmtpSenderNode" "PageNode" "PasswordCollectorNode" "PersistentCookieDecisionNode" "PollingWaitNode" "ProvisionDynamicAccountNode" "ProvisionIdmAccountNode" "PushAuthenticationSenderNode" "PushResultVerifierNode" "RecoveryCodeCollectorDecisionNode" "RecoveryCodeDisplayNode" "RegisterLogoutWebhookNode" "RemoveSessionPropertiesNode" "RetryLimitDecisionNode" "ScriptedDecisionNode" "SessionDataNode" "SetFailureUrlNode" "SetPersistentCookieNode" "SetSessionPropertiesNode" "SetSuccessUrlNode" "SocialFacebookNode" "SocialGoogleNode" "SocialNode" "SocialOAuthIgnoreProfileNode" "SocialOpenIdConnectNode" "TimerStartNode" "TimerStopNode" "UsernameCollectorNode" "WebAuthnAuthenticationNode" "WebAuthnRegistrationNode" "ZeroPageLoginNode" )
OOTBNODETYPES_6_5=( "AbstractSocialAuthLoginNode" "AccountLockoutNode" "AgentDataStoreDecisionNode" "AnonymousUserNode" "AuthLevelDecisionNode" "ChoiceCollectorNode" "CookiePresenceDecisionNode" "CreatePasswordNode" "DataStoreDecisionNode" "InnerTreeEvaluatorNode" "LdapDecisionNode" "MessageNode" "MetadataNode" "MeterNode" "ModifyAuthLevelNode" "OneTimePasswordCollectorDecisionNode" "OneTimePasswordGeneratorNode" "OneTimePasswordSmsSenderNode" "OneTimePasswordSmtpSenderNode" "PageNode" "PasswordCollectorNode" "PersistentCookieDecisionNode" "PollingWaitNode" "ProvisionDynamicAccountNode" "ProvisionIdmAccountNode" "PushAuthenticationSenderNode" "PushResultVerifierNode" "RecoveryCodeCollectorDecisionNode" "RecoveryCodeDisplayNode" "RegisterLogoutWebhookNode" "RemoveSessionPropertiesNode" "RetryLimitDecisionNode" "ScriptedDecisionNode" "SessionDataNode" "SetFailureUrlNode" "SetPersistentCookieNode" "SetSessionPropertiesNode" "SetSuccessUrlNode" "SocialFacebookNode" "SocialGoogleNode" "SocialNode" "SocialOAuthIgnoreProfileNode" "SocialOpenIdConnectNode" "TimerStartNode" "TimerStopNode" "UsernameCollectorNode" "WebAuthnAuthenticationNode" "WebAuthnRegistrationNode" "ZeroPageLoginNode" )
OOTBNODETYPES_7=( "AcceptTermsAndConditionsNode" "AccountActiveDecisionNode" "AccountLockoutNode" "AgentDataStoreDecisionNode" "AnonymousSessionUpgradeNode" "AnonymousUserNode" "AttributeCollectorNode" "AttributePresentDecisionNode" "AttributeValueDecisionNode" "AuthLevelDecisionNode" "ChoiceCollectorNode" "ConsentNode" "CookiePresenceDecisionNode" "CreateObjectNode" "CreatePasswordNode" "DataStoreDecisionNode" "DeviceGeoFencingNode" "DeviceLocationMatchNode" "DeviceMatchNode" "DeviceProfileCollectorNode" "DeviceSaveNode" "DeviceTamperingVerificationNode" "DisplayUserNameNode" "EmailSuspendNode" "EmailTemplateNode" "IdentifyExistingUserNode" "IncrementLoginCountNode" "InnerTreeEvaluatorNode" "IotAuthenticationNode" "IotRegistrationNode" "KbaCreateNode" "KbaDecisionNode" "KbaVerifyNode" "LdapDecisionNode" "LoginCountDecisionNode" "MessageNode" "MetadataNode" "MeterNode" "ModifyAuthLevelNode" "OneTimePasswordCollectorDecisionNode" "OneTimePasswordGeneratorNode" "OneTimePasswordSmsSenderNode" "OneTimePasswordSmtpSenderNode" "PageNode" "PasswordCollectorNode" "PatchObjectNode" "PersistentCookieDecisionNode" "PollingWaitNode" "ProfileCompletenessDecisionNode" "ProvisionDynamicAccountNode" "ProvisionIdmAccountNode" "PushAuthenticationSenderNode" "PushResultVerifierNode" "QueryFilterDecisionNode" "RecoveryCodeCollectorDecisionNode" "RecoveryCodeDisplayNode" "RegisterLogoutWebhookNode" "RemoveSessionPropertiesNode" "RequiredAttributesDecisionNode" "RetryLimitDecisionNode" "ScriptedDecisionNode" "SelectIdPNode" "SessionDataNode" "SetFailureUrlNode" "SetPersistentCookieNode" "SetSessionPropertiesNode" "SetSuccessUrlNode" "SocialFacebookNode" "SocialGoogleNode" "SocialNode" "SocialOAuthIgnoreProfileNode" "SocialOpenIdConnectNode" "SocialProviderHandlerNode" "TermsAndConditionsDecisionNode" "TimeSinceDecisionNode" "TimerStartNode" "TimerStopNode" "UsernameCollectorNode" "ValidatedPasswordNode" "ValidatedUsernameNode" "WebAuthnAuthenticationNode" "WebAuthnDeviceStorageNode" "WebAuthnRegistrationNode" "ZeroPageLoginNode" "product-CertificateCollectorNode" "product-CertificateUserExtractorNode" "product-CertificateValidationNode" "product-KerberosNode" "product-ReCaptchaNode" "product-Saml2Node" "product-WriteFederationInformationNode" )
OOTBNODETYPES_7_1=( "PushRegistrationNode" "GetAuthenticatorAppNode" "MultiFactorRegistrationOptionsNode" "OptOutMultiFactorAuthenticationNode" "AcceptTermsAndConditionsNode" "AccountActiveDecisionNode" "AccountLockoutNode" "AgentDataStoreDecisionNode" "AnonymousSessionUpgradeNode" "AnonymousUserNode" "AttributeCollectorNode" "AttributePresentDecisionNode" "AttributeValueDecisionNode" "AuthLevelDecisionNode" "ChoiceCollectorNode" "ConsentNode" "CookiePresenceDecisionNode" "CreateObjectNode" "CreatePasswordNode" "DataStoreDecisionNode" "DeviceGeoFencingNode" "DeviceLocationMatchNode" "DeviceMatchNode" "DeviceProfileCollectorNode" "DeviceSaveNode" "DeviceTamperingVerificationNode" "DisplayUserNameNode" "EmailSuspendNode" "EmailTemplateNode" "IdentifyExistingUserNode" "IncrementLoginCountNode" "InnerTreeEvaluatorNode" "IotAuthenticationNode" "IotRegistrationNode" "KbaCreateNode" "KbaDecisionNode" "KbaVerifyNode" "LdapDecisionNode" "LoginCountDecisionNode" "MessageNode" "MetadataNode" "MeterNode" "ModifyAuthLevelNode" "OneTimePasswordCollectorDecisionNode" "OneTimePasswordGeneratorNode" "OneTimePasswordSmsSenderNode" "OneTimePasswordSmtpSenderNode" "PageNode" "PasswordCollectorNode" "PatchObjectNode" "PersistentCookieDecisionNode" "PollingWaitNode" "ProfileCompletenessDecisionNode" "ProvisionDynamicAccountNode" "ProvisionIdmAccountNode" "PushAuthenticationSenderNode" "PushResultVerifierNode" "QueryFilterDecisionNode" "RecoveryCodeCollectorDecisionNode" "RecoveryCodeDisplayNode" "RegisterLogoutWebhookNode" "RemoveSessionPropertiesNode" "RequiredAttributesDecisionNode" "RetryLimitDecisionNode" "ScriptedDecisionNode" "SelectIdPNode" "SessionDataNode" "SetFailureUrlNode" "SetPersistentCookieNode" "SetSessionPropertiesNode" "SetSuccessUrlNode" "SocialFacebookNode" "SocialGoogleNode" "SocialNode" "SocialOAuthIgnoreProfileNode" "SocialOpenIdConnectNode" "SocialProviderHandlerNode" "TermsAndConditionsDecisionNode" "TimeSinceDecisionNode" "TimerStartNode" "TimerStopNode" "UsernameCollectorNode" "ValidatedPasswordNode" "ValidatedUsernameNode" "WebAuthnAuthenticationNode" "WebAuthnDeviceStorageNode" "WebAuthnRegistrationNode" "ZeroPageLoginNode" "product-CertificateCollectorNode" "product-CertificateUserExtractorNode" "product-CertificateValidationNode" "product-KerberosNode" "product-ReCaptchaNode" "product-Saml2Node" "product-WriteFederationInformationNode" )
OOTBNODETYPES_7_2=( "OathRegistrationNode" "OathTokenVerifierNode" "PassthroughAuthenticationNode" "ConfigProviderNode" "PushRegistrationNode" "GetAuthenticatorAppNode" "MultiFactorRegistrationOptionsNode" "OptOutMultiFactorAuthenticationNode" "AcceptTermsAndConditionsNode" "AccountActiveDecisionNode" "AccountLockoutNode" "AgentDataStoreDecisionNode" "AnonymousSessionUpgradeNode" "AnonymousUserNode" "AttributeCollectorNode" "AttributePresentDecisionNode" "AttributeValueDecisionNode" "AuthLevelDecisionNode" "ChoiceCollectorNode" "ConsentNode" "CookiePresenceDecisionNode" "CreateObjectNode" "CreatePasswordNode" "DataStoreDecisionNode" "DeviceGeoFencingNode" "DeviceLocationMatchNode" "DeviceMatchNode" "DeviceProfileCollectorNode" "DeviceSaveNode" "DeviceTamperingVerificationNode" "DisplayUserNameNode" "EmailSuspendNode" "EmailTemplateNode" "IdentifyExistingUserNode" "IncrementLoginCountNode" "InnerTreeEvaluatorNode" "IotAuthenticationNode" "IotRegistrationNode" "KbaCreateNode" "KbaDecisionNode" "KbaVerifyNode" "LdapDecisionNode" "LoginCountDecisionNode" "MessageNode" "MetadataNode" "MeterNode" "ModifyAuthLevelNode" "OneTimePasswordCollectorDecisionNode" "OneTimePasswordGeneratorNode" "OneTimePasswordSmsSenderNode" "OneTimePasswordSmtpSenderNode" "PageNode" "PasswordCollectorNode" "PatchObjectNode" "PersistentCookieDecisionNode" "PollingWaitNode" "ProfileCompletenessDecisionNode" "ProvisionDynamicAccountNode" "ProvisionIdmAccountNode" "PushAuthenticationSenderNode" "PushResultVerifierNode" "QueryFilterDecisionNode" "RecoveryCodeCollectorDecisionNode" "RecoveryCodeDisplayNode" "RegisterLogoutWebhookNode" "RemoveSessionPropertiesNode" "RequiredAttributesDecisionNode" "RetryLimitDecisionNode" "ScriptedDecisionNode" "SelectIdPNode" "SessionDataNode" "SetFailureUrlNode" "SetPersistentCookieNode" "SetSessionPropertiesNode" "SetSuccessUrlNode" "SocialFacebookNode" "SocialGoogleNode" "SocialNode" "SocialOAuthIgnoreProfileNode" "SocialOpenIdConnectNode" "SocialProviderHandlerNode" "TermsAndConditionsDecisionNode" "TimeSinceDecisionNode" "TimerStartNode" "TimerStopNode" "UsernameCollectorNode" "ValidatedPasswordNode" "ValidatedUsernameNode" "WebAuthnAuthenticationNode" "WebAuthnDeviceStorageNode" "WebAuthnRegistrationNode" "ZeroPageLoginNode" "product-CertificateCollectorNode" "product-CertificateUserExtractorNode" "product-CertificateValidationNode" "product-KerberosNode" "product-ReCaptchaNode" "product-Saml2Node" "product-WriteFederationInformationNode" )
OOTBNODETYPES=(${OOTBNODETYPES_7[@]})
CONTAINERNODETYPES=( "PageNode" "CustomPageNode" )
SCRIPTNODETYPES=( "ConfigProviderNode" "ScriptedDecisionNode" "ClientScriptNode" "SocialProviderHandlerNode" "CustomScriptNode" )
EMAILTEMPLATENODETYPES=( "EmailSuspendNode" "EmailTemplateNode" )
AM=""
REALM=""
AMADMIN=""
AMPASSWD=""
AMSESSION=""
ACCESS_TOKEN=""
FILE=""
VERSION=""
COOKIE_NAME=""
DEPLOYMENT=""
ORIGIN_CMD="md5<<<\$AM\$REALM"
SHA256SUM_CMD='shasum -a 256'
REUUID="true"

checkUtils(){
    if ! [ -x "$(command -v md5)" ]; then
        if ! [ -x "$(command -v md5sum)" ]; then
            1>&2 echo 'Error: neither md5 nor md5sum is installed.'
            exit 1
        fi
        ORIGIN_CMD="md5sum<<<\$AM\$REALM"
    fi
    if ! [ -x "$(command -v jq)" ]; then
        1>&2 echo 'Error: jq is required but not installed.'
        exit 1
    fi
    if ! [ -x "$(command -v shasum)" ]; then
        if ! [ -x "$(command -v sha256sum)" ]; then
            echo >&2 "Error: neither shasum nor sha256sum installed."
            exit 1
        fi
        SHA256SUM_CMD='sha256sum'
    fi
    if ! [ -x "$(command -v xxd)" ]; then
        echo >&2 "Error: xxd is required but not installed."
        exit 1
    fi
}
checkUtils

CLIENT_ID="idmAdminClient"
CLIENT_PASSWORD="doesnotmatter"
SCOPES="fr:idm:*"
RESPONSE_TYPE="code"

function login {
    COOKIE_NAME=$(curl -k -s $AM/json/serverinfo/* | jq -r .cookieName)
    AREALM=$REALM
    shopt -s nocasematch
    if [[ $AMADMIN == "amadmin" ]]; then
        AREALM=""
    fi
    shopt -u nocasematch
    RESPONSE=$(curl -s -j -k -X POST --data "" -H "Accept-API-Version:resource=2.0,protocol=1.0" -H "X-Requested-With:XmlHttpRequest" -H "X-OpenAM-Username:${AMADMIN}" -H "X-OpenAM-Password:${AMPASSWD}" "$AM/json/authenticate")
    if [[ $RESPONSE = "" ]]; then
        echo 'Error: Check hostname is valid.'
        exit -1
    else
        if [ "null" != "$(echo $RESPONSE | jq .callbacks)" ]; then
            # could this be MFA with skip option in ID Cloud?
            SKIP="$(echo $RESPONSE | jq .callbacks | jq -r '.[] | select(.type == "HiddenValueCallback") | .input | .[] | select(.value | contains("skip-input")) | .value')"
            if [ ! -z "$SKIP" ]; then
                DATA=$(echo $RESPONSE | sed -e "s/$SKIP/Skip/g")
                RESPONSE=$(curl -j -s -k -X POST --data "$DATA" -H "Content-Type:application/json" -H "Accept-API-Version:resource=2.0,protocol=1.0" "$AM/json/authenticate")
            fi
        fi
        if [ "null" == "$(echo "$RESPONSE" | jq .tokenId)" ]; then
            if [ "null" != "$(echo "$RESPONSE" | jq -r '.errorMessage')" ]; then
                1>&2 echo "Error: $(echo "$RESPONSE" | jq -r '.errorMessage')"
            else
                1>&2 echo "Error: $(echo "$RESPONSE" | jq -r '.message')"
            fi
            exit -1
        else
            AMSESSION=$(echo "$RESPONSE" | jq -r .tokenId)
        fi
    fi
    setVersion
    if [ -z "$DEPLOYMENT" ]; then
        setDeployment
    fi
    # if cloud or forgeops deployment, also get an IDM session
    shopt -s nocasematch
    if [[ "$DEPLOYMENT" == "Cloud" ]] || [[ "$DEPLOYMENT" == "ForgeOps" ]] ; then
        getAccessToken
    fi
    shopt -u nocasematch
}

function getAccessToken() {
	VERIFIER=`LC_CTYPE=C && LANG=C && cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 50 | head -n 1`
	CHALLENGE=`echo -n $VERIFIER | $SHA256SUM_CMD | cut -d " " -f 1 | xxd -r -p | base64 | tr / _ | tr + - | tr -d =`

    AM_AUTHORIZE=$AM/oauth2/authorize
    AM_ACCESS_TOKEN=$AM/oauth2/access_token
    BASE_HOST="${AM%/*}"
    REDIRECT_URL=$BASE_HOST/platform/appAuthHelperRedirect.html

    CODE=`curl -H "Cookie: $COOKIE_NAME=$AMSESSION" -s -k -X POST -H "Content-Type: application/x-www-form-urlencoded" -d "redirect_uri=$REDIRECT_URL&scope=$SCOPES&response_type=$RESPONSE_TYPE&client_id=$CLIENT_ID&csrf=$AMSESSION&decision=allow&code_challenge=$CHALLENGE&code_challenge_method=S256" "$AM_AUTHORIZE" -D - | grep "code=" | cut -d '=' -f2 | cut -d '&' -f1`
    # 1>&2 echo "authz code: $CODE"

    # FIDC uses a different oauth2 client config than forgeops
    if [[ "$DEPLOYMENT" == "Cloud" ]] ; then
        TOKENS=`curl -s -X POST --user "$CLIENT_ID:$CLIENT_PASSWORD" -H "Cache-Control: no-cache" -d "grant_type=authorization_code&code=$CODE&redirect_uri=$REDIRECT_URL&code_verifier=$VERIFIER" -k "$AM_ACCESS_TOKEN" | jq .`
    elif [[ "$DEPLOYMENT" == "ForgeOps" ]] ; then
        TOKENS=`curl -s -X POST -H "Content-Type: application/x-www-form-urlencoded" -H "Cache-Control: no-cache" -d "client_id=$CLIENT_ID&grant_type=authorization_code&code=$CODE&redirect_uri=$REDIRECT_URL&code_verifier=$VERIFIER" -k "$AM_ACCESS_TOKEN" | jq .`
    fi
    ACCESS_TOKEN=`echo $TOKENS | jq -r .access_token`
    # 1>&2 echo "access token: $ACCESS_TOKEN"

    JVERSION=`curl -s -X GET -H "Authorization: Bearer $ACCESS_TOKEN" -k "$BASE_HOST/openidm/info/version"`
    IDM_VERSION=`echo $JVERSION | jq -r .productVersion`
    IDM_BUILD_DATE=`echo $JVERSION | jq -r .productBuildDate`
    IDM_REVISION=`echo $JVERSION | jq -r .productRevision`
    IDM_VERSION_STRING="ForgeRock Identity Management $IDM_VERSION Build $IDM_REVISION ($IDM_BUILD_DATE)"
    1>&2 echo "Connected to $IDM_VERSION_STRING"
}

function setDeployment {
	VERIFIER=`LC_CTYPE=C && LANG=C && cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 50 | head -n 1`
	CHALLENGE=`echo -n $VERIFIER | $SHA256SUM_CMD | cut -d " " -f 1 | xxd -r -p | base64 | tr / _ | tr + - | tr -d =`

    AM_AUTHORIZE=$AM/oauth2/authorize
    BASE_HOST="${AM%/*}"
    REDIRECT_URL=$BASE_HOST/platform/appAuthHelperRedirect.html

    STATUS=`curl -o /dev/null -w "%{http_code}" -H "Cookie: $COOKIE_NAME=$AMSESSION" -s -k -X POST -H "Content-Type: application/x-www-form-urlencoded" -d "redirect_uri=$REDIRECT_URL&scope=$SCOPES&response_type=$RESPONSE_TYPE&client_id=$CLIENT_ID&csrf=$AMSESSION&decision=allow&code_challenge=$CHALLENGE&code_challenge_method=S256" "$AM_AUTHORIZE"`

    JVERSION=$(curl -H "Cookie: $COOKIE_NAME=$AMSESSION" -s -k -X GET -H "Accept-API-Version:resource=1.0" $AM/json${REALM}/serverinfo/version)
    if [ $STATUS -eq 302 ]; then
        DEPLOYMENT="Cloud"
        1>&2 echo "ForgeRock Identity Cloud detected."
    else
        CLIENT_ID="idm-admin-ui"
        STATUS=`curl -o /dev/null -w "%{http_code}" -H "Cookie: $COOKIE_NAME=$AMSESSION" -s -k -X POST -H "Content-Type: application/x-www-form-urlencoded" -d "redirect_uri=$REDIRECT_URL&scope=$SCOPES&response_type=$RESPONSE_TYPE&client_id=$CLIENT_ID&csrf=$AMSESSION&decision=allow&code_challenge=$CHALLENGE&code_challenge_method=S256" "$AM_AUTHORIZE"`
        if [ $STATUS -eq 302 ]; then
            DEPLOYMENT="ForgeOps"
            1>&2 echo "ForgeOps deployment detected."
        else
            DEPLOYMENT="Classic"
            1>&2 echo "Classic deployment detected."
        fi
    fi
}

function setVersion {
    JVERSION=$(curl -H "Cookie: $COOKIE_NAME=$AMSESSION" -s -k -X GET -H "Accept-API-Version:resource=1.0" $AM/json${REALM}/serverinfo/version)
    VERSION=$(echo $JVERSION| jq -r  '.version')
    FULLVER=$(echo $JVERSION| jq -r  '.fullVersion')
    1>&2 echo "Connected to $FULLVER"
    if [ -z "$OVERSION" ] ; then
        VERKEY=$(echo "$VERSION" | sed -e 's/\./_/g' | cut -c1-5)
        VERKEY1=$(echo "$VERKEY" | cut -c1-1)
        VARNAME="OOTBNODETYPES_$VERKEY"
        eval OOTBNODETYPES=(\${$VARNAME[@]})
        if [ -z "$OOTBNODETYPES" ] ; then
            VERKEY=$(echo "$VERKEY" | cut -c1-3)
            VARNAME="OOTBNODETYPES_$VERKEY"
            eval OOTBNODETYPES=(\${$VARNAME[@]})
            if [ -z "$OOTBNODETYPES" ] ; then
                VERKEY=$(echo "$VERKEY" | cut -c1-1)
                VARNAME="OOTBNODETYPES_$VERKEY"
                eval OOTBNODETYPES=(\${$VARNAME[@]})
            fi
        fi
    fi
    overrideVersion
}

function overrideVersion {
    if [ -n "$OVERSION" ] ; then
        1>&2 echo "Overriding version to $OVERSION"
        VERKEY=$(echo "$OVERSION" | sed -e 's/\./_/g' | cut -c1-5)
        VERKEY1=$(echo "$VERKEY" | cut -c1-1)
        VARNAME="OOTBNODETYPES_$VERKEY"
        eval OOTBNODETYPES=(\${$VARNAME[@]})
        if [ -z "$OOTBNODETYPES" ] ; then
            VERKEY=$(echo "$VERKEY" | cut -c1-3)
            VARNAME="OOTBNODETYPES_$VERKEY"
            eval OOTBNODETYPES=(\${$VARNAME[@]})
            if [ -z "$OOTBNODETYPES" ] ; then
                VERKEY=$(echo "$VERKEY" | cut -c1-1)
                VARNAME="OOTBNODETYPES_$VERKEY"
                eval OOTBNODETYPES=(\${$VARNAME[@]})
            fi
        fi
    fi
}

# the admin ui leaves orphaned node instances after deleting a tree and when using the APIs it is very easy to
# forget to clean-up everything as well. the prune function will iterate through all node types, and then through
# all instances of each node type. Then it will iterate over all the trees and their nodes and check if any of
# the auth node type instances are orphaned and remove them.
function prune {
    1>&2 echo "Analyzing authentication nodes configuration artifacts..."

    #get all the trees and their node references
    #these are all the nodes that are actively in use. every node instance we find in the next step, that is not in this list, is orphaned and will be removed/pruned.
    JTREES=$(curl -H "Cookie: $COOKIE_NAME=$AMSESSION" -s -k -X GET -H "Accept-API-Version:resource=1.0" $AM/json${REALM}/realm-config/authentication/authenticationtrees/trees?_queryFilter=true)
    ACTIVENODES=($(echo $JTREES| jq -r  '.result|.[]|.nodes|keys|.[]'))

    #do any of the active nodes have inner nodes?
    INNERNODES=()
    for CONTAINERNODETYPE in "${CONTAINERNODETYPES[@]}" ; do
        CONTAINERNODES=($(echo $JTREES| jq -r --arg CONTAINERNODETYPE "$CONTAINERNODETYPE" '.result|.[]|.nodes|keys[] as $key|select(.[$key].nodeType==$CONTAINERNODETYPE)|$key'))

        #get the inner nodes for each container node
        for CONTAINERNODE in "${CONTAINERNODES[@]}" ; do
            JINNERNODES=$(curl -H "Cookie: $COOKIE_NAME=$AMSESSION" -s -k -X GET -H "Accept-API-Version:resource=1.0" -H "X-Requested-With:XmlHttpRequest" $AM/json${REALM}/realm-config/authentication/authenticationtrees/nodes/$CONTAINERNODETYPE/$CONTAINERNODE)
            local ERROR="$(echo $JINNERNODES | jq -r '.code')"
            if [ "$ERROR" == "null" ] ; then
                INNERNODES+=($(echo $JINNERNODES | jq -r '.nodes|.[]|._id'))
            else
                local MSG="$(echo $JINNERNODES | jq -r '.message')"
                1>&2 echo "ERROR: $ERROR - $MSG ($AM/json${REALM}/realm-config/authentication/authenticationtrees/nodes/$CONTAINERNODETYPE/$CONTAINERNODE)"
            fi
        done
    done

    #add inner nodes to list of active nodes
    ACTIVENODES+=(${INNERNODES[@]})

    #get all the node instances
    JNODES=$(curl -H "Cookie: $COOKIE_NAME=$AMSESSION" -s -k -X POST --data "{}" -H "Accept-API-Version:resource=1.0" -H  "Content-Type:application/json" $AM/json${REALM}/realm-config/authentication/authenticationtrees/nodes?_action=nextdescendents)
    NODES=($(echo $JNODES| jq -r  '.result|.[]|._id'))
    ORPHANEDNODES=()

    #find all the orphaned nodes
    for NODE in "${NODES[@]}" ; do
        ORPHANED=true
        for ACTIVENODE in "${ACTIVENODES[@]}" ; do
            if [ "$NODE" == "$ACTIVENODE" ] ; then
                ORPHANED=false
                break
            fi
        done
        if [ "$ORPHANED" == "true" ] ; then
            ORPHANEDNODES+=("$NODE")
        fi
    done

    1>&2 echo
    1>&2 echo "Total:    ${#NODES[@]}"
    #1>&2 echo "Active:   ${#ACTIVENODES[@]}"
    1>&2 echo "Orphaned: ${#ORPHANEDNODES[@]}"
    1>&2 echo

    if [[ ${#ORPHANEDNODES[@]} > 0 ]] ; then
        read -p "Do you want to prune (permanently delete) all the orphaned node instances? (N/y): " -n 1 -r
        1>&2 echo    # (optional) move to a new line
        if [[ $REPLY =~ ^[Yy]$ ]] ; then
            1>&2 echo -n "Pruning"
            #delete all the orphaned nodes
            for NODE in "${ORPHANEDNODES[@]}"
            do
                1>&2 echo -n "."
                TYPE=$(echo $JNODES | jq -r --arg id "$NODE" '.result|.[]|select(._id==$id)|._type|._id')
                RESULT=$(curl -H "Cookie: $COOKIE_NAME=$AMSESSION" -s -k -X DELETE -H "Accept-API-Version:resource=1.0" -H "X-Requested-With:XmlHttpRequest" $AM/json${REALM}/realm-config/authentication/authenticationtrees/nodes/$TYPE/$NODE)
            done
            1>&2 echo
            1>&2 echo "Done."
            exit 0
        else
            1>&2 echo "Done."
            exit 0
        fi
    else
        1>&2 echo "Nothing to prune."
        exit 0
    fi
}


function listTrees {
    local JTREES=$(curl -H "Cookie: $COOKIE_NAME=$AMSESSION" -s -k -X GET -H "Accept-API-Version:resource=1.0" $AM/json${REALM}/realm-config/authentication/authenticationtrees/trees?_queryFilter=true)
    local TREES=($(echo $JTREES| jq -r '.result|.[]|._id'))
    if [[ -z $FILE ]] ; then
        CUSTOM=false
        for TREE in "${TREES[@]}" ; do
            local JTREE=$(echo $JTREES| jq -r --arg id "$TREE" '.result|.[]|select(._id==$id)')
            if isCustomTree "$JTREE" ; then
                echo "- $TREE"
            else
                echo "* $TREE"
                CUSTOM=true
            fi
        done;
        if [ "$CUSTOM" == "true" ] ; then
            echo
            echo "(*) Tree contains custom node(s)."
        fi
    else
        for TREE in "${TREES[@]}" ; do
            echo $TREE >>"$FILE"
        done;
    fi
}


# isCustomTree {json}"
function isCustomTree {
    local TREE=$1
    local NODES=$(echo $TREE| jq -r  '.nodes | keys | .[]')
    for each in $NODES ; do
        local TYPE=$(echo $TREE | jq -r --arg NODE "$each" '.nodes | .[$NODE] | .nodeType')
        if ! itemIn "$TYPE" "${OOTBNODETYPES[@]}" ; then
            return 1
        fi
        local NODE=$(curl -H "Cookie: $COOKIE_NAME=$AMSESSION" -s -k -X GET -H "Accept-API-Version:resource=1.0" -H "X-Requested-With:XmlHttpRequest" $AM/json${REALM}/realm-config/authentication/authenticationtrees/nodes/$TYPE/$each | jq '. | del (._rev)')

        # inner nodes
        # Currently the only node type containing inner nodes is "PageNode". Additional types can be defined in CONTAINERNODETYPES.
        if itemIn "$TYPE" "${CONTAINERNODETYPES[@]}" ; then
            local PAGES=$(echo $NODE | jq -r '.nodes | keys | .[]')
            for page in $PAGES; do
                local PAGENODETYPE=$(echo $NODE | jq -r --arg IND "$page" '.nodes[($IND|tonumber)] | .nodeType')
                if ! itemIn "$PAGENODETYPE" "${OOTBNODETYPES[@]}" ; then
                    return 1
                fi
            done
        fi
    done
    return 0
}


# itemIn "value" "${array[@]}"
function itemIn () {
    found=`echo "${@:2}" | grep -c $1`
    return $(( found * -1 + 1 ))
}


# isMultiTree <json>
# determine if json document is a single or multi tree export
function isMultiTree {
    cat authn_all.json | jq -r 'keys'
    return 0
    return 1
}

function describeAllTrees {
    if [[ -z $AM ]] ; then
        local FILES=($(ls -1tr *.json))
        for TREEFILE in "${FILES[@]}" ; do
            describe "$(cat $TREEFILE)"
        done;
    else
        login
        local JTREES=$(curl -H "Cookie: $COOKIE_NAME=$AMSESSION" -s -k -X GET -H "Accept-API-Version:resource=1.0" $AM/json${REALM}/realm-config/authentication/authenticationtrees/trees?_queryFilter=true)
        # local TREES=($(echo $JTREES| jq -r  '.result|.[]|._id'))
        local TREES=()
        #local TREES=($(echo $JTREES| jq -r  '.result|.[]|._id' | sed -e 's/^/"/g' -e 's/$/"/g' | tr '\n' ' '))
        # using while loop with herestring to create the TREES array - this is needed for handling trees with spaces in names
        while read -r line ; do
            TREES+=( "${line}" )
        done <<< "$(echo $JTREES| jq '.result|.[]|._id')"

        for TREE in "${TREES[@]}" ; do
            describe "$(exportTree "$TREE" true)"
        done;
    fi
}

function describeTree {
    if [[ -z $AM ]] ; then
        overrideVersion
        describe "$(cat $FILE)"
    else
        login
        describe "$(exportTree "$TREENAME" true)"
    fi
}

function describe {
    JTREE="$1"
    TREE=$(echo $JTREE | jq -r '.tree._id')
    RAWNODES=($(echo $JTREE | jq -r  '.["nodes","innernodes"]|.[]|._type|._id' | sort -s))
    NODES=($(echo $JTREE | jq -r  '.["nodes","innernodes"]|.[]|._type|._id' | sort -u))
    # the @base64 is ugly but the only way I found to make the array work with spaces in the script name
    SCRIPTS=($(echo $JTREE | jq -r '.scripts|.[]|.name|@base64' | sort -u))
    DEP_TREES=($(echo $JTREE | jq -r '.nodes|keys[] as $key|select(.[$key]._type._id=="InnerTreeEvaluatorNode")|.[$key]|.tree'))
    echo Tree: $TREE
    echo -n =====
    for ((i = 0; i < (`echo $TREE | wc -c`); i++)) ; do
        echo -n "="
    done;
    echo
    echo
    echo Nodes:
    echo -----
    if [ ${#NODES[@]} -eq 0 ]; then
        echo "None"
    else
        CUSTOM=false
        for NODE in "${NODES[@]}" ; do
            if itemIn "$NODE" "${OOTBNODETYPES[@]}" ; then
                echo "- $(grep -o $NODE <<< ${RAWNODES[@]} | wc -l  | xargs) $NODE"
            else
                echo "* $(grep -o $NODE <<< ${RAWNODES[@]} | wc -l  | xargs) $NODE"
                CUSTOM=true
            fi
        done;
        if [ "$CUSTOM" == "true" ] ; then
            echo
            echo "(*) Custom node."
        fi
    fi
    echo
    echo Scripts:
    echo -------
    if [ ${#SCRIPTS[@]} -eq 0 ]; then
        echo None
    else
        for SCRIPT in "${SCRIPTS[@]}" ; do
            echo "- $(echo $SCRIPT | base64 -d)"
        done;
    fi
    echo
    echo Dependencies:
    echo ------------
        if [ ${#DEP_TREES[@]} -eq 0 ]; then
        echo None
    else
        for DEP_TREE in "${DEP_TREES[@]}" ; do
            echo "- $DEP_TREE"
        done;
    fi
}

function exportAllTrees {
    local JTREES=$(curl -H "Cookie: $COOKIE_NAME=$AMSESSION" -s -k -X GET -H "Accept-API-Version:resource=1.0" $AM/json${REALM}/realm-config/authentication/authenticationtrees/trees?_queryFilter=true)
    local TREES=()
    # local TREES=($(echo $JTREES| jq -r  '.result|.[]|._id'))
    # using while loop with herestring to create the TREES array - this is needed for handling trees with spaces in names
    while read -r line ; do
        TREES+=( "${line}" )
    done <<< "$(echo $JTREES| jq '.result|.[]|._id')"
    local EXPORTS="{ \"trees\":{} }"
    for TREE in "${TREES[@]}" ; do
      local JTREE=`exportTree "$TREE" "noFile"`
      EXPORTS=$(echo $EXPORTS "{ \"trees\": { \"${TREE//\"}\":$JTREE } }" | jq -s 'reduce .[] as $item ({}; . * $item)')
    done;

    if [[ -z $FILE ]]; then
        echo $EXPORTS | jq .
    else
        echo "" > "$FILE"
        echo $EXPORTS | jq . >>"$FILE"
    fi
}

function exportTreesSeparately {
    local FILEPREFIX=$FILE
    echo "Export all trees to files"
    local JTREES=$(curl -H "Cookie: $COOKIE_NAME=$AMSESSION" -s -k -X GET -H "Accept-API-Version:resource=1.0" $AM/json${REALM}/realm-config/authentication/authenticationtrees/trees?_queryFilter=true)
    local TREES=()
    #local TREES=($(echo $JTREES| jq -r  '.result|.[]|._id' | sed -e 's/^/"/g' -e 's/$/"/g' | tr '\n' ' '))
    # using while loop with herestring to create the TREES array - this is needed for handling trees with spaces in names
    while read -r line ; do
        TREES+=( "${line}" )
    done <<< "$(echo $JTREES| jq '.result|.[]|._id')"
    local EXPORTS="{ \"trees\":{} }"
    for TREE in "${TREES[@]}" ; do
        FILE="${FILEPREFIX}${TREE//\"}.json"
        if [[ -n $FILE ]]; then
            echo "" > "$FILE"
        fi
        local JTREE=`exportTree "${TREE}"`
    done;
}

function importTreesSeparately {
    echo "Import all trees in the current directory"
    local FILES=($(ls -1tr *.json))
    local JTREES=$'{\n  \"trees\": {\n    \"'
    for TREEFILE in "${FILES[@]}" ; do
        local TREENAME=${TREEFILE%.*}
        JTREES=$JTREES$TREENAME$'\":\n'
        JTREES=$JTREES$(cat $TREEFILE)$',\n    \"'
    done;
    # Remove the comma from the end of the last file import and close the JSON
    JTREES=${JTREES%???????}
    jtrees=$JTREES$'  }\n}'
    # get list of already installed trees for dependency and conflict resolution
    local jinstalled=$(curl -H "Cookie: $COOKIE_NAME=$AMSESSION" -s -k -X GET -H "Accept-API-Version:resource=1.0" $AM/json${REALM}/realm-config/authentication/authenticationtrees/trees?_queryFilter=true)
    # local installed=($(echo $jinstalled| jq -r  '.result|.[]|._id'))
    local installed=()
    # using while loop with herestring to create the installed array - this is needed for handling trees with spaces in names
    while read -r line ; do
        installed+=( "${line}" )
    done <<< "$(echo $jinstalled| jq '.result|.[]|._id')"

    local resolved=()
    local unresolved=()
    resolve
    for tree in ${resolved[@]} ; do
        local jtree=$(echo $jtrees | jq --arg tree $tree '.trees[$tree]')
        echo $jtree | importTree "$tree" "noFile"
    done
}

# exportTree <tree> <flag>
# where tree is the name of tree to export and if flag is set to anything, stdout will be used for output even if $FILE is set.
function exportTree {
    local TREENAME=${1//\"} # remove double quotes which were inserted
    TREENAMEFORURL=$(echo "$TREENAME" | sed 's/ /%20/g') # replace any spaces with %20
    local URL="$AM/json${REALM}/realm-config/authentication/authenticationtrees/trees/$TREENAMEFORURL"
    local TREE=$(curl -H "Cookie: $COOKIE_NAME=$AMSESSION" -f -s -k -X GET -H "Accept-API-Version:resource=1.0" -H "X-Requested-With:XmlHttpRequest" "$URL" | jq -c '. | del (._rev)')
    if [ -z "$TREE" ]; then
        1>&2 echo "Failed to find tree: $TREENAME"
        exit -1
    fi
    1>&2 echo -n "$TREENAME."

    local NODES=$(echo $TREE| jq -r  '.nodes | keys | .[]')

    local ORIGIN=$(eval $ORIGIN_CMD)

    local EXPORTS="{ \"origin\":\"$ORIGIN\", \"innernodes\":{}, \"nodes\":{}, \"scripts\":{}, \"emailTemplates\":{} }"

    for each in $NODES ; do
        local TYPE=$(echo $TREE | jq -r --arg NODE "$each" '.nodes | .[$NODE] | .nodeType')
        local NODE=$(curl -H "Cookie: $COOKIE_NAME=$AMSESSION" -s -k -X GET -H "Accept-API-Version:resource=1.0" -H "X-Requested-With:XmlHttpRequest" $AM/json${REALM}/realm-config/authentication/authenticationtrees/nodes/$TYPE/$each | jq '. | del (._rev)')
        1>&2 echo -n "."
        EXPORTS=$(echo $EXPORTS "{ \"nodes\": { \"$each\": $NODE } }" | jq -s 'reduce .[] as $item ({}; . * $item)')

        # Export inner nodes
        # Currently the only node type containing inner nodes is "PageNode". Additional types can be defined in CONTAINERNODETYPES.
        if itemIn "$TYPE" "${CONTAINERNODETYPES[@]}" ; then
            local PAGES=$(echo $NODE | jq -r '.nodes | keys | .[]')
            for page in $PAGES; do
                local PAGENODEID=$(echo $NODE | jq -r --arg IND "$page" '.nodes[($IND|tonumber)] | ._id')
                local PAGENODETYPE=$(echo $NODE | jq -r --arg IND "$page" '.nodes[($IND|tonumber)] | .nodeType')
                local PAGENODE=$(curl -H "Cookie: $COOKIE_NAME=$AMSESSION" -s -k -X GET -H "Accept-API-Version:resource=1.0" -H "X-Requested-With:XmlHttpRequest" $AM/json${REALM}/realm-config/authentication/authenticationtrees/nodes/$PAGENODETYPE/$PAGENODEID | jq '. | del (._rev)')
                1>&2 echo -n "."
                EXPORTS=$(echo $EXPORTS "{ \"innernodes\": { \"$PAGENODEID\": $PAGENODE } }" | jq -s 'reduce .[] as $item ({}; . * $item)')

                # Export scripts inside page nodes
                if itemIn "$PAGENODETYPE" "${SCRIPTNODETYPES[@]}" ; then
                    local SCRIPTID=$(echo $PAGENODE | jq -r '.script')
                    if [ "$SCRIPTID" == "null" ] || [ "$SCRIPTID" == "" ] ; then
                        1>&2 echo ""
                        1>&2 echo "Error processing node with _id: $PAGENODEID"
                        1>&2 echo "$PAGENODE"
                    fi
                    local SCRIPT=$(curl -H "Cookie: $COOKIE_NAME=$AMSESSION" -s -k -X GET -H "Accept-API-Version:resource=1.0" -H "X-Requested-With:XmlHttpRequest" $AM/json${REALM}/scripts/$SCRIPTID | jq '. | del (._rev)')
                    EXPORTS=$(echo $EXPORTS "{ \"scripts\": { \"$SCRIPTID\": $SCRIPT } }" | jq -s 'reduce .[] as $item ({}; . * $item)')
                fi

                # If this is FIDC or ForgeOps, export email templates referenced by nodes in this page node
                #
                # There is currently no node that produces a callback and references an email template.
                # But if somebody were to create such a node and were to follow the same implementation
                # and property naming pattern as the existing email template referencing nodes, then
                # this code will handle such a node properly.
                if [ "$DEPLOYMENT" == "Cloud" ] || [ "$DEPLOYMENT" == "ForgeOps" ] ; then
                    if itemIn "$PAGENODETYPE" "${EMAILTEMPLATENODETYPES[@]}" ; then
                        local TEMPLATEID=$(echo $PAGENODE | jq -r '.emailTemplateName')
                        local TEMPLATE=$(curl -s -k -X GET -H "Authorization: Bearer $ACCESS_TOKEN" $BASE_HOST/openidm/config/emailTemplate/$TEMPLATEID | jq '. | del (._rev)')
                        1>&2 echo -n "."
                        EXPORTS=$(echo $EXPORTS "{ \"emailTemplates\": { \"$TEMPLATEID\": $TEMPLATE } }" | jq -s 'reduce .[] as $item ({}; . * $item)')
                    fi
                fi
            done
        fi
        # Export scripts referenced by nodes in this tree
        if itemIn "$TYPE" "${SCRIPTNODETYPES[@]}" ; then
            local SCRIPTID=$(echo $NODE | jq -r '.script')
            if [ "$SCRIPTID" == "null" ] || [ "$SCRIPTID" == "" ] ; then
                1>&2 echo ""
                1>&2 echo "Error processing node:"
                1>&2 echo "$NODE"
            fi
            local SCRIPT=$(curl -H "Cookie: $COOKIE_NAME=$AMSESSION" -s -k -X GET -H "Accept-API-Version:resource=1.0" -H "X-Requested-With:XmlHttpRequest" $AM/json${REALM}/scripts/$SCRIPTID | jq '. | del (._rev)')
            if [ -n "${CLONE}" ]; then
              SCRIPT=$(echo $SCRIPT | jq --arg prefix "${CLONE////_} " ' .name=$prefix+.name ')
            fi
            1>&2 echo -n "."
            EXPORTS=$(echo $EXPORTS "{ \"scripts\": { \"$SCRIPTID\": $SCRIPT } }" | jq -s 'reduce .[] as $item ({}; . * $item)')
        fi
        # If this is FIDC or ForgeOps, export email templates referenced by nodes in this tree
        if [ "$DEPLOYMENT" == "Cloud" ] || [ "$DEPLOYMENT" == "ForgeOps" ] ; then
            if itemIn "$TYPE" "${EMAILTEMPLATENODETYPES[@]}" ; then
                local TEMPLATEID=$(echo $NODE | jq -r '.emailTemplateName')
                local TEMPLATE=$(curl -s -k -X GET -H "Authorization: Bearer $ACCESS_TOKEN" $BASE_HOST/openidm/config/emailTemplate/$TEMPLATEID | jq '. | del (._rev)')
                1>&2 echo -n "."
                EXPORTS=$(echo $EXPORTS "{ \"emailTemplates\": { \"$TEMPLATEID\": $TEMPLATE } }" | jq -s 'reduce .[] as $item ({}; . * $item)')
            fi
        fi
    done

    EXPORTS=$(echo ${EXPORTS} "{ \"tree\":${TREE} }" | jq -s 'reduce .[] as $item ({}; . * $item)')
    1>&2 echo "."

    if [[ -z $FILE ]] || [[ -n $2 ]] ; then
        echo $EXPORTS | jq .
    else
        echo $EXPORTS | jq . >>"$FILE"
    fi
}


# sample data:
# #. Trees    Dependencies
# 1. simple
# 2. push
# 3. smart    simple
#             push
#             trusona
# 4. solid    simple
#             select
# 5. select   push
#             trusona
# 6. trusona

# installed = get installed trees
# resolved = ()
# unresolved = get trees to be imported

# function resolve {
#     local resolved = $1
#     local unresolved = $2
#     local before = ${#unresolved[@]}
#     if before == 0
#         echo "all dependencies resolved. ready to install."
#         return
#     fi
#     for tree in unresolved
#         if tree has dependencies
#             allresolved = true
#             for dependency in dependencies
#                 if [ dependency in resolved ] || [ dependency in installed ]
#                     continue
#                 else
#                     allresolved = false
#                     break
#                 fi
#             done
#             if allresolved
#                 echo "tree"
#                 add tree to resolved
#                 remove tree from unresolved
#             fi
#         else
#             add tree to resolved
#             remove tree from unresolved
#         fi
#     done
#     local after = ${#unresolved[@]}
#     if before > after
#         resolve resolved unresolved
#     else
#         echo "unresolvable dependencies. aborting dependency resolution."
#     fi
# }
function resolve {
    if [[ -n $1 ]] ; then
        before=$1
        trees=${unresolved[@]}
        # 1>&2 echo "nested resolve: retry $1 tree(s)"
    else
        1>&2 echo -n "Determining installation order"
        trees=$(echo $jtrees | jq -r  '.trees | keys | .[]')
    fi

    for tree in $trees ; do
        1>&2 echo -n "."
        # 1>&2 echo "resolving $tree"
        dependencies=$(echo $jtrees | jq -r --arg tree $tree '.trees[$tree]|.nodes|keys[] as $key|select(.[$key]._type._id=="InnerTreeEvaluatorNode")|.[$key]|.tree')
        allresolved=true
        for dependency in $dependencies ; do
            1>&2 echo -n "."
            if itemIn "$dependency" "${resolved[@]}" || itemIn "$dependency" "${installed[@]}" ; then
                # 1>&2 echo "  dependency \"$dependency\" resolved. Continuing..."
                continue
            else
                # 1>&2 echo "  Unable to resolve dependency \"$dependency\". Skipping..."
                allresolved=false
            fi
        done
        if [ "$allresolved" = true ] ; then
            # add tree to resolved
            # echo "  resolved before: ${#resolved[@]}"
            resolved+=( $tree )
            # 1>&2 echo "  resolved after : ${#resolved[@]}"
            # remove tree from unresolved
            # echo "  unresolved before: ${#unresolved[@]}"
            for i in "${!unresolved[@]}"; do
                if [[ ${unresolved[i]} = $tree ]]; then
                unset 'unresolved[i]'
                fi
            done
            # unresolved=( "${unresolved[@]/$tree}" )
            # 1>&2 echo "  unresolved after: ${#unresolved[@]}"
        else
            if ! itemIn "$tree" "${unresolved[@]}" ; then
                unresolved+=( $tree )
            fi
        fi
    done
    after=${#unresolved[@]}
    # 1>&2 echo "resolve: after=$after"
    if [[ -n $1 ]] && [[ $after -eq $before ]] ; then
        1>&2 echo
        1>&2 echo "Trees with unresolvable dependencies: ${unresolved[@]}"
    elif [[ $after -gt 0 ]] ; then
        # 1>&2 echo "continuing dependency resolution."
        resolve $after
    fi
    echo
}


# need to handle dependency resolution
function importAllTrees {
    if [[ -z $FILE ]]; then
        local jtrees="$(</dev/stdin)"
    else
        local jtrees="$(<$FILE)"
    fi

    # get list of already installed trees for dependency and conflict resolution
    local jinstalled=$(curl -H "Cookie: $COOKIE_NAME=$AMSESSION" -s -k -X GET -H "Accept-API-Version:resource=1.0" $AM/json${REALM}/realm-config/authentication/authenticationtrees/trees?_queryFilter=true)
    # using while loop with herestring to create the installed array - this is needed for handling trees with spaces in names
    while read -r line ; do
        installed+=( "${line}" )
    done <<< "$(echo $jinstalled| jq '.result|.[]|._id')"

    local resolved=()
    local unresolved=()
    resolve

    for tree in ${resolved[@]} ; do
        local jtree=$(echo $jtrees | jq --arg tree $tree '.trees[$tree]')
        echo $jtree | importTree "$tree" "noFile"
    done
}


# importTree <tree> <flag>
# where tree is the name of tree to import and if flag is set to anything, stdin will be used for input even if $FILE is set.
function importTree {
  local retryCount=0
  RESULT="null"

  if [[ -z $FILE ]] || [[ -n $2 ]] ; then
      TREES=$(</dev/stdin)
  else
      TREES=$(<"$FILE")
  fi
  1>&2 echo -n "$1."

  # initialize hashmap for re-UUID-ing
  HASHMAP="{}"

  # determine origin. this will allow detection if importing into a new or the same environment the tree was exported from
  ORIGIN=$(eval $ORIGIN_CMD)

  # Scripts
  SCRIPTS=$(echo $TREES | jq -r  '.scripts | keys | .[]')
  for each in $SCRIPTS
  do
    SCRIPT=$(echo $TREES | jq --arg script $each '.scripts[$script]')
    NAME=$(echo $SCRIPT | jq -r '.name')
    1>&2 echo -n "."
    #1>&2 echo "Importing script $NAME ($each)"
    RESULT=$(curl -H "Cookie: $COOKIE_NAME=$AMSESSION" -s -k -X PUT --data "$SCRIPT" -H "Accept-API-Version:resource=1.0" -H "Content-Type:application/json" -H "X-Requested-With:XmlHttpRequest" $AM/json${REALM}/scripts/$each)
    if [ "$(echo $RESULT | jq '._id')" == "null" ]; then
        1>&2 echo "Error importing script $NAME ($each): $RESULT"
        1>&2 echo "$SCRIPT"
        exit -1
    fi
  done

  # Email Templates
  TEMPLATES=$(echo $TREES | jq -r  'try .emailTemplates | keys | .[]')
  for each in $TEMPLATES
  do
    TEMPLATE=$(echo $TREES | jq --arg template $each '.emailTemplates[$template]')
    TEMPLATEID=$(echo $TEMPLATE | jq -r '.name')
    1>&2 echo -n "."
    #1>&2 echo "Importing email template $each"
    RESULT=$(curl -s -k -X PUT --data-raw "$TEMPLATE" -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type:application/json" $BASE_HOST/openidm/config/emailTemplate/$each)
    if [ "$(echo $RESULT | jq '._id')" == "null" ]; then
      1>&2 echo "Error importing email template $each: $RESULT"
      1>&2 echo "$TEMPLATE"
      #exit -1
    fi
  done

  # Inner nodes
  # Currently the only node type containing inner nodes is "PageNode". Additional types can be defined in CONTAINERNODETYPES.
  INNERNODES=$(echo $TREES | jq -r  '.innernodes | keys | .[]')
  for each in $INNERNODES
  do
    INNERNODE=$(echo $TREES | jq --arg node $each '.innernodes[$node]')
    TYPE=$(echo $INNERNODE | jq -r '._type | ._id')
    if [ "$REUUID" == "true" ]; then
        NEWUUID=$(echo `uuidgen` | awk '{print tolower($0)}')
        HASHMAP=$(echo $HASHMAP | jq --arg old $each --arg new $NEWUUID '.map[$old]=$new')
    else
        NEWUUID=$(echo $INNERNODE | jq -r '._id')
    fi
    NEWNODE=$(echo $INNERNODE | jq ._id=\"${NEWUUID}\")
    1>&2 echo -n "."
    #1>&2 echo "Importing inner node $TYPE ($NEWUUID)"
    RESULT="null"
    retryCount=0
    while [ "$(echo $RESULT | jq '._id')" == "null" ]; do
      RESULT=$(curl -H "Cookie: $COOKIE_NAME=$AMSESSION" -s -k -X PUT --data "$NEWNODE" -H "Accept-API-Version:resource=1.0" -H "Content-Type:application/json" -H "X-Requested-With:XmlHttpRequest" $AM/json${REALM}/realm-config/authentication/authenticationtrees/nodes/$TYPE/$NEWUUID)
      retryCount=$((retryCount+1))
      sleep 2
      if [ "$retryCount" == "20" ]; then
        1>&2 echo "Error importing inner node $TYPE ($NEWUUID): $RESULT"
        1>&2 echo "$NEWNODE"
        exit -1
      elif [ "$(echo $RESULT | jq '._id')" == "null" ]; then
        1>&2 echo -n "*"
      fi
    done
  done

  # Nodes
  NODES=$(echo $TREES | jq -r  '.nodes | keys | .[]')
  for each in $NODES
  do
    NODE=$(echo $TREES | jq --arg node $each '.nodes[$node]')
    TYPE=$(echo $NODE | jq -r '._type | ._id')
    if [ "$REUUID" == "true" ]; then
        NEWUUID=$(echo `uuidgen` | awk '{print tolower($0)}')
        HASHMAP=$(echo $HASHMAP | jq --arg old $each --arg new $NEWUUID '.map[$old]=$new')
    else
        NEWUUID=$(echo $NODE | jq -r '._id')
    fi
    NEWNODE=$(echo $NODE | jq ._id=\"${NEWUUID}\")
    # Need to re-UUID page nodes
    if [[ "$TYPE" == "PageNode" && "$REUUID" == "true" ]]; then
      MAP=$(echo $HASHMAP| jq -r  '.map | keys | .[]' )
      for each in $MAP
      do
          NEW=$(echo $HASHMAP | jq -r --arg NODE "$each" '.map[$NODE]')
          NEWNODE=$(echo $NEWNODE | sed -e 's/'$each'/'$NEW'/g')
      done
    fi
    1>&2 echo -n "."
    #1>&2 echo "Importing node $TYPE ($NEWUUID)"
    RESULT="null"
    retryCount=0
    while [ "$(echo $RESULT | jq '._id')" == "null" ]; do
      1>&2 echo -n "*"
      RESULT=$(curl -H "Cookie: $COOKIE_NAME=$AMSESSION" -s -k -X PUT --data "$NEWNODE" -H "Accept-API-Version:resource=1.0" -H "Content-Type:application/json" -H "X-Requested-With:XmlHttpRequest" $AM/json${REALM}/realm-config/authentication/authenticationtrees/nodes/$TYPE/$NEWUUID)
      retryCount=$((retryCount+1))
      sleep 2
      if [ "$retryCount" == "20" ]; then
        1>&2 echo "Error importing node $TYPE ($NEWUUID): $RESULT"
        1>&2 echo "$NEWNODE"
        exit -1
      elif [ "$(echo $RESULT | jq '._id')" == "null" ]; then
        1>&2 echo -n "*"
      fi
    done
  done

  # Tree
  TREE=$(echo $TREES | jq -r  '.tree')
  ID="$1"
  IDFORURL=$(echo "$ID" | sed 's/ /%20/g') # replace any spaces with %20
  TREE=$(echo $TREE | jq --arg id "$ID" '._id=$id')
  if [ "$REUUID" == "true" ]; then
      MAP=$(echo $HASHMAP| jq -r  '.map | keys | .[]' )
      for each in $MAP
      do
          NEW=$(echo $HASHMAP | jq -r --arg NODE "$each" '.map[$NODE]')
          TREE=$(echo $TREE | sed -e 's/'$each'/'$NEW'/g')
      done
  fi
  #1>&2 echo "Importing tree $1"
  curl -H "Cookie: $COOKIE_NAME=$AMSESSION" -s -k -X PUT --data "$TREE" -H "Accept-API-Version:resource=1.0" -H "Content-Type:application/json" -H "X-Requested-With:XmlHttpRequest" "$AM/json${REALM}/realm-config/authentication/authenticationtrees/trees/$IDFORURL" > /dev/null
  1>&2 echo "."
}


function usage {
  1>&2 echo "Usage: $0 ( -e | -E | -i | -I | -l | -d | -P ) [options]"
  1>&2 echo
  1>&2 echo "Export, import, list, describe, and prune authentication journeys/trees in the"
  1>&2 echo "ForgeRock Identity Platform. The utility supports Identity Cloud, ForgeOps"
  1>&2 echo "(CDM/CDK) deployments, and classic deployments."
  1>&2 echo
  1>&2 echo "Actions/tasks (must specify only one):"
  1>&2 echo "  -e             Export an authentication journey/tree."
  1>&2 echo "  -E             Export all the journeys/trees in a realm."
  1>&2 echo "  -S             Export all the journeys/trees in a realm as separate files of the"
  1>&2 echo "                 format <journey/tree name>.json."
  1>&2 echo "  -s             Import all the journeys/trees in the current directory (*.json)."
  1>&2 echo "  -i             Import an authentication journey/tree."
  1>&2 echo "  -I             Import all the journeys/trees in a realm."
  1>&2 echo "  -d             If -h is supplied, describe the journey/tree indicated by -t, or"
  1>&2 echo "                 all journeys/trees in the realm if no -t is supplied, otherwise"
  1>&2 echo "                 describe the journey/tree export file indicated by -f."
  1>&2 echo "  -D             If -h is supplied, describe all the journeys/trees in the realm,"
  1>&2 echo "                 otherwise describe *.json files in the current directory."
  1>&2 echo "  -l             List all the journeys/trees in a realm."
  1>&2 echo "  -P             Prune orphaned configuration artifacts left behind after deleting"
  1>&2 echo "                 authentication trees. You will be prompted before any irreversible"
  1>&2 echo "                 operations are performed."
  1>&2 echo "  -z             Login, print versions and tokens, then exit."
  1>&2 echo
  1>&2 echo "Options:"
  1>&2 echo "-h url           Access Management base URL, e.g.: https://cdk.iam.example.com/am"
  1>&2 echo "-u user          Username to login with. Must be an admin user with appropriate"
  1>&2 echo "                 rights to manage authentication journeys/trees. For Identity Cloud"
  1>&2 echo "                 use a tenant admin account if possible."
  1>&2 echo "-p passwd        Password."
  1>&2 echo "-r realm         Realm. If not specified, the root realm '/' is assumed. Specify"
  1>&2 echo "                 realm as '/parent/child'. Note the leading '/'!"
  1>&2 echo "-f file          If supplied, export/list to and import from <file> instead of"
  1>&2 echo "                 stdout and stdin. For -S, use as file prefix"
  1>&2 echo "-t tree          Specify the name of an authentication journey/tree. Mandatory in"
  1>&2 echo "                 combination with the following actions: -i, -e, -d."
  1>&2 echo "-o version       Override version. Notation: \"X.Y.Z\" e.g. \"7.1.0\""
  1>&2 echo "                 Override detected version with any version. This is helpful in"
  1>&2 echo "                 order to check if journeys in one environment would be compatible"
  1>&2 echo "                 running in another environment (e.g. in preparation of migrating"
  1>&2 echo "                 from on-prem to ForgeRock Identity Cloud. Only impacts these"
  1>&2 echo "                 actions: -d, -l."
  1>&2 echo "-m type          Override auto-detected deployment type. Valid values for type:"
  1>&2 echo "                 Classic  - A classic Access Management-only deployment with custom"
  1>&2 echo "                            layout and configuration."
  1>&2 echo "                 Cloud    - A ForgeRock Identity Cloud environment."
  1>&2 echo "                 ForgeOps - A ForgeOps CDK or CDM deployment."
  1>&2 echo "                 The detected or provided deployment type controls certain behavior"
  1>&2 echo "                 like obtaining an Identity Management admin token or not and whether"
  1>&2 echo "                 to export/import referenced email templates or how to walk through"
  1>&2 echo "                 the tenant admin login flow of Identity Cloud and skip MFA."
  1>&2 echo "-n               No Re-UUID, i.e., import does not generate new UUIDs for (inner)nodes."
  1>&2 echo "                 Used to update existing trees/nodes instead of cloneing them."
  1>&2 echo "-c newRealmName  Clone mode i.e., Used when exporting auth trees as clones in the same"
  1>&2 echo "                 Classic ForgeRock instance from one Realm to another. It will duplicate"
  1>&2 echo "                 the scripts by prefixing with the "
  1>&2 echo
  1>&2 echo "Run $0 without any parameters to display this usage information."
  exit 0
}


TASK=""
while getopts "?iIeEldDzh:r:u:p:Pf:sSt:o:m:c:n" arg; do
    case $arg in
        e) TASK="export";;
        E) TASK="exportAll";;
        s) TASK="importTreesSeparately";;
        S) TASK="exportTreesSeparately";;
        i) TASK="import";;
        I) TASK="importAll";;
        l) TASK="list";;
        d) TASK="describe";;
        D) TASK="describeAll";;
        P) TASK="prune";;
        z) TASK="info";;
        h) AM="$OPTARG";;
        r) if [ $OPTARG == "/" ]; then REALM=""; else REALM="$OPTARG"; fi;;
        u) AMADMIN="$OPTARG";;
        p) AMPASSWD="$OPTARG";;
        f) FILE="$OPTARG";;
        t) TREENAME="$OPTARG";;
        o) OVERSION="$OPTARG";;
        m) DEPLOYMENT="$OPTARG";;
        n) REUUID="false";;
        c) CLONE="$OPTARG";;
        \?) echo "Unknown option: $arg"; usage;;
   esac
done

function checkParams {
    if [ "$TASK" == 'import' ] ; then
        # mandatory params:
        # -h: AM
        # -u: AMADMIN
        # -p: AMPASSWD
        # -t: TREENAME
        if [[ -z $AM ]] || [[ -z $AMADMIN ]] || [[ -z $AMPASSWD ]] || [[ -z $TREENAME ]] ; then
            1>&2 echo "Error: Missing mandatory parameter(s) for action/task!"
            1>&2 echo
            1>&2 echo "Action/task:"
            1>&2 echo "  -i         Import an authentication tree."
            1>&2 echo
            1>&2 echo "Mandatory options:"
            1>&2 echo "  -h url     Access Management base URL, e.g.: https://cdk.iam.example.com/am"
            1>&2 echo "  -u user    Username to login with. Must be an admin user with appropriate"
            1>&2 echo "             rights to manage authentication journeys/trees. For Identity Cloud"
            1>&2 echo "             use a tenant admin account if possible."
            1>&2 echo "  -p passwd  Password."
            1>&2 echo "  -t tree    Specify the name of an authentication journey/tree. Mandatory in"
            1>&2 echo "             combination with the following actions: -i, -e, -d."
            exit 1
        fi
    elif [ "$TASK" == 'importAll' ] ; then
        # mandatory params:
        # -h: AM
        # -u: AMADMIN
        # -p: AMPASSWD
        if [[ -z $AM ]] || [[ -z $AMADMIN ]] || [[ -z $AMPASSWD ]] ; then
            1>&2 echo "Error: Missing mandatory parameter(s) for action/task!"
            1>&2 echo
            1>&2 echo "Action/task:"
            1>&2 echo "  -I         Import all the trees in a realm."
            1>&2 echo
            1>&2 echo "Mandatory options:"
            1>&2 echo "  -h url     Access Management base URL, e.g.: https://cdk.iam.example.com/am"
            1>&2 echo "  -u user    Username to login with. Must be an admin user with appropriate"
            1>&2 echo "             rights to manage authentication journeys/trees. For Identity Cloud"
            1>&2 echo "             use a tenant admin account if possible."
            1>&2 echo "  -p passwd  Password."
            exit 1
        fi
    elif [ "$TASK" == 'export' ] ; then
        # mandatory params:
        # -h: AM
        # -u: AMADMIN
        # -p: AMPASSWD
        # -t: TREENAME
        if [[ -z $AM ]] || [[ -z $AMADMIN ]] || [[ -z $AMPASSWD ]] || [[ -z $TREENAME ]] ; then
            1>&2 echo "Error: Missing mandatory parameter(s) for action/task!"
            1>&2 echo
            1>&2 echo "Action/task:"
            1>&2 echo "  -e         Export an authentication tree."
            1>&2 echo
            1>&2 echo "Mandatory options:"
            1>&2 echo "  -h url     Access Management base URL, e.g.: https://cdk.iam.example.com/am"
            1>&2 echo "  -u user    Username to login with. Must be an admin user with appropriate"
            1>&2 echo "             rights to manage authentication journeys/trees. For Identity Cloud"
            1>&2 echo "             use a tenant admin account if possible."
            1>&2 echo "  -p passwd  Password."
            1>&2 echo "  -t tree    Specify the name of an authentication journey/tree. Mandatory in"
            1>&2 echo "             combination with the following actions: -i, -e, -d."
            exit 1
        fi
    elif [ "$TASK" == 'exportAll' ] ; then
        # mandatory params:
        # -h: AM
        # -u: AMADMIN
        # -p: AMPASSWD
        if [[ -z $AM ]] || [[ -z $AMADMIN ]] || [[ -z $AMPASSWD ]] ; then
            1>&2 echo "Error: Missing mandatory parameter(s) for action/task!"
            1>&2 echo
            1>&2 echo "Action/task:"
            1>&2 echo "  -E         Export all the trees in a realm."
            1>&2 echo
            1>&2 echo "Mandatory options:"
            1>&2 echo "  -h url     Access Management base URL, e.g.: https://cdk.iam.example.com/am"
            1>&2 echo "  -u user    Username to login with. Must be an admin user with appropriate"
            1>&2 echo "             rights to manage authentication journeys/trees. For Identity Cloud"
            1>&2 echo "             use a tenant admin account if possible."
            1>&2 echo "  -p passwd  Password."
            exit 1
        fi
    elif [ "$TASK" == 'exportTreesSeparately' ] ; then
        # mandatory params:
        # -h: AM
        # -u: AMADMIN
        # -p: AMPASSWD
        if [[ -z $AM ]] || [[ -z $AMADMIN ]] || [[ -z $AMPASSWD ]] ; then
            1>&2 echo "Error: Missing mandatory parameter(s) for action/task!"
            1>&2 echo
            1>&2 echo "Action/task:"
            1>&2 echo "  -S         Export all the trees in a realm as separate files of the format"
            1>&2 echo "             FileprefixTreename.json."
            1>&2 echo
            1>&2 echo "Mandatory options:"
            1>&2 echo "  -h url     Access Management base URL, e.g.: https://cdk.iam.example.com/am"
            1>&2 echo "  -u user    Username to login with. Must be an admin user with appropriate"
            1>&2 echo "             rights to manage authentication journeys/trees. For Identity Cloud"
            1>&2 echo "             use a tenant admin account if possible."
            1>&2 echo "  -p passwd  Password."
            exit 1
        fi
    elif [ "$TASK" == 'importTreesSeparately' ] ; then
        # mandatory params:
        # -h: AM
        # -u: AMADMIN
        # -p: AMPASSWD
        if [[ -z $AM ]] || [[ -z $AMADMIN ]] || [[ -z $AMPASSWD ]] ; then
            1>&2 echo "Error: Missing mandatory parameter(s) for action/task!"
            1>&2 echo
            1>&2 echo "Action/task:"
            1>&2 echo "  -s         Import all the trees in the current directory"
            1>&2 echo
            1>&2 echo "Mandatory options:"
            1>&2 echo "  -h url     Access Management base URL, e.g.: https://cdk.iam.example.com/am"
            1>&2 echo "  -u user    Username to login with. Must be an admin user with appropriate"
            1>&2 echo "             rights to manage authentication journeys/trees. For Identity Cloud"
            1>&2 echo "             use a tenant admin account if possible."
            1>&2 echo "  -p passwd  Password."
            exit 1
        fi
    elif [ "$TASK" == 'list' ] ; then
        # mandatory params:
        # -h: AM
        # -u: AMADMIN
        # -p: AMPASSWD
        if [[ -z $AM ]] || [[ -z $AMADMIN ]] || [[ -z $AMPASSWD ]] ; then
            1>&2 echo "Error: Missing mandatory parameter(s) for action/task!"
            1>&2 echo
            1>&2 echo "Action/task:"
            1>&2 echo "  -l         List all the trees in a realm."
            1>&2 echo
            1>&2 echo "Mandatory options:"
            1>&2 echo "  -h url     Access Management base URL, e.g.: https://cdk.iam.example.com/am"
            1>&2 echo "  -u user    Username to login with. Must be an admin user with appropriate"
            1>&2 echo "             rights to manage authentication journeys/trees. For Identity Cloud"
            1>&2 echo "             use a tenant admin account if possible."
            1>&2 echo "  -p passwd  Password."
            exit 1
        fi
    elif [ "$TASK" == 'describe' ] ; then
        # mandatory params:
        # -h: AM
        # -u: AMADMIN
        # -p: AMPASSWD
        #
        # OR
        #
        # -f: FILE

        # only -h supplied
        if [[ -n $AM ]] && [[ -z $FILE ]] ; then
            if [[ -z $AMADMIN ]] || [[ -z $AMPASSWD ]] ; then
                1>&2 echo "Error: Missing mandatory parameter(s) for action/task!"
                1>&2 echo
                1>&2 echo "Action/task:"
                1>&2 echo "  -d         If -h is supplied, describe the indicated tree in the realm,"
                1>&2 echo "             otherwise describe the tree export file indicated by -f"
                1>&2 echo
                1>&2 echo "Mandatory options:"
                1>&2 echo "  -h url     Access Management base URL, e.g.: https://cdk.iam.example.com/am"
                1>&2 echo "  -u user    Username to login with. Must be an admin user with appropriate"
                1>&2 echo "             rights to manage authentication journeys/trees. For Identity Cloud"
                1>&2 echo "             use a tenant admin account if possible."
                1>&2 echo "  -p passwd  Password."
                exit 1
            fi

        # only -f supplied
        elif [[ -n $FILE ]] && [[ -z $AM ]] ; then
            true = true

        # neither -h nor -f supplied
        elif [[ -z $FILE ]] && [[ -z $AM ]] ; then
            1>&2 echo "Error: Missing mandatory parameter(s) for action/task!"
            1>&2 echo
            1>&2 echo "Action/task:"
            1>&2 echo "  -d         If -h is supplied, describe the indicated tree in the realm,"
            1>&2 echo "             otherwise describe the tree export file indicated by -f"
            1>&2 echo
            1>&2 echo "Mandatory options:"
            1>&2 echo "  -h url     Access Management base URL, e.g.: https://cdk.iam.example.com/am"
            1>&2 echo "  -u user    Username to login with. Must be an admin user with appropriate"
            1>&2 echo "             rights to manage authentication journeys/trees. For Identity Cloud"
            1>&2 echo "             use a tenant admin account if possible."
            1>&2 echo "  -p passwd  Password."
            1>&2 echo "  -f file    If supplied, export/list to and import from <file> instead of stdout"
            1>&2 echo "             and stdin. For -S, use as file prefix"
            exit 1

        # both -h and -f supplied
        elif [[ -n $FILE ]] && [[ -n $AM ]] ; then
            1>&2 echo "Error: Conflicting parameters supplied: Use -h or -f but not both."
            1>&2 echo
            1>&2 echo "Action/task:"
            1>&2 echo "  -d         If -h is supplied, describe the indicated tree in the realm,"
            1>&2 echo "             otherwise describe the tree export file indicated by -f"
            1>&2 echo
            1>&2 echo "Mandatory options:"
            1>&2 echo "  -h url     Access Management base URL, e.g.: https://cdk.iam.example.com/am"
            1>&2 echo "  -u user    Username to login with. Must be an admin user with appropriate"
            1>&2 echo "             rights to manage authentication journeys/trees. For Identity Cloud"
            1>&2 echo "             use a tenant admin account if possible."
            1>&2 echo "  -p passwd  Password."
            1>&2 echo "  -f file    If supplied, export/list to and import from <file> instead of stdout"
            1>&2 echo "             and stdin. For -S, use as file prefix"
            exit 1
        fi
    elif [ "$TASK" == 'describeAll' ] ; then
        true = true

    elif [ "$TASK" == 'prune' ] ; then
        # mandatory params:
        # -h: AM
        # -u: AMADMIN
        # -p: AMPASSWD
        if [[ -z $AM ]] || [[ -z $AMADMIN ]] || [[ -z $AMPASSWD ]] ; then
            1>&2 echo "Error: Missing mandatory parameter(s) for action/task!"
            1>&2 echo
            1>&2 echo "Action/task:"
            1>&2 echo "  -P         Prune orphaned configuration artifacts left behind after deleting"
            1>&2 echo "             authentication trees. You will be prompted before any destructive"
            1>&2 echo "             operations are performed."
            1>&2 echo
            1>&2 echo "Mandatory options:"
            1>&2 echo "  -h url     Access Management base URL, e.g.: https://cdk.iam.example.com/am"
            1>&2 echo "  -u user    Username to login with. Must be an admin user with appropriate"
            1>&2 echo "             rights to manage authentication journeys/trees. For Identity Cloud"
            1>&2 echo "             use a tenant admin account if possible."
            1>&2 echo "  -p passwd  Password."
            exit 1
        fi

    elif [ "$TASK" == 'info' ] ; then
        # mandatory params:
        # -h: AM
        # -u: AMADMIN
        # -p: AMPASSWD
        if [[ -z $AM ]] || [[ -z $AMADMIN ]] || [[ -z $AMPASSWD ]] ; then
            1>&2 echo "Error: Missing mandatory parameter(s) for action/task!"
            1>&2 echo
            1>&2 echo "Action/task:"
            1>&2 echo "  -z         Login, print versions and tokens, then exit."
            1>&2 echo
            1>&2 echo "Mandatory options:"
            1>&2 echo "  -h url     Access Management base URL, e.g.: https://cdk.iam.example.com/am"
            1>&2 echo "  -u user    Username to login with. Must be an admin user with appropriate"
            1>&2 echo "             rights to manage authentication journeys/trees. For Identity Cloud"
            1>&2 echo "             use a tenant admin account if possible."
            1>&2 echo "  -p passwd  Password."
            exit 1
        fi
    fi

    # Validate -r realm param
    if [[ $REALM != "" ]] ; then
        if [[ $REALM != /* ]] ; then
            1>&2 echo "Error: Invalid realm: '$REALM'! Must start with a leading '/'"
            1>&2 echo
            1>&2 echo "  -r realm   Realm. If not specified, the root realm '/' is assumed. Specify"
            1>&2 echo "             realm as '/parent/child'. Note the leading '/'!"
            exit 1
        fi
    fi

    # Validate -m type param
    if [[ $DEPLOYMENT != "" ]] ; then
        shopt -s nocasematch
        if [[ "$DEPLOYMENT" != "Cloud" ]] && [[ "$DEPLOYMENT" != "ForgeOps" ]] && [[ "$DEPLOYMENT" != "Classic" ]] ; then
            1>&2 echo "Error: Invalid deployment type: '$DEPLOYMENT'!"
            1>&2 echo
            1>&2 echo "  -m type    Override auto-detected deployment type. Valid values for type:"
            1>&2 echo "             Classic  - A classic Access Management-only deployment with custom"
            1>&2 echo "                        layout and configuration."
            1>&2 echo "             Cloud    - A ForgeRock Identity Cloud environment."
            1>&2 echo "             ForgeOps - A ForgeOps CDK or CDM deployment."
            1>&2 echo "             The detected or provided deployment type controls certain behavior"
            1>&2 echo "             like obtaining an Identity Management admin token or not and whether"
            1>&2 echo "             to export/import referenced email templates or how to walk through"
            1>&2 echo "             the tenant admin login flow of Identity Cloud and skip MFA."
            shopt -u nocasematch
            exit 1
        fi
    fi
}

checkParams

if [ "$TASK" == 'import' ] ; then
    login
    importTree "$TREENAME"
elif [ "$TASK" == 'importAll' ] ; then
    login
    importAllTrees
elif [ "$TASK" == 'export' ] ; then
    login
    if [[ -n $FILE ]]; then
        echo "" > "$FILE"
    fi
    exportTree "$TREENAME"
elif [ "$TASK" == 'exportAll' ] ; then
    login
    exportAllTrees
elif [ "$TASK" == 'exportTreesSeparately' ] ; then
    login
    exportTreesSeparately
elif [ "$TASK" == 'importTreesSeparately' ] ; then
    login
    importTreesSeparately
elif [ "$TASK" == 'list' ] ; then
    login
    listTrees
elif [ "$TASK" == 'describe' ] ; then
    describeTree
elif [ "$TASK" == 'describeAll' ] ; then
    describeAllTrees
elif [ "$TASK" == 'prune' ] ; then
    login
    prune
elif [ "$TASK" == 'info' ] ; then
    login
    if [ ! -z "$AMSESSION" ] ; then
        1>&2 echo "AM session: $AMSESSION"
    fi
    if [ ! -z "$ACCESS_TOKEN" ] ; then
        1>&2 echo "IDM admin token: $ACCESS_TOKEN"
    fi
else
    usage
fi
