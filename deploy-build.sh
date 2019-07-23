#!/bin/bash
###############################################################################
# Include common functions...
# -----------------------------------------------------------------------------
TOP=$(dirname $0)
source "${TOP}/common-functions.sh"

# -----------------------------------------------------------------------------
# USAGE prints help and exits the script with error code from provided parameter
# Parameters:
#   $1   - error code to be used as return code from the script
# -----------------------------------------------------------------------------
function USAGE
{
	echo ""
	echo "Usage:  $CMD  repo-dir  version  [command]"
	echo ""
	echo "repo-dir            path to git repository with library sources"
	echo ""
	echo "version             is version to be published to repositories"
	echo "                      Only X.Y.Z format is accepted"
	echo ""
	echo "command             is command performed with the version:"
	echo ""
	echo "    prepare           prepare files for deployment"
	echo "    push              push changes to git"
	echo "    deploy            deploy changes to public repository"
	echo "    merge             merges changes to master branch"
	echo ""
	echo "                    if command is not used, then script will"
	echo "                    execute commands in following order:"
	echo "                    'prepare', 'push', 'deploy' and 'merge'"
	echo ""
	echo "options are:"
	echo "    -v0               turn off all prints to stdout"
	echo "    -v1               print only basic log about build progress"
	echo "    -v2               print full build log with rich debug info"
	echo "    -h | --help       print this help information"
	echo ""
	echo "    -dm target | --do-more-target target"
	echo "                      specifies target for do-more.sh deployment"
	echo "                      If specified, then only target will be executed"
	echo ""
	echo "    --any-branch      specifies that deployment is possible from"
	echo "                      any branch. Be careful with this option."
	echo ""
	echo "    --allow-warnings  forces deployment even if some step reported"
	echo "                      an ignorable warning."
	echo ""
	exit $1
}

###############################################################################
# Config
DEPLOY_INFO=".limedeploy"
MASTER_BRANCH="master"
DEV_BRANCH="develop"

# Runtime global vars
GIT_VALIDATE_DEVELOPMENT_BRANCH=1
GIT_SKIP_TAGS=0
GIT_ONLY_TAGS=0
STANDARD_BRANCH=0
COMMAND='all'
VERSION=''
REPO_DIR=''
DO_MORE_TARGET=''
ALLOW_WARNINGS=0

# -----------------------------------------------------------------------------
# Validate whether git branch is 'develop'
# -----------------------------------------------------------------------------
function VALIDATE_GIT_STATUS
{
	LOG "----- Validating git status..."
	PUSH_DIR "${REPO_DIR}"
	####
	local GIT_CURRENT_CHANGES=`git status -s`
	if [ ! -z "$GIT_CURRENT_CHANGES" ]; then
		FAILURE "Git status must be clean."
	fi

	local GIT_CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
	if [ x$GIT_VALIDATE_DEVELOPMENT_BRANCH == x1 ]; then
		if [ "$GIT_CURRENT_BRANCH" != ${DEV_BRANCH} ]; then
			FAILURE "You have to be at '${DEV_BRANCH}' git branch."
		fi
		STANDARD_BRANCH=1
	else
		WARNING "Going to publish '${VERSION}' from non-standard branch '${GIT_CURRENT_BRANCH}'"
		STANDARD_BRANCH=0
	fi

	git fetch origin
	####
	POP_DIR
}

# -----------------------------------------------------------------------------
# Loads '.limedeploy' file from {REPO_DIR}
# -----------------------------------------------------------------------------
function LOAD_DEPLOY_INFO_FILE
{
	PUSH_DIR "${REPO_DIR}"
	####
	if [ -f ${DEPLOY_INFO} ]; then
		source ${DEPLOY_INFO}
		# validate variables imported from .limedeploy
		if [ -z "${DEPLOY_MODE}" ]; then
			FAILURE "File `${DEPLOY_INFO}` found, but doesn't contain required properties."
		fi
		if [ -z "$DEPLOY_VERSIONING_FILES" ]; then
			if [ -z "$NO_DEPLOY_VERSIONING_FILES" ]; then
				FAILURE "DEPLOY_VERSIONING_FILES or NO_DEPLOY_VERSIONING_FILES variable must be set in '${DEPLOY_INFO}'."
			fi
		fi
	else
		FAILURE "Repository doesn't contain '${DEPLOY_INFO}' file."
	fi
	
	local MODE_IMPL="${TOP}/do-${DEPLOY_MODE}.sh"
	if [ ! -f "${MODE_IMPL}" ]; then
		FAILURE "There's no deployment script for '${DEPLOY_MODE}' mode."
	fi
	source "${MODE_IMPL}"
	
	# Prepare tag message
	DO_PREPARE_TAG_MESSAGE ${VERSION}
	if [ -z "${DEPLOY_TAG_MESSAGE}" ]; then
		WARNING "'${DEPLOY_MODE}' mode script failed to prepare message for TAG"
	else
		DEPLOY_TAG_MESSAGE="Version ${VERSION}"
	fi
	
	####
	POP_DIR
}

# -----------------------------------------------------------------------------
# Executes "DO_DEPLOY" or custom function with given parameters
# -----------------------------------------------------------------------------
function EXECUTE_DO_DEPLOY
{
    if [ -z "$DO_DEPLOY_CUSTOM_FUNCTION" ]; then
        DO_DEPLOY "$@"
    else
        $DO_DEPLOY_CUSTOM_FUNCTION "$@"
    fi
}

