FROM openshift/origin

# Jenkins image for OpenShift
#
# This image provides a Jenkins server, primarily intended for integration with
# OpenShift v3.
#
# Volumes:
# * /var/jenkins_home
# Environment:
# * $JENKINS_PASSWORD - Password for the Jenkins 'admin' user.

MAINTAINER Donovan Mulder <donovan@spatialedge.co.za>

ARG VERSION
ARG CONFIG_FILE_PATH
# Jenkins LTS packages from
# https://pkg.jenkins.io/redhat-stable/
ENV JENKINS_VERSION=2 \
    VERSION=${VERSION} \
    HOME=/var/lib/jenkins \
    JENKINS_HOME=/var/lib/jenkins \
    JENKINS_UC=https://updates.jenkins.io \
    OPENSHIFT_JENKINS_IMAGE_VERSION=4.0 \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

LABEL k8s.io.description="Jenkins is a continuous integration server" \
      k8s.io.display-name="Jenkins 2" \
      openshift.io.expose-services="8080:http" \
      openshift.io.tags="jenkins,jenkins2,ci" \
      io.openshift.s2i.scripts-url=image:///usr/libexec/s2i

USER root
# 8080 for main web interface, 50000 for slave agents
EXPOSE 8080 50000

RUN curl https://pkg.jenkins.io/redhat-stable/jenkins.repo -o /etc/yum.repos.d/jenkins.repo && \
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins-ci.org.key && \
    yum install -y centos-release-scl-rh && \
    curl https://copr.fedorainfracloud.org/coprs/alsadi/dumb-init/repo/epel-7/alsadi-dumb-init-epel-7.repo -o /etc/yum.repos.d/alsadi-dumb-init-epel-7.repo &&\
    x86_EXTRA_RPMS=$(if [ "$(uname -m)" == "x86_64" ]; then echo -n java-1.8.0-openjdk.i686 java-1.8.0-openjdk-devel.i686 ; fi) && \
    yum -y --setopt=tsflags=nodocs install $x86_EXTRA_RPMS && \
    INSTALL_PKGS="dejavu-sans-fonts rsync gettext git tar zip unzip openssl bzip2 dumb-init java-1.8.0-openjdk jenkins-${VERSION}" && \
    yum -y --setopt=tsflags=nodocs install $INSTALL_PKGS && \
    # have temporarily removed the validation for java to work around known problem fixed in fedora; jupierce and gmontero are working with
    # the requisit folks to get that addressed ... will switch back to rpm -V $INSTALL_PKGS when that occurs
    rpm -V  dejavu-sans-fonts rsync gettext git tar zip unzip openssl bzip2 dumb-init jenkins-${VERSION} && \
    yum clean all  && \
    rm -rf /var/cache/yum && \
    localedef -f UTF-8 -i en_US en_US.UTF-8

#COPY contrib/repos/openshift /opt/openshift
#COPY contrib/repos/jenkins /usr/local/bin
#ADD contrib/repos/s2i /usr/libexec/s2i
#ADD contrib/repos/release.version /tmp/release.version

COPY usr/local/bin/pem/*.pem /etc/pki/ca-trust/source/anchors/

# Install certs
RUN update-ca-trust force-enable \
    && update-ca-trust

RUN chmod 777 /usr/local/bin/install-plugins.sh
RUN chmod 777 /usr/local/bin/fix-permissions
RUN chmod 777 /usr/libexec/s2i/run

RUN /usr/local/bin/install-plugins.sh /opt/openshift/base-plugins.txt && \
    # need to create <plugin>.pinned files when upgrading "core" plugins like credentials or subversion that are bundled with the jenkins server
    # Currently jenkins v2 does not embed any plugins, but for reference:
    # touch /opt/openshift/plugins/credentials.jpi.pinned && \
    rmdir /var/log/jenkins && \
    chmod 664 /etc/passwd && \
    chmod -R 775 /etc/alternatives && \
    chmod -R 775 /var/lib/alternatives && \
    chmod -R 775 /usr/lib/jvm && \
    chmod 775 /usr/bin && \
    chmod 775 /usr/lib/jvm-exports && \
    chmod 775 /usr/share/man/man1 && \
    chmod 775 /var/lib/origin && \
    unlink /usr/bin/java && \
    unlink /usr/bin/jjs && \
    unlink /usr/bin/keytool && \
    unlink /usr/bin/orbd && \
    unlink /usr/bin/pack200 && \
    unlink /usr/bin/policytool && \
    unlink /usr/bin/rmid && \
    unlink /usr/bin/rmiregistry && \
    unlink /usr/bin/servertool && \
    unlink /usr/bin/tnameserv && \
    unlink /usr/bin/unpack200 && \
    unlink /usr/lib/jvm-exports/jre && \
    unlink /usr/share/man/man1/java.1.gz && \
    unlink /usr/share/man/man1/jjs.1.gz && \
    unlink /usr/share/man/man1/keytool.1.gz && \
    unlink /usr/share/man/man1/orbd.1.gz && \
    unlink /usr/share/man/man1/pack200.1.gz && \
    unlink /usr/share/man/man1/policytool.1.gz && \
    unlink /usr/share/man/man1/rmid.1.gz && \
    unlink /usr/share/man/man1/rmiregistry.1.gz && \
    unlink /usr/share/man/man1/servertool.1.gz && \
    unlink /usr/share/man/man1/tnameserv.1.gz && \
    unlink /usr/share/man/man1/unpack200.1.gz && \
    chown -R 1001:0 /opt/openshift && \
    /usr/local/bin/fix-permissions /opt/openshift && \
    /usr/local/bin/fix-permissions /var/lib/jenkins && \
    /usr/local/bin/fix-permissions /var/log

VOLUME ["/var/lib/jenkins"]

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/usr/libexec/s2i/run"]
