#!/bin/bash

# -----------------------------------------------------------------------------
# Internal function, validates whether we have all prerequisites. 
# -----------------------------------------------------------------------------
function VALIDATE_SCRIPT_PARAMS
{
    [[ -z "$DEPLOY_SCRIPT_DEPLOY" ]] && FAILURE "Missing \$DEPLOY_SCRIPT_DEPLOY variable in .limedeploy file."
}

# -----------------------------------------------------------------------------
# Deploys library using custom command. Script is executed in ${REPO_DIR}
# Parameters:
#   $1   - version
#   $2   - deploy command (push | prepare)
#
# Expected global variables:
#   DEPLOY_SCRIPT_PREPARE           - optional script command to execute on prepare task.
#   DEPLOY_SCRIPT_DEPLOY            - script command to execute on deploy task.
# -----------------------------------------------------------------------------
function DO_DEPLOY
{
    local VER=$1
    local DEPLOY_COMMAND=$2
    
    # validate variables and input parameters
    VALIDATE_SCRIPT_PARAMS
    
    if [ "$DEPLOY_COMMAND" == "prepare" ]; then
        
        LOG "----- Validating..."
        
        if [ ! -z "$DEPLOY_SCRIPT_PREPARE" ]; then
            local EVAL_COMMAND=${DEPLOY_SCRIPT_PREPARE/\%DEPLOY_VERSION\%/$VER}
            DEBUG_LOG "Going to execute 'eval $EVAL_COMMAND'"
            eval $EVAL_COMMAND
        else
            LOG "Skipping preparation step due to missing \$DEPLOY_SCRIPT_PREPARE variable in .limedeploy file."
        fi
        
    elif [ "$DEPLOY_COMMAND" == "deploy" ]; then
        
        LOG "----- Publishing..."
        
        local EVAL_COMMAND=${DEPLOY_SCRIPT_DEPLOY/\%DEPLOY_VERSION\%/$VER}
        DEBUG_LOG "Going to execute 'eval $EVAL_COMMAND'"
        eval $EVAL_COMMAND
        
    else
        FAILURE "do-script.sh doesn't support '$DEPLOY_COMMAND' command"
    fi
}

# -----------------------------------------------------------------------------
# Prepares tag message for library. Script is executed in ${REPO_DIR}
# Parameters:
#   $1   - version
# -----------------------------------------------------------------------------
function DO_PREPARE_TAG_MESSAGE
{
    VALIDATE_SCRIPT_PARAMS
    DEPLOY_TAG_MESSAGE="Version $1"
}