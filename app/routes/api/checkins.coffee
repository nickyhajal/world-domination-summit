redis = require("redis")
rds = redis.createClient()

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

    rds.get 'recent_checkins', (err, checkins) ->
      if checkins? and checkins and typeof JSON.parse(checkins) is 'object'
        res.r.checkins = JSON.parse(checkins)
        next()
      else
        time_spread = 160 # A check-in expires after X minutes
        from = (new Date(new Date().getTime() - (time_spread * 60 * 1000)))
        Checkins.forge()
        .query (qb) ->
          qb.where('created_at', '>', from)
          qb.groupBy(qb.knex.raw('location_type, location_id'))
          qb.orderBy('num_checkins', 'DESC')
          qb.orderBy('check_in', 'DESC')
          qb.column(qb.knex.raw('COUNT(*) as num_checkins'))
        .fetch()
        .then (checkins) ->
          res.r.checkins = checkins.models
          next()
          rds.set 'recent_checkins', JSON.stringify(checkins.models), ->
            rds.expire 'recent_checkins', 4
        , (err) ->
          tk err
          next()

module.exports = routes
