FROM jenkins/jenkins:${JENKINS_WAR_VER}

USER root

RUN echo "$JENKINS_WAR_SHA  /usr/share/jenkins/jenkins.war" | sha1sum -c -

# Override Jenkins start-up script
RUN mv /usr/local/bin/jenkins.sh /usr/local/bin/run-jenkins.sh
COPY jenkins.sh /usr/local/bin/

RUN apt-get update && apt-get install -y \
    ca-certificates \
    python-dev \
    python-pip \
    python-yaml \
    python-jenkinsapi \
    default-jdk \
    autoconf \
    automake \
    xsltproc \
    apt-transport-https && \
    rm -rf /var/lib/apt/lists/* && \
    pip install pbr==2.0.0 && \
    mkdir -p /etc/jenkins_jobs && chown jenkins: /etc/jenkins_jobs

RUN sed -i 's#mozilla/DST_Root_CA_X3.crt#!mozilla/DST_Root_CA_X3.crt#' /etc/ca-certificates.conf && \
    update-ca-certificates

# Install JJB from source until the support for checks-filters is released
RUN git clone https://review.opendev.org/jjb/jenkins-job-builder && \
    cd jenkins-job-builder && \
    git checkout 979770380151f99ec7b48d7d6fbd8d8d254c752c && \
    pip install .

COPY jenkins_jobs.ini /etc/jenkins_jobs/jenkins_jobs.ini

ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false -Dhudson.model.ParametersAction.keepUndefinedParameters=true
ENV JENKINS_REF /usr/share/jenkins/ref/
ENV USE_SECURITY false
ENV OAUTH_ID clientid
ENV OAUTH_SECRET secret
ENV JENKINS_API_USER user
ENV JENKINS_API_PASSWORD pass
ENV DOCKER_HOST unix:///var/run/docker.sock
ENV BINTRAY_URL https://dl.bintray.com/lucamilanesio

COPY edit-config.xslt $JENKINS_REF
COPY config.xml $JENKINS_REF
COPY jenkins.plugins.logstash.LogstashInstallation.xml $JENKINS_REF
COPY jenkins.model.JenkinsLocationConfiguration.xml $JENKINS_REF

RUN mkdir -p $JENKINS_REF/.ssh && \
    chown -R jenkins:jenkins $JENKINS_REF/.ssh && \
    chmod -R 700 $JENKINS_REF/.ssh

COPY plugins.txt $JENKINS_REF
RUN cat $JENKINS_REF/plugins.txt | xargs install-plugins.sh
RUN chown -R jenkins:jenkins $JENKINS_REF

RUN mkdir -p $JENKINS_REF/jobs/gerrit-ci-scripts/ && \
    mkdir -p $JENKINS_REF/jobs/gerrit-ci-scripts-manual/

COPY number-executors.groovy $JENKINS_REF/init.groovy.d/
COPY setCredentials.groovy $JENKINS_REF/init.groovy.d/
COPY gerrit-ci-scripts.xml $JENKINS_REF/jobs/gerrit-ci-scripts/config.xml
COPY gerrit-ci-scripts-manual.xml $JENKINS_REF/jobs/gerrit-ci-scripts-manual/config.xml
COPY org.jenkinsci.plugins.workflow.libs.GlobalLibraries.xml $JENKINS_REF/

RUN echo "2.0" > $JENKINS_REF/jenkins.install.UpgradeWizard.state && \
    echo "2.0" > $JENKINS_REF/upgraded && \
    echo "2.0" > $JENKINS_REF/.last_exec_version

COPY gitconfig $JENKINS_REF/.gitconfig

RUN apt-get install -y \
     apt-transport-https \
     ca-certificates \
     curl \
     dirmngr gnupg gpgv && \
     curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
     echo "deb [arch=amd64] https://download.docker.com/linux/debian buster stable" >> etc/apt/sources.list && \
     apt-get update && \
     apt-cache policy docker-engine && \
     apt-get install -y docker-ce=18.03.1~ce-0~debian

COPY id_rsa* $JENKINS_REF/.ssh/
RUN chown jenkins:jenkins $JENKINS_REF/.ssh/id_rsa* && \
    chmod 600 $JENKINS_REF/.ssh/id_rsa

COPY config.sh /usr/local/bin/

# Install gosu
ENV GOSU_VERSION 1.9
RUN set -x \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

# Set default JDK to 8
RUN apt-get install -y openjdk-8-jdk && \
    update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java

ENV DOCKER_GID=993

USER root
