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
Q = require ("q")
fs = require ("fs")
childProcess = require('child_process')

GitLabApi    = require("../gitlab/api")
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

    try
      deployment = new Deployment(name, ref, task, env, force, hosts)

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

      api = new GitLabApi(deployment.application, deployment)

      # check project status
      api.projectStatus().catch((error) =>
        msg.reply error
        throw error
      ).then(()=>
        # get project info
        api.projectInfo().catch((error) =>
          msg.reply error
          throw error
        )
      )
    catch err
      robot.logger.info "Create a deployment abnormal: #{err}"

  robot.hear /orly/, (res) ->
    res.send "yarly"
