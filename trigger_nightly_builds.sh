#!/bin/bash

set -e

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
    REPO_NAME="${PROJECT}-nightly-recipe"
    git clone https://github.com/Simpetus/${REPO_NAME}.git
    pushd ${REPO_NAME}
    git checkout master
    sed -r -i 's/(.*set buildnumber = )([0-9]+)(.*)/echo "\1$((\2+1))\3"/ge' recipe/meta.yaml
    git add recipe/meta.yaml
    git commit -m "Travis: Update build number"
    git remote set-url origin https://${GH_TOKEN}@github.com/Simpetus/${REPO_NAME}.git > /dev/null 2>&1
    git push origin master
    popd

    echo "Updated build number"

    # Update commit file
    rm ${COMMIT_PATH}
    echo "${LATEST_COMMIT}" > ${COMMIT_PATH}
    git add ${COMMIT_PATH}
    git commit -m "Travus: Update latest commit"
    git remote set-url origin https://${GH_TOKEN}@github.com/Simpetus/trigger-nightly-builds.git > /dev/null 2>&1
    git push origin master

    echo "Updated latest ${PROJECT} commit"
else
    echo "No updates"
fi
