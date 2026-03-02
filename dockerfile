FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

#Install required OS packages.
RUN apt-get update && apt-get install -y curl gnupg lsb-release python3 python3-pip wget python3-psycopg2 python3-yaml python3-click wget vim

#Add the PostgreSQL repo.
RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt noble-pgdg main" > /etc/apt/sources.list.d/pgdg.list

#Install postgres.
RUN apt-get update && apt-get install -y postgresql-18 postgresql-client-18

# Install etcd manually
ENV ETCD_VER=v3.6.8
RUN curl -L https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz \
    | tar xz && \
    mv etcd-${ETCD_VER}-linux-amd64/etcd* /usr/local/bin/ && \
    rm -rf etcd-${ETCD_VER}-linux-amd64
    
#Install Patroni.
RUN pip3 install --break-system-packages patroni[etcd]

#Set directory pemissions.
RUN mkdir -p /home/postgres/pgdata /var/lib/etcd 
RUN chown -R postgres:postgres /home/postgres /var/lib/etcd
RUN chmod -R 700 /home/postgres/pgdata

#Copy the startup script.
COPY bootstrap.sh /bootstrap.sh
RUN chmod +x /bootstrap.sh && chown postgres:postgres /bootstrap.sh
USER postgres
EXPOSE 5432 8008 2379 2380

ENTRYPOINT ["/bin/bash", "/bootstrap.sh"]