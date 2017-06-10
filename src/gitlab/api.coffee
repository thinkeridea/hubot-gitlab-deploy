commitStatus = require ("./commit_status")
projectInfo = require ("./project_info")
snippet = require ("./snippet")
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

  snippetsName: ->
    (@application? and @application['gitlab_snippets_name']) or
      process.env.GITLAB_SNIPPETS_NAME or throw new Error("Without the correct configuration gitlab snippets name")

  path : ->
    urlJoin(@url, arguments...)

  projectStatus: ->
    new commitStatus(@).get()

  projectInfo: ->
    new projectInfo(@).get()

  writeDeployLog: (title, stdout, stderr) ->
    new snippet(@).create(title, stdout, stderr)

module.exports = GitLabApi
