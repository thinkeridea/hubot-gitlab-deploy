Q = require ("q")
request = require ("request")
urlEncode = require ("urlencode")

Version      = require("../version").Version
###########################################################################
class CommitStatus
  constructor: (@api) ->

  get: ->
    deferred = Q.defer()
    request({
      url: @api.path("/projects/#{urlEncode(@api.application['repository'])}/repository/commits/#{urlEncode(@api.deployment.ref)}"),
      method: 'GET',
      headers: {
        'PRIVATE-TOKEN': @api.token,
        'User-Agent':'hubot-gitlab-deploy-v#{Version}'
      }
    },(error, response, body) =>
      if (error)
        deferred.reject("check project status failed:#{error}")

      if (typeof response !="undefined" && response? && response.statusCode == 200)
        info = JSON.parse(body)
        if (info && info.status == "success")
          deferred.resolve(info.id)
        else
          deferred.reject("""
          Unmet required commit status contexts for #{@api.deployment.name}: #{info.status}.
          """)
      else if (typeof response !="undefined" && response? && response.statusCode == 401)
        deferred.reject("Unable to create deployment for #{@api.application['repository']}. Check your scopes for this token.")
      else
        info = JSON.parse(body)
        deferred.reject("check project status failed:#{info.message}")
    )

    return deferred.promise

module.exports = CommitStatus
