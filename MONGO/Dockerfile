FROM centos:7

ARG mongoversion=server-4.4.0-1.el7.x86_64
ARG mongourl=https://repo.mongodb.org/yum/redhat/7/mongodb-org/4.4/x86_64/RPMS/mongodb-org-${mongoversion}.rpm
ARG mongoshellurl=https://repo.mongodb.org/yum/redhat/7/mongodb-org/4.4/x86_64/RPMS/mongodb-org-shell-4.4.0-1.el7.x86_64.rpm
ARG mongosurl=https://repo.mongodb.org/yum/redhat/7/mongodb-org/4.4/x86_64/RPMS/mongodb-org-mongos-4.4.0-1.el7.x86_64.rpm

RUN yum -y install openssl \
 && rpm -ivh ${mongourl}   \
 && rpm -ivh ${mongoshellurl} \
 && rpm -ivh ${mongosurl} \
 && yum clean all

VOLUME /media/data/mongodb
VOLUME /media/data/mongodb/logs

EXPOSE 27017
COPY mongod.conf /etc/mongo/
COPY pem.key /etc/mongo/
COPY run.sh /

CMD ["bash", "-x", "/run.sh"]