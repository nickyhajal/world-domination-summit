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

module.exports = routes
