#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

echo "Updating packages..."
apt-get update

echo "Installing dependencies..."
apt-get install -y \
    curl \
    gnupg \
    lsb-release \
    python3 \
    python3-pip \
    python3-psycopg2 \
    python3-yaml \
    python3-click \
    wget

echo "Adding PostgreSQL repo..."
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg

echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt noble-pgdg main" \
> /etc/apt/sources.list.d/pgdg.list

apt-get update

echo "Installing PostgreSQL 18..."
apt-get install -y postgresql-18 postgresql-client-18 etcd

echo "Installing Patroni..."
pip3 install patroni[etcd]

#Start etcd cluster member
ETCD_NAME=$(hostname)

etcd \
  --name ${ETCD_NAME} \
  --data-dir /var/lib/etcd \
  --initial-advertise-peer-urls http://${ETCD_NAME}:2380 \
  --listen-peer-urls http://0.0.0.0:2380 \
  --listen-client-urls http://0.0.0.0:2379 \
  --advertise-client-urls http://${ETCD_NAME}:2379 \
  --initial-cluster patroni-1=http://patroni-1:2380,patroni-2=http://patroni-2:2380,patroni-3=http://patroni-3:2380 \
  --initial-cluster-state new &

#Wait for etcd to become available
sleep 30

echo "Preparing data directory..."
mkdir -p /home/postgres/pgdata
chown -R postgres:postgres /home/postgres

echo "Starting Patroni..."
su postgres -c "patroni /etc/patroni.yml"