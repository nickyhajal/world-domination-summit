redis = require("redis")
rds = redis.createClient()
crypto = require('crypto')
apn = require('apn')
gcm = require('node-gcm')
_ = require('underscore')

routes = (app) ->

  [Notification, Notifications] = require('../../models/notifications')
  [Device, Devices] = require('../../models/devices')
  [Registration, Registrations] = require('../../models/registrations')
  [Feed, Feeds] = require('../../models/feeds')
  ntfn_routes =
    get_count: (req, res, next) ->
      if req.query.device? and req.query.registered?
        ntfn_routes.get_devices req, res, (devices) ->
          next()
      else
        res.r.msg = "Missing parameters"
        next()

    send: (req, res, next) ->
      if req.query.device? and req.query.registered?
        ntfn_routes.get_devices req, res, (devices) ->
          if +res.r.device_count > 0
            if req.query.dispatch_text?
              post =
                content: req.query.dispatch_text
                user_id: '8082'
              if req.query.event_id? and req.query.event_id != 'all'
                post.channel_type = 'meetup'
                post.channel_id = req.query.event_id
              if req.query.test? and req.query.test == 'yes'
                post.restrict = 'staff'
              if req.query.type?
                type = req.query.type
                if type is '360'
                  post.restrict = '360'
                if type is 'staff'
                  post.restrict = 'staff'
                if type is 'ambassador'
                  post.restrict = 'ambassador'
                if type is 'staff,ambassador'
                  post.restrict = 'ambnstaff'
              uniq = moment().format('YYYY-MM-DD HH:mm') + post.content + post.user_id
              post.hash = crypto.createHash('md5').update(uniq).digest('hex')
              Feed.forge
                hash: post.hash
              .fetch()
              .then (existing) ->
                if not existing
                  feed = Feed.forge post
                  feed
                  .save()
                  .then (feed_rsp) ->
                    feed_id = feed_rsp.get('feed_id')
                    if feed_id? and feed_id > 0
                      for device in devices
                        tokens = [device.get('token')]
                        type = device.get('type')
                        user_id = device.get('user_id')
                        link = '/dispatch/'+feed_id
                        tk device.get('token')
                        if type is 'ios' # and user_id == 176
                          note = new apn.Notification()
                          note.alert = req.query.notification_text
                          note.payload = {content: '{"user_id":"8082"}', type: 'feed_comment', link: link}
                          tk 'ios'
                          # tk note
                          process.APN.pushNotification(note, tokens)
                        else if type is 'and' # and user_id == 176
                          tokens = [device.get('token')]
                          message = new gcm.Message
                            collapseKey: "WDS Notifications"
                            data:
                              title: "WDS App"
                              message: req.query.notification_text
                              id: post.hash
                              user_id: '8082'
                              content: '{"user_id":"8082"}'
                              type: 'feed_comment'
                              link: link
                          tk JSON.stringify(message)
                          process.gcmSender.send message, tokens, (err, result) ->
                            tk err
                            tk result
                      res.r.sent = true
                      next()
                  , (err) ->
                    console.error err
                else
                  res.r.msg = 'You already posted that!'
                  res.status(409)
                  next()
              , (err) ->
                console.error err
      else
        res.r.msg = "Missing parameters"
        next()


    get_devices: (req, res, cb) ->
      test = req.query.test
      device_type = req.query.device
      devices = Devices.forge()
      registered = req.query.registered
      type = req.query.type
      event_id = req.query.event_id
      devices.query('join', 'users', 'users.user_id', '=', 'devices.user_id', 'left')
      if test == 'yes'
        devices.query('whereIn', 'devices.user_id', ['176', '6292', '179', '216']) #, '179', '216', '6292'])
      if device_type != 'all'
        devices.query('where', 'devices.type', req.query.device)
      if registered != 'all'
        if registered == 'yes'
          devices.query('join', 'registrations', 'registrations.user_id', '=', 'devices.user_id', 'left')
          devices.query('where', 'registrations.event_id', '=', '1')
          devices.query('where', 'registrations.year', '=', process.yr)
        else
          devices.query 'whereNotExists', ->
            @select('*').from('registrations').whereRaw("
              devices.user_id = registrations.user_id
              AND event_id='1'
              AND year = '"+process.yr+"'"
            )
      if type != 'all'
        types = type.split(',')
        ttypes = []
        atypes = []
        for type in types
          if ['360', 'connect'].indexOf(type) > -1
            ttypes.push type
          else
            atypes.push type
        _ttypes = (_.map ttypes, (v) ->
          "'"+v+"'"
        ).join(', ')
        _atypes = (_.map atypes, (v) ->
          "'"+v+"'"
        ).join(', ')
        if ttypes.length and atypes.length
          devices.query('whereRaw', '(users.ticket_type in ('+_ttypes+') OR users.type in ('+_atypes+'))')
        else if ttypes.length
          devices.query('whereIn', 'users.ticket_type', ttypes)
        else if atypes.length
          devices.query('whereIn', 'users.type', atypes)
      if event_id != 'all'
        devices.query('join', 'event_rsvps', 'event_rsvps.user_id', '=', 'devices.user_id', 'left')
        devices.query('where', 'event_rsvps.event_id', '=', event_id)

      devices.fetch()
      .then (rsp) ->
        user_ids = {}
        id_count = 0
        for device in rsp.models
          key = 'u_'+device.get('user_id')
          if !user_ids[key]?
            user_ids[key] = 1
            id_count += 1
        res.r.user_count = id_count
        res.r.device_count = rsp.models.length
        cb rsp.models
      , (err) ->
        console.error err


module.exports = routes
