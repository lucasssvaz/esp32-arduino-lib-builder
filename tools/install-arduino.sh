#/bin/bash

source ./tools/config.sh

#
# CLONE/UPDATE ARDUINO
#
echo "Updating ESP32 Arduino..."
if [ ! -d "$AR_COMPS/arduino" ]; then
	git clone $AR_REPO_URL "$AR_COMPS/arduino"
fi

if [ -z $AR_SOURCE_BRANCH ]; then
	if [ -z $GITHUB_HEAD_REF ]; then
		current_branch=`git branch --show-current`
	else
		current_branch="$GITHUB_HEAD_REF"
	fi
	echo "Current Branch: $current_branch"
	if [[ "$current_branch" != "master" && `git_branch_exists "$AR_COMPS/arduino" "$current_branch"` == "1" ]]; then
		export AR_SOURCE_BRANCH="$current_branch"
	else
		if [ "$IDF_COMMIT" ]; then #commit was specified at build time
			AR_SOURCE_BRANCH_CANDIDATE="idf-$IDF_COMMIT"
		elif [ "$IDF_TAG" ]; then #tag was specified at build time
			AR_SOURCE_BRANCH_CANDIDATE="idf-$IDF_TAG"
		else
			AR_SOURCE_BRANCH_CANDIDATE="idf-$IDF_BRANCH"
		fi
		has_ar_branch=`git_branch_exists "$AR_COMPS/arduino" "$AR_SOURCE_BRANCH_CANDIDATE"`
		if [ "$has_ar_branch" == "1" ]; then
			export AR_SOURCE_BRANCH="$AR_SOURCE_BRANCH_CANDIDATE"
		else
			has_ar_branch=`git_branch_exists "$AR_COMPS/arduino" "$AR_PR_TARGET_BRANCH"`
			if [ "$has_ar_branch" == "1" ]; then
				export AR_SOURCE_BRANCH="$AR_PR_TARGET_BRANCH"
			fi
		fi
	fi
fi

if [ "$AR_SOURCE_BRANCH" ]; then
	echo "AR_SOURCE_BRANCH='$AR_SOURCE_BRANCH'"
	git -C "$AR_COMPS/arduino" fetch --all && \
	git -C "$AR_COMPS/arduino" checkout -B "$AR_SOURCE_BRANCH" origin/"$AR_SOURCE_BRANCH" && \
	git -C "$AR_COMPS/arduino" pull --ff-only
fi
if [ $? -ne 0 ]; then exit 1; fi
