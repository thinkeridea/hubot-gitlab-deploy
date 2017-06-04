Q = require ("q")
request = require ("request")
urlEncode = require ("urlencode")

Version      = require("../version").Version
###########################################################################
class ProjectInfo
  constructor: (@api) ->

  get: ->
    deferred = Q.defer()
    request({
      url: @api.path("/projects/#{urlEncode(@api.application['repository'])}"),
      method:'GET',
      headers: {
        'PRIVATE-TOKEN': @api.token,
        'User-Agent':'hubot-gitlab-deploy-v#{Version}'
      }
    },(error, response, body) =>
      if (error)
        deferred.reject("get project info failed:#{error}")

      if (typeof response !="undefined" && response? && response.statusCode == 200)
        info = JSON.parse(body)
        deferred.resolve(info)
      else if (typeof response !="undefined" && response? && response.statusCode == 401)
        deferred.reject("Unable to create deployment for #{@api.application['repository']}. Check your scopes for this token.")
      else
        info = JSON.parse(body)
        deferred.reject("get project info failed:#{info.error}")
    )

    return deferred.promise

module.exports = ProjectInfo
