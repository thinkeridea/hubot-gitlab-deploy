#!/bin/bash
set -eo pipefail

sudo chown -R hubot.hubot /home/hubot/.ssh
chmod -R 600 /home/hubot/.ssh

exec "$@"
