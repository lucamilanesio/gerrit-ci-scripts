#!/bin/bash -e

git checkout -fb {branch} gerrit/{branch}
git submodule update --init
rm -rf plugins/{name}
git read-tree -u --prefix=plugins/{name} origin/{branch}
git fetch --tags origin

if [ -f plugins/{name}/external_plugin_deps.bzl ]
then
  cp -f plugins/{name}/external_plugin_deps.bzl plugins/
fi

TARGETS=$(echo "{targets}" | sed -e 's/{{name}}/{name}/g')
TEST_TARGET=$(grep -2 junit_tests plugins/{name}/BUILD | grep -o 'name = "[^"]*"' | cut -d '"' -f 2)

. set-java.sh 8

java -fullversion
bazelisk version
bazelisk build --spawn_strategy=standalone --genrule_strategy=standalone $TARGETS

if [ "$TEST_TARGET" != "" ]
then
    bazelisk test --test_env DOCKER_HOST=$DOCKER_HOST plugins/{name}:$TEST_TARGET
fi

for JAR in $(find bazel-bin/plugins/{name} -name {name}*.jar)
do
    PLUGIN_VERSION=$(git describe  --always origin/{branch})
    echo -e "Implementation-Version: $PLUGIN_VERSION" > MANIFEST.MF
    jar ufm $JAR MANIFEST.MF && rm MANIFEST.MF
    DEST_JAR=bazel-bin/plugins/{name}/$(basename $JAR)
    [ "$JAR" -ef "$DEST_JAR" ] || mv $JAR $DEST_JAR
    echo "$PLUGIN_VERSION" > bazel-bin/plugins/{name}/$(basename $JAR-version)
done
