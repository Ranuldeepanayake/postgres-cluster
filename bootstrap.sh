#!/bin/bash
set -e

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
until curl -sf http://localhost:2379/health; do
  echo "Waiting for etcd..."
  sleep 2
done

echo "Starting Patroni..."
su postgres -c "patroni /etc/patroni.yml"