Sprintf = require("sprintf").sprintf

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

    "show applications\n```\n#{output}\n```"

exports.WhereAppFormatter  = WhereAppFormatter
exports.WhereAppsFormatter  = WhereAppsFormatter
