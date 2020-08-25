#!/bin/bash

# -----------------------------------------------------------------------------
# Internal function, validates whether we have all prerequisites. 
# -----------------------------------------------------------------------------
function VALIDATE_NPM
{
	if [ ! -f "package.json" ]; then
		FAILURE "Look's like that repository doesn't contain 'package.json' file."
	fi
}

# -----------------------------------------------------------------------------
# Deploys node package using npm. Script is executed in ${REPO_DIR}
# Parameters:
#   $1   - version
#   $2   - deploy command (push | prepare)
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
	VALIDATE_NPM
	
	if [ "$DEPLOY_COMMAND" == "prepare" ]; then
		
		LOG "----- Validating..."
		npm publish --dry-run
		
	elif [ "$DEPLOY_COMMAND" == "deploy" ]; then
		
		LOG "----- Publishing..."
		npm publish
		
	else
		FAILURE "do-npm.sh doesn't support '$DEPLOY_COMMAND' command"
	fi
}

# -----------------------------------------------------------------------------
# Prepares tag message for library. Script is executed in ${REPO_DIR}
# Parameters:
#   $1   - version
# -----------------------------------------------------------------------------
function DO_PREPARE_TAG_MESSAGE
{
	VALIDATE_NPM
	DEPLOY_TAG_MESSAGE="Version $1"
}