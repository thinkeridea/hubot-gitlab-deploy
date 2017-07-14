#!/bin/bash
set -eo pipefail

gosu root chown -R hubot.hubot /home/hubot/.ssh
gosu root chmod -R 600 /home/hubot/.ssh

node -e "console.log(JSON.stringify('$EXTERNAL_SCRIPTS'.split(',')))" > external-scripts.json
npm install $(node -e "console.log('$EXTERNAL_SCRIPTS'.split(',').join(' '))")

exec "$@"
