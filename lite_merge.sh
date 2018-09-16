#!/bin/bash

echo "Enter new aosp tag - r?"
read tag_aosp
echo "Enter LiteOS branch"
read lite_branch

aosp_tag=android-$lite_branch.0_r$tag_aosp
AOSP="https://android.googlesource.com"
LITE_PATH=$PWD

git config --global credential.helper cache

for merge_repos in $(grep 'remote="lite"' ./manifest/aosp/merge.xml  | awk '{print $2}' | awk -F '"' '{print $2}'); do
    cd $merge_repos
    git checkout $lite_branch
    if [ "$merge_repos" == "build/make" ]; then
        merge_repos="build"
    fi
    git remote add aosp "${AOSP}/platform/$merge_repos"
    git fetch aosp
    git merge $aosp_tag --no-edit
    if [ $? -ne 0 ]; then
        echo "$merge_repos" >> ${LITE_PATH}/failed
        echo "$merge_repos failed :("
    else
        if [[ "$(git rev-parse HEAD)" != "$(git rev-parse lite/${lite_branch})" ]]; then
            echo "$merge_repos" >> ${LITE_PATH}/success
            git commit --signoff --date="$(date)" --amend --no-edit
            echo "$merge_repos succeeded"
            echo "Pushing!"
            git push -u lite $lite_branch
            git remote remove aosp
        else
            git remote remove aosp
            echo "$merge_repos - unchanged"
        fi
    fi
    cd ${LITE_PATH}
done
