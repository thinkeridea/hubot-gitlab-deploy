Sprintf = require("sprintf").sprintf
Timeago = require("timeago")
TimeStamp = require("time-stamp")

splitLine = "-".repeat(100)+"\n"
class WhereAppFormatter
  constructor: (@deployment) ->
  message: ->
    allowed_rooms = if @deployment.allowedRooms? then @deployment.allowedRooms.join(", ") else "all room"
    allowed_users =  if @deployment.allowedUsers? then @deployment.allowedUsers.join(", ") else "all user"

    output = Sprintf "%-15s | %-35s\n", "Environment",  @deployment.environments.join(", ")
    output += splitLine

    output += Sprintf "%-15s | %-35s\n", "Rooms", allowed_rooms
    output += splitLine

    output += Sprintf "%-15s | %-35s\n", "Users", allowed_users
    output += splitLine

    "show applications for #{@deployment.name}\n```#{output}```"

class WhereAppsFormatter
  constructor: (@applications) ->
  message: ->
    output = Sprintf "%-10s | %-25s | %-25s| %-25s\n", "name", "Rooms", "Users",  "Environment"
    output += splitLine
    for name, application of @applications
      environments = if application["environments"]? then application["environments"].join(", ") else ""
      allowed_rooms = if application["allowed_rooms"]? then application["allowed_rooms"].join(", ") else "all room"
      allowed_users =  if application["allowed_users"]? then application["allowed_users"].join(", ") else "all user"
      output += Sprintf "%-10s | %-25s | %-25s| %-25s\n", name, allowed_rooms, allowed_users, environments
      output += splitLine

    "show applications\n```#{output}```"

class LatestFormatter
  constructor: (@res) ->
  message: ->
    output = Sprintf "%-5s | %-10s | %-35s | %-10s| %-25s\n", "ID", "Who", "What", "Status", "When"
    output += splitLine
    for log in @res
      output += Sprintf("%-5s | %-10s | %-35s | %-10s| %-25s\n",
        log.id,
        log.executor,
        "#{log.ref}(#{log.sha.substr(0, 7)}) to #{log.env}",
        "#{if log.status then "succeed" else "failure"}",
        "#{Timeago(log.create_date)} / #{TimeStamp("YYYY-MM-DD HH:mm:ss", log.create_date)}")
      output += splitLine

    "```#{output}```"

exports.WhereAppFormatter  = WhereAppFormatter
exports.WhereAppsFormatter  = WhereAppsFormatter
exports.LatestFormatter  = LatestFormatter
