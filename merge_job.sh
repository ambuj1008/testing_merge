#!/bin/bash

while [[ $# -gt 1 ]]; do
    key="$1"
    case $key in
    -d | --tag)
        RELEASE_TAG="$2"
        shift
        ;;
    *) ;;
    esac
    shift
done

if [[ -z $RELEASE_TAG ]]; then
    echo "RELEASE_TAG not provided"
	exit 1
fi

DMIAMSERVICE="iam-service";
DMONBOARDING="onboarding-service";

#Building Submodule List
SUB_MODULES=$(git config --file .gitmodules --get-regexp path | awk '{ print $2 }')

git submodule sync && git submodule update --init --recursive

for SUB_MODULE in $SUB_MODULES; do	
	if [ "$SUB_MODULE" != "$DMIAMSERVICE" ] && [ "$SUB_MODULE" != "$DMONBOARDING" ]; then
	cd $SUB_MODULE;
	echo "inside $SUB_MODULE"
	#Checkout
	git stash || exit 1
	git checkout origin/master || exit 1
	git fetch origin || exit 1
	git rebase tags/${RELEASE_TAG} || exit 1

	#Merge
	git fetch --tags origin || exit 1
	git merge --ff-only ${RELEASE_TAG} || exit 1
	echo "Git log after merge:"
	git log -n 5 || exit 1

	#Pull
	git pull origin master || exit 1

	#Commit
	COMMIT_MSG=$(git show dev --pretty=%B | cut -d '"' -f2)
	if [ $COMMIT_MSG != '' ]; then
	echo "Committing merge to origin/master"
	git commit --amend -m "$COMMIT_MSG" || exit 1
	else
	echo "No commit message found";
	exit 1
	fi
	#Push
	git push origin HEAD:master || exit 1
	cd ..
	fi
done