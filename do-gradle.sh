#!/bin/bash

# -----------------------------------------------------------------------------
# Internal function, validates whether we have all prerequisites. 
# -----------------------------------------------------------------------------
function VALIDATE_GRADLE_PARAMS
{
    if [ -z "$DEPLOY_LIB_NAME" ]; then
		FAILURE "There's no DEPLOY_LIB_NAME variable in '$DEPLOY_INFO' file."
	fi
	if [ -z "$DEPLOY_GRADLE_PARAMS" ]; then
		FAILURE "There's no DEPLOY_GRADLE_PARAMS variable in '$DEPLOY_INFO' file."
	fi
	if [ -z "$DEPLOY_GRADLE_PREPARE_PARAMS" ]; then
	    DEBUG_LOG "DEPLOY_GRADLE_PREPARE_PARAMS variable defaulting to 'clean assembleRelease'."
	    DEPLOY_GRADLE_PREPARE_PARAMS="clean assembleRelease"
    fi
	if [ -z "$DEPLOY_GRADLE_PATH" ]; then
	    DEBUG_LOG "DEPLOY_GRADLE_PATH variable defaulting to repo folder."
	    DEPLOY_GRADLE_PATH="."
    fi
    if [ ! -f "${REPO_DIR}/${DEPLOY_GRADLE_PATH}/gradlew" ]; then
        FAILURE "There's no 'gradlew' file in '${DEPLOY_GRADLE_PATH}' directory."
    fi
}

# -----------------------------------------------------------------------------
# Deploys build for swift, with using gradle. Script is executed in ${REPO_DIR}
# Parameters:
#   $1   - version
#   $2   - deploy command (push | prepare)
#
# Expected global variables:
#  	DEPLOY_LIB_NAME		            - library's name
#   DEPLOY_GRADLE_PARAMS            - params for deployment
#   DEPLOY_GRADLE_PREPARE_PARAMS    - (optional) params for prepare command
#   DEPLOY_GRADLE_PATH              - (optional) path to gradle build system
# -----------------------------------------------------------------------------
function DO_DEPLOY
{
	local VER=$1
	local DEPLOY_COMMAND=$2
	local VERBOSE_SWITCH="--quiet"
	
	if [ x$VERBOSE == x2 ]; then
	    VERBOSE_SWITCH="--debug"
	fi
	
	# validate variables and input parameters
	VALIDATE_GRADLE_PARAMS
	
	PUSH_DIR "${REPO_DIR}/${DEPLOY_GRADLE_PATH}"
	####
	
	if [ "$DEPLOY_COMMAND" == "prepare" ]; then
		
		LOG "----- Validating ${DEPLOY_LIB_NAME}..."
		./gradlew ${VERBOSE_SWITCH} ${DEPLOY_GRADLE_PREPARE_PARAMS}
		
	elif [ "$DEPLOY_COMMAND" == "deploy" ]; then
		
		LOG "----- Publishing ${DEPLOY_LIB_NAME}..."
	    ./gradlew ${VERBOSE_SWITCH} ${DEPLOY_GRADLE_PARAMS}
		
	else
		FAILURE "do-gradle.sh doesn't support '$DEPLOY_COMMAND' command"
	fi
	
	####
	POP_DIR
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
	VALIDATE_GRADLE_PARAMS
	DEPLOY_TAG_MESSAGE="${DEPLOY_LIB_NAME} version $1"
}