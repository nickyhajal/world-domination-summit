redis = require("redis")
rds = redis.createClient()
knex = require('knex')

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
    key = 'recent_checkins'
    if req.query.by_id?
      key += '_byid'
    rds.get key, (err, checkins) ->
      if checkins? and checkins and typeof JSON.parse(checkins) is 'object'
        res.r.checkins = JSON.parse(checkins)
        next()
      else
        time_spread = 100 # A check-in expires after X minutes
        from = (new Date(new Date().getTime() - (time_spread * 60 * 1000)))
        Checkins.forge()
        .query (qb) ->
          qb.where('created_at', '>', from)
          qb.groupBy(knex.raw('location_type, location_id'))
          qb.orderBy('num_checkins', 'DESC')
          qb.orderBy('check_in', 'DESC')
          qb.column(knex.raw('COUNT(*) as num_checkins'))
        .fetch({columns: ['location_id', 'location_type']})
        .then (checkins) ->
          checkins = checkins.models
          if req.query.by_id?
            tmp = {}
            for i in checkins
              if i.get('location_id') == '15'
                existing = tmp['2'].get('num_checkins')
                tmp['2'].set('num_checkins', (+i.get('num_checkins'))+(+existing))
              else
                tmp[i.get("location_id")] = i
            checkins = tmp
          res.r.checkins = checkins
          next()
          rds.set key, JSON.stringify(checkins), ->
            rds.expire key, 4
        , (err) ->
          console.error err
          next()

module.exports = routes
