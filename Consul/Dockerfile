FROM centos:7

ARG version=1.8.0
ARG rooturl=https://releases.hashicorp.com/consul
ENV binary=${rooturl}/${version}/consul_${version}_linux_amd64.zip
ENV consulbin=consul.zip
ENV workbin=consul

WORKDIR /

RUN yum install -y unzip && \
curl -so ${consulbin} ${binary} && \