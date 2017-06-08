###########################################################################
providers={

}
###########################################################################

module.exports = (deployment) ->
  if not deployment.application.provider of providers
    throw "#{deployment.application.provider} is not a valid provider"
  providers[deployment.application.provider](deployment)
