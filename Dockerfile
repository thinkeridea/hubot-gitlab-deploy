FROM node:7.10.0

MAINTAINER thinkeride <thinkeridea@sina.com>

ENV HUBOT_NAME "gitlab-deploy-bot"
ENV HUBOT_ADAPTER rocketchat
ENV HUBOT_DESCRIPTION "Hubot with rocketbot adapter and gitlab deploy script"
ENV HUBOT_OWNER "No owner specified"

ENV EXTERNAL_SCRIPTS=hubot-gitlab-deploy,hubot-diagnostics,hubot-help,hubot-google-images,hubot-google-translate,hubot-pugme,hubot-maps,hubot-rules,hubot-shipit

# rocketbot need constant configuration
# ENV ROCKETCHAT_URL
# ENV LISTEN_ON_ALL_PUBLIC
# ENV ROCKETCHAT_USER
# ENV ROCKETCHAT_PASSWORD
# ENV ROCKETCHAT_AUTH
# ENV EXTERNAL_SCRIPTS

# hubot-gitlab-deploy need constant configuration
# ENV GITLAB_URL
# ENV GITLAB_TOKEN
# ENV GITLAB_SNIPPETS_NAME
# ENV MONGO_URL
# ENV GITLAB_DEPLOY_KEY
# ENV SERVICE_DEPLOY_KEY

ENV GOSU_VERSION 1.10

USER root

RUN set -x \
    && groupadd -r gosu \
    && useradd -r -g gosu gosu \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chown root:gosu /usr/local/bin/gosu \
    && chmod +x /usr/local/bin/gosu \
    && chmod +s /usr/local/bin/gosu \
    && gosu nobody true

RUN set -xe \
    && npm install -g coffee-script yo generator-hubot \
	  && useradd hubot -m \
	  && usermod -a -G gosu hubot \
	  && mkdir /home/hubot/app \
	  && chown hubot.hubot /home/hubot/app

USER hubot

WORKDIR /home/hubot/app

RUN set -xe \
    && yo hubot --owner="$HUBOT_OWNER" \
                --name="$HUBOT_NAME" \
                --description="$HUBOT_DESCRIPTION" \
                --adapter="$HUBOT_ADAPTER" \
                --defaults \
    && sed -i /heroku/d ./external-scripts.json \
    && sed -i /redis-brain/d ./external-scripts.json \
    && npm install hubot-scripts

USER root

COPY ./ /home/hubot/app/node_modules/hubot-gitlab-deploy
COPY docker-entrypoint.sh /usr/local/bin/

RUN set -xe \
    && chown -R hubot.hubot /home/hubot/app \
    && apt update \
    && apt-get install -y fabric --force-yes \
    && apt-get clean \
    && chmod +x /usr/local/bin/docker-entrypoint.sh \
    && apt-get install \
       apt-transport-https \
       ca-certificates \
       curl \
       software-properties-common \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && apt-key fingerprint 0EBFCD88 \
    && add-apt-repository \
          "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) \
          stable" \
    && apt-get update \
    && apt-get install docker-ce

USER hubot

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD bin/hubot -n $HUBOT_NAME -a $HUBOT_ADAPTER
