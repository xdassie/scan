FROM openshift/jenkins-slave-base-centos7
MAINTAINER Darren Albertyn <darren@kineticskunk.com>

ARG HELM_VERSION="v2.12.2"
ARG KUBE_VERSION="v1.10.6"


USER root
######Update and Clean#############
RUN yum -y update && yum clean all
RUN yum install -y centos-release-scl-rh

######Installing Kubectl###########
RUN curl -L https://dl.k8s.io/${KUBE_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl

#######Installing Helm and Tiller##############
RUN wget https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz
RUN tar -zxvf helm-${HELM_VERSION}-linux-amd64.tar.gz
RUN cp linux-amd64/helm /usr/local/bin/helm

ADD /contrib/repos/pem /etc/pki/ca-trust/source/anchors/

RUN update-ca-trust force-enable \
  && update-ca-trust

USER 1001
RUN helm init --client-only

