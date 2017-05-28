fs = require "fs"
path = require "path"
extend = require "node.extend"
###########################################################################

appsFile = process.env['HUBOT_DEPLOY_APPS_JSON'] or "apps.json"
appsDir = process.env['HUBOT_DEPLOY_APPS_DIR_PATH'] or path.resolve("./apps")

applications = {}
try
  if fs.existsSync(appsFile) && fs.statSync(appsFile).isFile()
    applications = JSON.parse(fs.readFileSync(appsFile).toString())

  if fs.existsSync(appsDir) && fs.statSync(appsDir).isDirectory()
    for appsJSONFile in fs.readdirSync(appsDir).sort()
      if fs.statSync(path.join(appsDir, appsJSONFile)).isFile()
        tmp = JSON.parse fs.readFileSync(path.join(appsDir, appsJSONFile)).toString()
        applications = extend applications,tmp
catch err
  throw new Error("Unable to parse your apps.json file in hubot-gitlab-deploy #{err}")

module.exports = applications
