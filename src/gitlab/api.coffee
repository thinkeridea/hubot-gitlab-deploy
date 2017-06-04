commitStatus = require ("./commit_status")
projectInfo = require ("./project_info")
urlJoin = require ("url-join")

###########################################################################
class GitLabApi
  constructor: (@application, @deployment) ->
    @token = @apiToken()

    @url = @apiUrl()

  apiUrl: ->
    (@application? and @application['gitlab_api']) or
      process.env.GITLAB_URL or throw new Error("Without the correct configuration gitlab API URl")

  apiToken: ->
    (@application? and @application['gitlab_token']) or
      process.env.GITLAB_TOKEN

  path : ->
    urlJoin(@url, arguments...)

  projectStatus: ->
    new commitStatus(@).get()

  projectInfo: ->
    new projectInfo(@).get()

module.exports = GitLabApi
