#!/bin/sh

set -ex
git config --global user.name "${USER_NAME}"
git config --global user.email "${USER_EMAIL}"

echo "Retrieve docker commit"
getme Extract "${BUILD_URL}/bundles-ce-binary.tar.gz" "bundles/*/binary-client/docker" /tmp/docker

DOCKER_COMMIT=$(/tmp/docker version -f '{{ .Client.GitCommit }}' || true)
DOCKER_VERSION=$(/tmp/docker version -f '{{ .Client.Version }}' || true)
echo "Docker commit: ${DOCKER_COMMIT}"

BRANCH="docker-ce-${DOCKER_VERSION}-${DOCKER_COMMIT}"

echo "Get sources"
export GOPATH="/go"

mkdir -p "$GOPATH/src/github.com/docker"
cd "$GOPATH/src/github.com/docker"
git clone -b ${BASE} git@github.com:${GITHUB_REPO}.git

cd pinata
git checkout -b "${BRANCH}"

jq ".docker.artifacts=\"${BUILD_URL}\"" "$BUILD_JSON" |
  jq ".docker.version=\"${DOCKER_VERSION}\"" > "$BUILD_JSON".tmp
mv "$BUILD_JSON.tmp" "$BUILD_JSON"

if [ -d editions.moby ]; then
    jq 'with_entries(select(.key == ("docker")))' "$BUILD_JSON" > editions.moby/version.json
fi
git diff
git commit -asm "Update docker-ce to ${DOCKER_VERSION} (${DOCKER_COMMIT})"

echo "Update the proxy vendoring"
ls -al common/scripts
cd common/scripts/ 
sh -x ./update-docker-ce-vendor 
cd ../..
cp Gopkg.lock editions.moby/Gopkg.lock
git commit -asm "Propagate vendoring changes to subtree"

echo "Push changes"
git push origin "${BRANCH}"

echo "Open a PR"
MESSAGE="Update docker-ce to ${DOCKER_VERSION} (${DOCKER_COMMIT})"
hub pull-request -m "${MESSAGE}" -b "${BASE}" -r gtardif
