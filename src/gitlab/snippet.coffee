Q = require ("q")
request = require ("request")
urlEncode = require ("urlencode")

Version      = require("../version").Version
###########################################################################
class Snippet
  constructor: (@api) ->

  create: (title, stdout, stderr) ->
    deferred = Q.defer()
    request({
      url: @api.path("/projects/#{urlEncode(@api.snippetsName())}/snippets"),
      method:'POST',
      headers: {
        'PRIVATE-TOKEN': @api.token,
        'User-Agent':'hubot-gitlab-deploy-v#{Version}'
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      form: {
        title: title,
        file_name: "",
        code : @formatContent(stdout, stderr),
        visibility:"internal"
      }
    },(error, response, body) =>
      if (error)
        deferred.reject("create snippet failed:#{error}")
      if (typeof response !="undefined" && response? && response.statusCode >=200 && response.statusCode<300)
        info = JSON.parse(body)
        deferred.resolve({id:info.id, web_url:info.web_url})
      else if (typeof response !="undefined" && response? && response.statusCode == 401)
        deferred.reject("Unable to create snippet for #{@api.snippetsName()}. Check your scopes for this token.")
      else
        info = JSON.parse(body)
        deferred.reject("create snippet failed:#{info["error"]}")
    )

    return deferred.promise

  formatContent: (stdout, stderr) ->
    content = "-----------------------------------------------------------------\n"
    content += "| stderr:                                                       |\n"
    content += "-----------------------------------------------------------------\n"
    content += "#{stderr}\n\n\n"
    content += "-----------------------------------------------------------------\n"
    content += "| stdout:                                                       |\n"
    content += "-----------------------------------------------------------------\n"
    content += "#{stdout}\n"

    return content

module.exports = Snippet
