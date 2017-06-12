Sprintf = require("sprintf").sprintf

class WhereAppFormatter
  constructor: (@deployment) ->
  message: ->
    output  = "applications for #{@deployment.name}\n"
    output += "-----------------------------------------------------------------\n"
    output += Sprintf "%-15s | %-35s\n", "Environment",  @deployment.environments.join(", ")
    output += "-----------------------------------------------------------------\n"

    if @deployment.allowedRooms? && @deployment.allowedRooms.length > 0
      output += Sprintf "%-15s | %-35s\n", "Rooms",  @deployment.allowedRooms.join(", ")
      output += "-----------------------------------------------------------------\n"

    if @deployment.allowedUsers? && @deployment.allowedUsers.length > 0
      output += Sprintf "%-15s | %-35s\n", "Users",  @deployment.allowedUsers.join(", ")
      output += "-----------------------------------------------------------------\n"
    output

class WhereAppsFormatter
  constructor: (@applications) ->
  message: ->
    output  = "applications\n"
    output += "-----------------------------------------------------------------\n"
    output += Sprintf "%-15s | %-35s | %-35s| %-35s\n", "name",  "Environment", "Rooms", "Users"
    output += "-----------------------------------------------------------------\n"
    for name, application of @applications
      environments = if application["environments"]? then application["environments"].join(", ") else ""
      allowed_rooms = if application["allowed_rooms"]? then application["allowed_rooms"].join(", ") else "all room"
      allowed_users =  if application["allowed_users"]? then application["allowed_users"].join(", ") else "all user"
      output += Sprintf "%-15s | %-35s | %-35s| %-35s\n", name, environments, allowed_rooms, allowed_users
      output += "-----------------------------------------------------------------\n"

    output

exports.WhereAppFormatter  = WhereAppFormatter
exports.WhereAppsFormatter  = WhereAppsFormatter
