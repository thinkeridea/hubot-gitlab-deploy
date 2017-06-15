Q = require('q')
mongoose = require('mongoose')

db = mongoose.connect(process.env.MONGO_URL)
deployLogSchema = new db.Schema({
  appName: {type: String, index: true},
  projectName: {type: String, index: true},
  executor: String,
  room: String,
  ref: String,
  sha: String,
  env: String,
  command: String,
  id: {type: Number, index: true},
  url: String,
  status: {type: Boolean, index: true},
  stdout: String,
  stderr: String,
  create_date: {type: Date, default: Date.now}
})

deployLogModel = mongoose.model('DeployLog', deployLogSchema);
###########################################################################

class DeployLog
  constructor: (@appName, @projectName, @room, @executor, @ref, @env, @command) ->

  record: (sha, id, url, stdout, stderr, status) ->
    deferred = Q.defer()
    entity = new deployLogModel({
      appName: @appName,
      projectName: @projectName,
      executor: @executor,
      room: @room,
      ref: @ref,
      sha: sha,
      env: @env,
      command: @command,
      id: id,
      url: url,
      status: status,
      stdout: stdout,
      stderr: stderr,
    })

    entity.save((err, res) ->
      if err? && err != ""
        deferred.reject(err)
      else
        deferred.resolve(res)
    )

    return deferred.promise

  lastDeploySha: (@projectName) ->
    deferred = Q.defer()
    deployLogModel.findOne({status: true}).sort("-create_date").exec((err, res)->
      if err? && err != ""
        deferred.reject(err)
      else
        deferred.resolve(if res? && "sha" of res then res.sha else "0000000")
    )
    return deferred.promise

  latelyDeployLog: (deployment, limit=10) ->
    deferred = Q.defer()
    query = deployLogModel.find()
    if deployment.name?
      query = query.where({appName: deployment.name})

    if deployment.env?
      query = query.where({env: deployment.env})

    if deployment.ref?
      query = query.or([{ref:deployment.ref}, {sha:///^#{deployment.ref}///i }])

    query.select({appName:1, executor:1, ref:1, sha:1, env:1, id:1, url:1, status:1, create_date:1}).sort("-create_date").limit(parseInt(limit)).exec((err, res)->
      if err? && err != ""
        deferred.reject(err)
      else
        deferred.resolve(res)
    )
    return deferred.promise

module.exports = DeployLog