# -----------------------------------------------------------------------------
# Patches all files to required version string and creates tagged commit with
# this change.
# -----------------------------------------------------------------------------
function PATCH_VERSIONING_FILES
{
	PUSH_DIR "${REPO_DIR}"
	####
	LOG "----- Patching files to ${VERSION}..."
	if [ -z "$NO_DEPLOY_VERSIONING_FILES" ]; then
		for (( i=0; i<${#DEPLOY_VERSIONING_FILES[@]}; i++ ));
		do
			local patch_info="${DEPLOY_VERSIONING_FILES[$i]}"
			local files=(${patch_info//,/ })
			local template="${files[0]}"
			local target="${files[1]}"
			local template_file="${REPO_DIR}/$template"
			local target_file="${REPO_DIR}/$target"
			if [ ! -f "$template_file" ]; then
				FAILURE "Template file not found: $template_file"
			fi
			if [ ! -f "$target_file" ]; then
				FAILURE "Target should exist: $target_file"
			fi
			
			LOG "        + ${target}"
			sed -e "s/%DEPLOY_VERSION%/$VERSION/g" "$template_file" > "$target_file"
			git add "$target_file"
		done
			
		LOG "----- Commiting versioning files..."
		git commit -m "Deployment: Update versioning file[s] to ${VERSION}"
		
	else
		FAILURE "Looks like this library has no versioning files defined."
	fi
		
	LOG "----- Tagging version ${VERSION}..."
	git tag -a ${VERSION} -m "${DEPLOY_TAG_MESSAGE}"
	
	####
	POP_DIR
} 

# -----------------------------------------------------------------------------
# Checks whether version already exists (has tag in git) and if not then
# prepares versioning files.
# -----------------------------------------------------------------------------
function PREPARE_VERSIONING_FILES
{
	local CURRENT_TAGS=(`git tag -l`)
	local TAG	
	local SKIP_CREATE=0
	for TAG in ${CURRENT_TAGS[@]}; do
		if [ "$TAG" == ${VERSION} ]; then 
			WARNING "Version '${VERSION}' is already tagged. Skipping files creation."
			return
		fi 
	done
	PATCH_VERSIONING_FILES
}


# -----------------------------------------------------------------------------
# Prepares local files which contains version string, then commits those
# files with appropriate tag and pushes everything to the remote git repository
# -----------------------------------------------------------------------------
function PUSH_VERSIONING_FILES
{	
	PUSH_DIR "${REPO_DIR}"
	###
	LOG "----- Pushing changes to git..."
	git push --follow-tags 
	####
	POP_DIR
}

# -----------------------------------------------------------------------------
# Merges recent changes to the 'master' branch
# -----------------------------------------------------------------------------
function MERGE_TO_MASTER
{
	PUSH_DIR "${REPO_DIR}"
	####
	LOG "----- Merging to '${MASTER_BRANCH}'..."
	git fetch origin
	git checkout ${MASTER_BRANCH}
	git rebase origin/${DEV_BRANCH}
	git push
	git checkout ${DEV_BRANCH}
	####
	POP_DIR
}


###############################################################################
# Script's main execution starts here...
# -----------------------------------------------------------------------------
PINDEX=0
while [[ $# -gt 0 ]]
do
	opt="$1"
	case "$opt" in
		-h | --help)
			USAGE 0
			;;
		-v*)
			SET_VERBOSE_LEVEL_FROM_SWITCH $opt 
			;;
		--any-branch)
			GIT_VALIDATE_DEVELOPMENT_BRANCH=0
			;;
		prepare | push | deploy | merge)
			COMMAND=$opt
			;;
		-dm | --do-more-target)
		    DO_MORE_TARGET="$2"
		    shift
		    ;;
		--allow-warnings)
			ALLOW_WARNINGS=1
			;;
		*)
			if [ x$PINDEX == x0 ]; then
				REPO_DIR="$opt"
				PINDEX=1
			elif [ x$PINDEX == x1 ]; then
				VALIDATE_AND_SET_VERSION_STRING $opt
				PINDEX=2
			else
				FAILURE "Unknown parameter '$opt'"
			fi
			;;
	esac
	shift
done
#
# Mandatory parameters validation
#
if [ -z "$REPO_DIR" ]; then
	FAILURE "You have to provide path to repository."
fi
if [ -z "$VERSION" ]; then
	FAILURE "You have to provide version string."
fi
if [ ! -d "$REPO_DIR" ]; then
	FAILURE "Provided path is not a directory: $REPO_DIR"
fi

# Full path to REPO_DIR
REPO_DIR="`( cd \"$REPO_DIR\" && pwd )`"

#
# Main job starts here...
#

VALIDATE_GIT_STATUS
LOAD_DEPLOY_INFO_FILE

PUSH_DIR "${REPO_DIR}"
####
case "$COMMAND" in
	prepare)
		PREPARE_VERSIONING_FILES
		EXECUTE_DO_DEPLOY $VERSION 'prepare'
		;;
	push)
		PUSH_VERSIONING_FILES
		;;
	deploy)
		EXECUTE_DO_DEPLOY $VERSION 'deploy'
		;;
	merge)
		MERGE_TO_MASTER
		;;
	all)
		PREPARE_VERSIONING_FILES
		EXECUTE_DO_DEPLOY $VERSION 'prepare'
		PUSH_VERSIONING_FILES
		EXECUTE_DO_DEPLOY $VERSION 'deploy'
		MERGE_TO_MASTER
		;;	
esac
####
POP_DIR

EXIT_SUCCESS
