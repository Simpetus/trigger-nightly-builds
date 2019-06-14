#!/bin/bash

set -e
set -x

PROJECT="$1"

git config --global user.email "travis@travis-ci.org"
git config --global user.name "Travis CI"

# The name of the file that holds the most recent NanoComp/${PROJECT}.git commit hash
COMMIT_FILENAME=latest_${PROJECT}_commit.txt
LAST_KNOWN_COMMIT=$(head -n 1 ${COMMIT_FILENAME})
LATEST_COMMIT=$(git ls-remote git://github.com/NanoComp/${PROJECT}.git refs/heads/master | cut -f 1)

if [ "${LAST_KNOWN_COMMIT}" != "${LATEST_COMMIT}" ]; then
    # Bumb the recipe buildnumber, which will trigger a rebuild on travis,
    # which will publish a new conda package
    if [ "${PROJECT}" = "meep" ]; then
        REPO_NAME="pymeep-nightly-recipe"
    else
        REPO_NAME="${PROJECT}-nightly-recipe"
    fi
    git clone https://github.com/Simpetus/${REPO_NAME}.git
    pushd ${REPO_NAME}
    git checkout master
    sed -r -i 's/(.*set buildnumber = )([0-9]+)(.*)/echo "\1$((\2+1))\3"/ge' recipe/meta.yaml
    git add recipe/meta.yaml
    git commit -m "Travis: Update build number"
    set +x
    git remote set-url origin https://${GH_TOKEN}@github.com/Simpetus/${REPO_NAME}.git > /dev/null 2>&1
    git push origin master
    popd

    echo "Updated build number"

    set -x
    # Update commit file
    git checkout master
    rm ${COMMIT_FILENAME}
    echo "${LATEST_COMMIT}" > ${COMMIT_FILENAME}
    git add ${COMMIT_FILENAME}
    git commit -m "Travis: Update latest commit"
    set +x
    git remote set-url origin https://${GH_TOKEN}@github.com/Simpetus/trigger-nightly-builds.git > /dev/null 2>&1
    git push origin master

    echo "Updated latest ${PROJECT} commit"
else
    echo "No updates"
fi
