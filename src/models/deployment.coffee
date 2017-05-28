applications = require "./applications"
###########################################################################

class Deployment
  constructor: (@name, @ref, @task, @env, @force, @hosts) ->
    @environments     = [ "production" ]
    @application = applications[@name]

    if @application?
      @repository = @application['repository']
      @provider = @application['provider']
      @configureEnvironments()

      @allowedRooms = @application['allowed_rooms']
      @allowedUsers = @application['allowed_users']

  configureEnvironments: ->
    if @application['environments']?
      @environments = @application['environments']

    @env = 'staging' if @env == 'stg'
    @env = 'production' if @env == 'prod'

  isValidApp: ->
    @application?

  isValidEnv: ->
    @env in @environments

  isAllowedRoom: (room) ->
    !@allowedRooms? || room in @allowedRooms

  isAllowedUser: (user) ->
    !@allowedUsers? || user in @allowedUsers

module.exports = Deployment
