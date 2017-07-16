# hubot-gitlab-deploy

gitlab deploy

See [`src/gitlab-deploy.coffee`](src/gitlab-deploy.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-gitlab-deploy --save`

Then add **hubot-gitlab-deploy** to your `external-scripts.json`:

```json
[
  "hubot-gitlab-deploy"
]
```

## Sample Interaction

```
user1>> hubot hello
hubot>> hello!
```

## NPM Module

https://www.npmjs.com/package/hubot-gitlab-deploy
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gosu root apt-key add - \
    &&  gosu root apt-key fingerprint 0EBFCD88 \
    &&  gosu root add-apt-repository \
          "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) \
          stable" \
    &&  gosu root apt-get update \
    &&  gosu root apt-get install -y docker-ce
