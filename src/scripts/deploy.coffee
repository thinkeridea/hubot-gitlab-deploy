# Description
#   gitlab deploy
#
# Configuration:
#   GITLAB_URL
#   GITLAB_TOKEN
#   GITLAB_SNIPPETS_NAMME
#
# Commands:
#   hubot where can I deploy <app> - see what environments you can deploy app
#   hubot deploy:version - show the script version and node/environment info
#   hubot deploy <app>/<branch> to <env>/<roles> - deploys <app>'s <branch> to the <env> environment's <roles> servers
#   hubot deploys <app>/<branch> in <env> - Displays recent deployments for <app>'s <branch> in the <env> environment
#


Deployment    = require "../models/deployment"
Patterns    = require "../models/patterns"

DeployPrefix   = Patterns.DeployPrefix
DeployPattern  = Patterns.DeployPattern
DeploysPattern = Patterns.DeploysPattern

module.exports = (robot) ->
  ###########################################################################
  # deploy hubot/topic-branch to staging
  #
  # deploys <app>'s <branch> to the <env> environment's <roles> servers
  robot.respond DeployPattern, id: "hubot-gitlab-deploy.create", hubotDeployAuthenticate: true, (msg) ->
    defaultDeployEnvironment = process.env.HUBOT_DEPLOY_DEFAULT_ENVIRONMENT || 'production'
    task  = msg.match[1].replace("#{DeployPrefix}:", "")
    force = msg.match[2] == '!'
    name  = msg.match[3]
    ref   = (msg.match[4]||'master')
    env   = (msg.match[5]||defaultDeployEnvironment)
    hosts = (msg.match[6]||'')

    console.log(msg)
    deployment = new Deployment(name, ref, task, env, force, hosts)
    console.log(JSON.stringify(deployment))

    unless deployment.isValidApp()
      msg.reply "#{name}? Never heard of it."
      return

    unless deployment.isValidEnv()
      msg.reply "#{name} doesn't seem to have an #{env} environment."
      return
    unless deployment.isAllowedRoom msg.message.user.room
      msg.reply "#{name} is not allowed to be deployed from this room."
      return

    unless deployment.isAllowedUser msg.message.user.name
      msg.reply "#{name} you are not allowed to deployment."
      return



  robot.hear /orly/, (res) ->
    res.send "yarly"
