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
fs = require ("fs")
Q = require ("q")
childProcess = require('child_process')

GitLabApi = require "../gitlab/api"
Deployment = require "../models/deployment"
Patterns = require "../models/patterns"
Git = require "../models/git"

DeployPrefix = Patterns.DeployPrefix
DeployPattern = Patterns.DeployPattern
DeploysPattern = Patterns.DeploysPattern

module.exports = (robot) ->
###########################################################################
# deploy hubot/topic-branch to staging
#
# deploys <app>'s <branch> to the <env> environment's <roles> servers
  robot.respond DeployPattern, id: "hubot-gitlab-deploy.create", hubotDeployAuthenticate: true, (msg) ->
    defaultDeployEnvironment = process.env.HUBOT_DEPLOY_DEFAULT_ENVIRONMENT || 'production'
    task = msg.match[1].replace("#{DeployPrefix}:", "")
    force = msg.match[2] == '!'
    name = msg.match[3]
    ref = (msg.match[4] || 'master')
    env = (msg.match[5] || defaultDeployEnvironment)
    hosts = (msg.match[6] || '')

    workingDirectory = ""

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
      api.projectStatus().catch((error) ->
        msg.reply error
        throw error
      ).then(()->
        # get project info
        api.projectInfo().catch((error) ->
          msg.reply error
          throw error
        )
      ).then((info) ->
        deferred = Q.defer()
        try
          childProcess.execSync("mkdir -p /tmp/#{info.path_with_namespace}/")
          workingDirectory = fs.mkdtempSync("/tmp/#{info.path_with_namespace}/")

          msg.reply "deploying [#{info.path_with_namespace}](#{info.web_url}) to #{env}" + (if hosts? && hosts isnt "" then "/#{hosts}" else "")

          new Git().clone(workingDirectory, info.ssh_url_to_repo, ref, task).then((result) ->
            msg.reply JSON.stringify(result)
            deferred.resolve()
          ).catch((result) ->
            msg.reply "err"+JSON.stringify(result)
            throw error
          )
        catch error
          msg.reply "clone project [#{info.path_with_namespace}](#{info.web_url}) failure."
          robot.logger.error ("clone project #{info.path_with_namespace} failure. #{error}")
          throw error
        return deferred.promise
      ).then(() ->
        msg.reply workingDirectory
      )
    catch err
      robot.logger.info "Create a deployment abnormal: #{err}"

  robot.hear /orly/, (res) ->
    res.send "yarly"
