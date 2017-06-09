Q = require ("q")
childProcess = require('child_process')
###########################################################################
class Git
  clone: (workingDirectory, repoUrl, sha, task) ->
    deferred = Q.defer()
    gitResetCmd = if task isnt "rollback" then "&& git reset --hard #{sha}" else ""
    childProcess.exec("""
        git clone #{repoUrl} . && \
        git checkout -- . && \
        git clean -fd && \
        git fetch #{gitResetCmd}
    """
    ,{cwd:workingDirectory}, (error, stdout, stderr) ->
        if error? && error isnt ""
          deferred.reject({error, stdout, stderr})
        else
          deferred.resolve({error, stdout, stderr})
    )

    return deferred.promise

module.exports = Git
