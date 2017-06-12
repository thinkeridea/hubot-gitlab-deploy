# Description
#   gitlab deploy
#
# Configuration:
#   GITLAB_URL
#   GITLAB_TOKEN
#   GITLAB_SNIPPETS_NAME
#
# Commands:
#   hubot show deploy apps <app> - see what environments you can deploy app
#   hubot deploy:version - show the script version and node/environment info
#   hubot deploy <app>/<branch> to <env>/<roles> - deploys <app>'s <branch> to the <env> environment's <roles> servers
#   hubot deploys <app>/<branch> in <env> - Displays recent deployments for <app>'s <branch> in the <env> environment
#
fs = require ("fs")
Q = require ("q")
childProcess = require('child_process')

GitLabApi = require "../gitlab/api"
Deployment = require "../models/deployment"
Applications = require "../models/applications"
Patterns = require "../models/patterns"
Git = require "../models/git"
Provider = require "../models/provider"
DeployLog = require "../models/deploy_log"
Formatters = require("../models/formatters")

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
            robot.adapter.customMessage({
              channel: msg.message.user.roomID,
              alias: "",
              avatar: "",
              attachments: [{
                text:content,
                color:if status then "#6498CC" else "#c00",
              }]
            })
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
      Q().then(()->
        deferred = Q.defer()
        api.projectStatus().then((info) ->
          if info.status == "success" || info.status is null || force
            commitID = info.id
            deferred.resolve()
          else
            msg.reply "Unmet required commit status contexts for #{name}: continuous-integration/gitlab-ci/push #{info.status}."
            robot.brain.remove(deployLockKey)
        ).catch((error) ->
          msg.reply error
          robot.brain.remove(deployLockKey)
        )
        return deferred.promise
      ).then(()->
        deferred = Q.defer()
        # get project info
        api.projectInfo().then((info) ->
          projectInfo = info
          deferred.resolve()
        ).catch((error) ->
          msg.reply error
          robot.brain.remove(deployLockKey)
          throw error
        )
        return deferred.promise
      ).then(() ->
        deferred = Q.defer()
        deployLog.lastDeploySha(deployment.repository).then((sha) ->
          deferred.resolve(sha)
        ).catch((error) ->
          robot.logger.error("get last deploy sha failure. #{error}")
          deferred.resolve("0000000")
        )
        return deferred.promise
      ).then((lastSha) ->
        deferred = Q.defer()
        message = "deploying [#{projectInfo.path_with_namespace}:#{ref}](#{projectInfo.web_url}/tree/#{ref}) to #{env}" + (if hosts? && hosts isnt "" then "/#{hosts}" else "")
        msg.reply "#{message} ([compare](#{projectInfo.web_url}/compare/#{lastSha}...#{commitID}))"
        deferred.resolve()
        return deferred.promise
      ).then(() ->
        deferred = Q.defer()

        try
          childProcess.execSync("mkdir -p /tmp/#{projectInfo.path_with_namespace}/")
          workingDirectory = fs.mkdtempSync("/tmp/#{projectInfo.path_with_namespace}/")
          new Git().clone(workingDirectory, projectInfo.ssh_url_to_repo, commitID, task).then((result) ->
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
          stderr += "clone project #{projectInfo.path_with_namespace} failure.\n"
          if "message" of error
            stderr += "#{error.message}\n"

          if "stack" of error
            stderr += "#{error.stack}\n"
          robot.logger.error ("clone project #{projectInfo.path_with_namespace} failure. #{error["message"]}\n#{error["stack"]}")
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

  ###########################################################################
  # show deploy apps <app>
  #
  # Displays the available environments for an application
  robot.respond ///show\s+#{DeployPrefix}\s+apps(?:(\s+[-_\.0-9a-z]+)?)///i, id: "hubot-gitlab-deploy.wcid", (msg) ->
    name = msg.match[1]

    try
      if name?
        deployment = new Deployment(name)
        formatter  = new Formatters.WhereAppFormatter(deployment)
      else
        formatter  = new Formatters.WhereAppsFormatter(Applications)

      msg.reply formatter.message()
    catch err
      robot.logger.info "Exploded looking for deployment locations: #{err}"
