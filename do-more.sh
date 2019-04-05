#!/bin/bash

DO_DEPLOY_CUSTOM_FUNCTION='DO_DEPLOY_more'

# -----------------------------------------------------------------------------
# Internal function, validates whether we have all prerequisites. 
# -----------------------------------------------------------------------------
function VALIDATE_MORE_PARAMS
{
	if [ -z "$DEPLOY_LIB_NAME" ]; then
		FAILURE "There's no DEPLOY_LIB_NAME variable in '$DEPLOY_INFO' file."
	fi
	if [ -z "$DEPLOY_MORE_TARGETS" ]; then
	    FAILURE "There's no DEPLOY_MORE_TARGETS variable in '$DEPLOY_INFO' file."
    fi
}

# -----------------------------------------------------------------------------
# Deploys build with using multiple do-scripts. Script is executed in ${REPO_DIR}
# Parameters:
#   $1   - version
#   $2   - deploy command (push | prepare)
#
# Expected global variables:
#  	DEPLOY_LIB_NAME		    - name of library
#   DEPLOY_MORE_TARGETS     - list of "do" script targets
# -----------------------------------------------------------------------------
function DO_DEPLOY_more
{
    local VER=$1
	local DEPLOY_COMMAND=$2
	
    VALIDATE_MORE_PARAMS
    
    for target in $DEPLOY_MORE_TARGETS
    do
        if [ "$target" == "more" ]; then
            FAILURE "do-more.sh cannot execute itself."
        fi
        local MODE_IMPL="${TOP}/do-${target}.sh"
    	if [ ! -f "${MODE_IMPL}" ]; then
    		FAILURE "There's no deployment script for '${target}' mode."
    	fi
    	
    	if [ "$DEPLOY_COMMAND" == "prepare" ]; then
    		LOG "----- Running validate for '$target' ..."
    	elif [ "$DEPLOY_COMMAND" == "deploy" ]; then
    		LOG "----- Running deploy for '$target' ..."
    	fi
    	
    	# Read do-script
    	DO_DEPLOY_CUSTOM_FUNCTION=""
    	source "${MODE_IMPL}"
    	
    	# Execute "DO_DEPLOY" or custom function
    	if [ -z "$DO_DEPLOY_CUSTOM_FUNCTION" ]; then
    	    DO_DEPLOY "$@"
	    else
	        $DO_DEPLOY_CUSTOM_FUNCTION "$@"
        fi
    done
    
    # Make sure that DO_DEPLOY_CUSTOM_FUNCTION is still "ours"
    DO_DEPLOY_CUSTOM_FUNCTION='DO_DEPLOY_more'
}

# -----------------------------------------------------------------------------
# Prepares tag message for library. Script is executed in ${REPO_DIR}
# Parameters:
#   $1   - version
#
# Expected global variables:
#  	DEPLOY_LIB_NAME		- name of pod
#
# Prepares
#	DEPLOY_TAG_MESSAGE	- Message for adding tag
# -----------------------------------------------------------------------------
function DO_PREPARE_TAG_MESSAGE
{
	VALIDATE_MORE_PARAMS
	DEPLOY_TAG_MESSAGE="$DEPLOY_LIB_NAME version $1"
}