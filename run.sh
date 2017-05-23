#!/bin/sh

set -e

echo "Read ${DESCRIPTOR_URL}"
DESCRIPTOR=$(getme Copy "${DESCRIPTOR_URL}" -)
MOBY_SHA1=$(echo "${DESCRIPTOR}" | jq -r '.moby."git-commit"')
BINARY_URL=$(echo "${DESCRIPTOR}" | jq -r '.moby.docker."binary-artifact-url"')
BRANCH="moby-${MOBY_SHA1}"
DESCRIPTION="Update Moby to ${MOBY_SHA1}"

echo "Get sources"
git clone -n --depth=1 https://${GITHUB_TOKEN}@github.com/${GITHUB_REPO}.git sources

echo "Retrieve docker commit"
echo ${BINARY_URL}
getme Extract "${BINARY_URL}" **/binary-client/docker /tmp/docker
set +e
DOCKER_COMMIT=$(/tmp/docker version -f '{{ .Client.GitCommit }}')
set -e
echo "${DOCKER_COMMIT}"

echo "Switch to different branch"
cd sources
git checkout -b "${BRANCH}"

echo "Patch ${BUILD_JSON}"
cp "${BUILD_JSON}" "${BUILD_JSON}.bak"
jq ".moby.descriptor=\"${DESCRIPTOR_URL}\"" "${BUILD_JSON}.bak" > "${BUILD_JSON}"
rm "${BUILD_JSON}.bak"

echo "Commit changes"
git config --global user.name "${USER_NAME}"
git config --global user.email "${USER_EMAIL}"
git commit -asm "${DESCRIPTION}"

echo "Update the proxy vendoring"
cd ./v1/docker_proxy
./update-vendor.sh "${DOCKER_COMMIT}"
git commit -asm "Update proxy vendoring to ${DOCKER_COMMIT}" || true
cd -

echo "Push changes"
git push -f origin "${BRANCH}"

echo "Open a PR"
hub pull-request -m "${DESCRIPTION}" -b "${BASE}"
