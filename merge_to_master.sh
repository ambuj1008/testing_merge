#!/bin/bash

set -E

while [[ $# -gt 1 ]]; do
    key="$1"
    case $key in
    -d | --tag)
        RELEASE_TAG="$2"
        shift
        ;;
#    -r | --repo)
#        REPO_URL="$2"
#        shift
#        ;;
#    -p | --port)
#        PORT="$2"
#        shift
#        ;;
    *) ;;
    esac
    shift
done

if [[ -z $RELEASE_TAG ]]; then
    echo "RELEASE_TAG not provided"
    exit 1
fi

#if [[ -z $REPO_URL ]]; then
#    echo "REPO_URL not provided"
#    exit 1
#fi

#if [[ -z $PORT ]]; then
#    echo "PORT not provided"
#    exit 1
#fi

#Building Submodule List
SUB_MODULES=$(git config --file .gitmodules --get-regexp path | awk '{ print $2 }')

#function config_submodule_url() {
#    git config submodule.$1.url $REPO_URL:$PORT/$1
#}

#for SUB_MODULE in $SUB_MODULES; do
#    config_submodule_url $SUB_MODULE
#done

git submodule sync || exit 1
git submodule update --init --recursive || exit 1

function gitCommandToMergeCode() {
    #Checkout
    git stash || exit 1
    git checkout origin/master || exit 1
    git fetch --all || exit 1
    git rebase --onto tags/${RELEASE_TAG} origin/master || exit 1

    #Merge
    git merge --ff-only ${RELEASE_TAG} || exit 1
    echo "Git log after merge:" || exit 1
    git log -n 5 || exit 1

    #Commit
    COMMIT_MSG=$(git show ${RELEASE_TAG} --pretty=%B | cut -d '"' -f2)
    if [[ $COMMIT_MSG != '' ]]; then
        echo "Committing merge to origin/master"
        git commit --amend -m "$COMMIT_MSG" || exit 1
    else
        echo "No commit message found"
        exit 1
    fi

    #Push
    git push origin HEAD:master || exit 1
}

gitCommandToMergeCode

DMIAMSERVICE="iam-service"
DMONBOARDING="onboarding-service"

for SUB_MODULE in $SUB_MODULES; do
    if [ "$SUB_MODULE" != "$DMIAMSERVICE" ] && [ "$SUB_MODULE" != "$DMONBOARDING" ]; then
        cd $SUB_MODULE
        echo "Merging $SUB_MODULE submodule"
        gitCommandToMergeCode
        cd ..
    fi
done