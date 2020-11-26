FROM mongo:4.4

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y unzip && \
    apt-get install -y rsync && \
    apt-get clean

WORKDIR /media/data/mongodb/backups

COPY run.sh /

CMD ["sh", "-x", "/run.sh"]