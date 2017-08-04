#!/bin/bash
set -eo pipefail

sudo chown -R hubot.hubot /home/hubot/.ssh
sudo chmod 600 /home/hubot/.ssh/*
sudo chmod 700 /home/hubot/.ssh

# 实现 docker in docker 部署
if [ $DOCKER_GROUP_ID ]; then
    sudo groupmod -g ${DOCKER_GROUP_ID} docker
fi

exec "$@"
