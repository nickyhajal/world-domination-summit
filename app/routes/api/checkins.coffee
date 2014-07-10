routes = (app) ->

  [Checkin, Checkins] = require('../../models/checkins')

  get: (req, res, next) ->
    Checkins.forge()
    .fetch()
    .then (checkins) ->
      res.r.checkins = checkins.models
      next()
    , (err) ->
      console.error err
      next()

  get_recent: (req, res, next) ->
    time_spread = 45 # A check-in expires after X minutes
    from = (new Date(new Date().getTime() - (time_spread * 60 * 1000)))
    Checkins.forge()
    .query("where", "created_at", ">", from)
    .fetch()
    .then (checkins) ->
      res.r.checkins = checkins.models
      next()
    , (err) ->
      tk err
      next()

module.exports = routes
