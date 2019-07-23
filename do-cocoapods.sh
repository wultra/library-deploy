#!/bin/bash

# -----------------------------------------------------------------------------
# Internal function, validates whether we have all prerequisites. 
# -----------------------------------------------------------------------------
function VALIDATE_COCOAPODS
{
	if [ -z "$DEPLOY_POD_NAME" ]; then
		FAILURE "There's no DEPLOY_POD_NAME variable in '$DEPLOY_INFO' file."
	fi
	local PODSPEC="${DEPLOY_POD_NAME}.podspec"
	if [ ! -f ${PODSPEC} ]; then
		FAILURE "Look's like that repository doesn't contain '${PODSPEC}' file."
	fi
}

# -----------------------------------------------------------------------------
# Deploys build for swift, with using cocoapods. Script is executed in ${REPO_DIR}
# Parameters:
#   $1   - version
#   $2   - deploy command (push | prepare)
#
# Expected global variables:
#  	DEPLOY_POD_NAME		- name of pod
# -----------------------------------------------------------------------------
function DO_DEPLOY
{
	local VER=$1
	local DEPLOY_COMMAND=$2
	local VERBOSE_SWITCH=""
	
	if [ x$VERBOSE == x2 ]; then
	    VERBOSE_SWITCH="--verbose"
	fi
	if [ x$ALLOW_WARNINGS == x1 ]; then
		VERBOSE_SWITCH="${VERBOSE_SWITCH} --allow-warnings"
	fi
	
	# validate variables and input parameters
	VALIDATE_COCOAPODS
	
	local PODSPEC="${DEPLOY_POD_NAME}.podspec"
	
	if [ "$DEPLOY_COMMAND" == "prepare" ]; then
		
		LOG "----- Validating ${PODSPEC}..."
		pod lib lint ${PODSPEC} ${VERBOSE_SWITCH}
		
	elif [ "$DEPLOY_COMMAND" == "deploy" ]; then
		
		LOG "----- Publishing ${PODSPEC}..."
		pod trunk push ${PODSPEC} ${VERBOSE_SWITCH}
		
	else
		FAILURE "do-cocoapods.sh doesn't support '$DEPLOY_COMMAND' command"
	fi
}

# -----------------------------------------------------------------------------
# Prepares tag message for library. Script is executed in ${REPO_DIR}
# Parameters:
#   $1   - version
#
# Expected global variables:
#  	DEPLOY_POD_NAME		- name of pod
#
# Prepares
#	DEPLOY_TAG_MESSAGE	- Message for adding tag
# -----------------------------------------------------------------------------
function DO_PREPARE_TAG_MESSAGE
{
	VALIDATE_COCOAPODS
	DEPLOY_TAG_MESSAGE="${DEPLOY_POD_NAME} version $1"
}