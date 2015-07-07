redis = require("redis")
rds = redis.createClient()

routes = (app) ->

  [Notification, Notifications] = require('../../models/notifications')
  [Device, Devices] = require('../../models/devices')
  [Registration, Registrations] = require('../../models/registrations')

  get_count: (req, res, next) ->
    next()

  send: (req, res, next) ->
    next()

module.exports = routes
