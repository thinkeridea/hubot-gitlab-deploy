Q = require "q"
childProcess = require('child_process')
###########################################################################

module.exports = (deployment, workingDirectory) ->
  fabfilePath = deployment.application['fabfile'] || process.env['FABFILE_PATH']
  fabfileParam = ""
  if fabfilePath?
    fabfileParam = " -f #{fabfilePath} "
  deferred = Q.defer()
  if deployment.hosts? && deployment.hosts isnt ""
    deployCommand = "fab #{fabfileParam} -H #{deployment.hosts} #{deployment.task}:branch_name=#{deployment.ref} --set=environment=#{deployment.env}"
  else
    deployCommand = "fab #{fabfileParam} -R #{deployment.env} #{deployment.task}:branch_name=#{deployment.ref} --set=environment=#{deployment.env}"

  console.log("Executing fabric: #{deployCommand}")

  childProcess.exec(deployCommand,{cwd:workingDirectory}, (error, stdout, stderr) ->
    if error? && error isnt ""
      deferred.reject({error, stdout, stderr})
    else
      deferred.resolve({error, stdout, stderr})
  )

  return deferred.promise
