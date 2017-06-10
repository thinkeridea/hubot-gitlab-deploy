# Description
#   gitlab deploy
#
# Configuration:
#   GITLAB_URL
#   GITLAB_TOKEN
#   GITLAB_SNIPPETS_NAME
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
Provider = require "../models/provider"
DeployLog = require "../models/deploy_log"

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
    commitID = ref
    stdout = ""
    stderr = ""
    deployLockKey = "gitlab_deploy_lock_#{name}"
    command = "deploy#{msg.match[2]||""} #{name}:#{ref} to #{env}" + (if hosts? && hosts isnt "" then "/#{hosts}" else "")
    projectInfo = {}

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

      deployStatus = robot.brain.get deployLockKey
      if deployStatus? && deployStatus!=""
        msg.reply "#{name} #{deployStatus.user} Already deploying."
        return

      robot.brain.set(deployLockKey, {user:msg.message.user.name})

      api = new GitLabApi(deployment.application, deployment)
      deployLog = new DeployLog(name, deployment.application.repository, msg.message.user.room, msg.message.user.name, ref, env, command)

      sendMsg = (content, status) ->
        switch robot.adapterName
          when "rocketchat"
            robot.adapter.getRoomId(msg.message.user.room).then((rid)->
              robot.adapter.customMessage({
                channel: rid,
                alias: "",
                avatar: "",
                attachments: [{
                  text:content,
                  color:if status then "#6498CC" else "#c00",
                }]
              })
            ).catch(()->
              msg.reply content
            )
          else
            msg.reply content

      completeDeploy = (status) ->
        robot.brain.remove(deployLockKey)
        try
          message = "#{msg.message.user.name}'s #{name} deployment of [#{projectInfo.path_with_namespace}:#{ref}](#{projectInfo.web_url}/tree/#{ref}) is #{if status then "done!" else "failed."}"
          api.writeDeployLog(command, stdout, stderr).then((info)->
            deployLog.record(commitID, info.id, info.web_url, stdout, stderr, status).catch((error)->
              robot.logger.error("mongodb record deploy log failure. #{error}")
            )
            sendMsg("[##{info.id}](#{info.web_url}): #{message}", status)
          ).catch((error)->
            deployLog.record(commitID, -1, "", stdout, stderr, status).catch((error)->
              robot.logger.error("mongodb record deploy log failure. #{error}")
            )
            sendMsg("#{message}", status)
            robot.logger.error("writeDeployLog: #{error}")
          )
        catch error
          sendMsg("#{message}", status)
          robot.logger.error("writeDeployLog: #{error["message"]}\n#{error["stack"]}")

      # check project status
      api.projectStatus().catch((error) ->
        msg.reply error
        robot.brain.remove(deployLockKey)
      ).then((sha)->
        # get project info
        commitID = sha
        api.projectInfo().catch((error) ->
          msg.reply error
          robot.brain.remove(deployLockKey)
        )
      ).then((info) ->
        deferred = Q.defer()
        projectInfo = info
        try
          childProcess.execSync("mkdir -p /tmp/#{info.path_with_namespace}/")
          workingDirectory = fs.mkdtempSync("/tmp/#{info.path_with_namespace}/")

          msg.reply "deploying [#{info.path_with_namespace}:#{ref}](#{info.web_url}) to #{env}" + (if hosts? && hosts isnt "" then "/#{hosts}" else "")

          new Git().clone(workingDirectory, info.ssh_url_to_repo, commitID, task).then((result) ->
            stdout += result.stdout
            stderr += result.stderr
            deferred.resolve()
          ).catch((result) ->
            if "cmd" of result.error
              stderr += "command: #{result.error.cmd}\n"
            stdout += result.stdout
            stderr += result.stderr
            deferred.reject()
          )
        catch error
          stderr += "clone project #{info.path_with_namespace} failure.\n"
          if "message" of error
            stderr += "#{error.message}\n"

          if "stack" of error
            stderr += "#{error.stack}\n"
          robot.logger.error ("clone project #{info.path_with_namespace} failure. #{error["message"]}\n#{error["stack"]}")
          deferred.reject()

        return deferred.promise
      ).then(() ->
        deferred = Q.defer()
        try
          Provider(deployment, workingDirectory).then((result) ->
            stdout += result.stdout
            stderr += result.stderr
            deferred.resolve()
          ).catch((result) ->
            if "cmd" of result.error
              stderr += "command: #{result.error.cmd}\n"
            stdout += result.stdout
            stderr += result.stderr
            deferred.reject()
          )
        catch error
          stderr += "Executing deploy script failure."
          if "message" of error
            stderr += "#{error.message}\n"

          if "stack" of error
            stderr += "#{error.stack}\n"
          robot.logger.error ("Executing deploy script failure. #{error["message"]}\n#{error["stack"]}")
          deferred.reject()

        return deferred.promise
      ).then(()->
        completeDeploy(true)
      ).catch(()->
        completeDeploy(false)
      )
    catch error
      robot.brain.remove(deployLockKey)
      robot.logger.info "Create a deployment abnormal: #{error["message"]}\n#{error["stack"]}"

  robot.hear /orly/, (res) ->
    res.send "yarly"
