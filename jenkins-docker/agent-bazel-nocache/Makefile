include ../chrome-vers.mk

NO_CACHE=false
PREFIX=gerritforge
IMAGE=${PREFIX}/gerrit-ci-agent-bazel:debian-buster-nocache
BAZEL_VER=4.0.0
BUILDIFIER_VER=4.0.0
BAZELISK_VER=1.7.4
NODE_VER=10
WCT_VER=6.8.0

# Targets

build:
	@for chrome_ver in $(CHROME_VERS); \
	do \
		cat Dockerfile | \
		BAZEL_VER=${BAZEL_VER} \
		BUILDIFIER_VER=${BUILDIFIER_VER} \
		BAZELISK_VER=${BAZELISK_VER} \
		NODE_VER=${NODE_VER} \
		WCT_VER=${WCT_VER} \
		CHROME_VER=$$chrome_ver envsubst > Dockerfile-subst; \
		docker build --no-cache=$(NO_CACHE) \
		-f Dockerfile-subst \
		-t ${IMAGE}-$$chrome_ver . ; \
	done

publish:
	@for chrome_ver in $(CHROME_VERS); \
	do \
		docker push ${IMAGE}-$$chrome_ver; \
	done

clean:
	@for chrome_ver in $(CHROME_VERS); \
        do \
		docker rmi -f ${IMAGE}-$$chrome_ver; \
	done

.PHONY: clean image publish

