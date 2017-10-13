#!/bin/bash

[ -v SSHTUNNEL_REMOTE_PORT1 ] || SSHTUNNEL_REMOTE_PORT1=22
[ -v SSHTUNNEL_REMOTE_PORT2 ] || SSHTUNNEL_REMOTE_PORT2=22

function log {
  echo "ssh-tunnel	event=$1"
}

function is_configured1 {
  [[ \
    -v SSHTUNNEL_PRIVATE_KEY1 && \
    -v SSHTUNNEL_TUNNEL_CONFIG1 && \
    -v SSHTUNNEL_REMOTE_USER1 && \
    -v SSHTUNNEL_REMOTE_HOST1
  ]] && return 0 || return 1
}

function is_configured2 {
  [[ \
    -v SSHTUNNEL_PRIVATE_KEY2 && \
    -v SSHTUNNEL_TUNNEL_CONFIG2 && \
    -v SSHTUNNEL_REMOTE_USER2 && \
    -v SSHTUNNEL_REMOTE_HOST2
  ]] && return 0 || return 1
}

function deploy_key1 {
  mkdir -p ${HOME}/.ssh
  chmod 700 ${HOME}/.ssh

  echo "${SSHTUNNEL_PRIVATE_KEY1}" > ${HOME}/.ssh/ssh-tunnel-key1
  chmod 600 ${HOME}/.ssh/ssh-tunnel-key1

  ssh-keyscan -p ${SSHTUNNEL_REMOTE_PORT1} ${SSHTUNNEL_REMOTE_HOST1} >> ${HOME}/.ssh/known_hosts
  ssh-add ${HOME}/.ssh/ssh-tunnel-key1
  log "Added key 1"
}

function deploy_key2 {
  mkdir -p ${HOME}/.ssh
  chmod 700 ${HOME}/.ssh

  echo "${SSHTUNNEL_PRIVATE_KEY2}" > ${HOME}/.ssh/ssh-tunnel-key2
  chmod 600 ${HOME}/.ssh/ssh-tunnel-key2

  ssh-keyscan -p ${SSHTUNNEL_REMOTE_PORT2} ${SSHTUNNEL_REMOTE_HOST2} >> ${HOME}/.ssh/known_hosts
  ssh-add ${HOME}/.ssh/ssh-tunnel-key2
  log "Added key 2"
}

function spawn_tunnel1 {
  while true; do
    log "ssh-connection-init 1"
    ssh -i ${HOME}/.ssh/ssh-tunnel-key1 -N -o "ServerAliveInterval 10" -o "ServerAliveCountMax 3" -L ${SSHTUNNEL_TUNNEL_CONFIG1} ${SSHTUNNEL_REMOTE_USER1}@${SSHTUNNEL_REMOTE_HOST1} -p ${SSHTUNNEL_REMOTE_PORT1}
    log "ssh-connection-end 1"
    sleep 5;
  done &
}

function spawn_tunnel2 {
  while true; do
    log "ssh-connection-init 2"
    ssh -i ${HOME}/.ssh/ssh-tunnel-key2 -N -o "ServerAliveInterval 10" -o "ServerAliveCountMax 3" -L ${SSHTUNNEL_TUNNEL_CONFIG2} ${SSHTUNNEL_REMOTE_USER2}@${SSHTUNNEL_REMOTE_HOST2} -p ${SSHTUNNEL_REMOTE_PORT2}
    log "ssh-connection-end 2"
    sleep 5;
  done &
}

log "starting"
echo " " > ${HOME}/.ssh/known_hosts

log "Starting SSH agent"
eval $(ssh-agent)

if is_configured1; then
  deploy_key1
  spawn_tunnel1

  log "spawned 1";
else
  log "missing-configuration 1"
fi

if is_configured2; then
  deploy_key2
  spawn_tunnel2

  log "spawned 2";
else
  log "missing-configuration 2"
fi
