#!/bin/bash -e

cd gerrit

if git show --diff-filter=AM --name-only --pretty="" HEAD | grep -q .bazelversion
then
  export BAZEL_OPTS=""
fi

case {branch} in
  master|stable-3.9)
    . set-java.sh 17
    ;;

  *)
    . set-java.sh 11
    ;;
esac

echo "Build with mode=$MODE"
echo '----------------------------------------------'

java -fullversion
bazelisk version

if [[ "$MODE" == *"rbe"* ]]
then
  if [[ "$TARGET_BRANCH" == "master" ]]
  then
    echo "Skipping RBE build because of lack of support for GLIBC_2.28"
  else
    bazelisk build --config=remote --remote_instance_name=projects/gerritcodereview-ci/instances/default_instance plugins:core release api-skip-javadoc
  fi
elif [[ "$MODE" == *"polygerrit"* ]]
then
  echo "Skipping building eclipse and maven"
else
  bazelisk build $BAZEL_OPTS plugins:core release api
  tools/maven/api.sh install
  tools/eclipse/project.py --bazel bazelisk
fi
