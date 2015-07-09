redis = require("redis")
rds = redis.createClient()
crypto = require('crypto')
apn = require('apn')
gcm = require('node-gcm')

routes = (app) ->

  [Notification, Notifications] = require('../../models/notifications')
  [Device, Devices] = require('../../models/devices')
  [Registration, Registrations] = require('../../models/registrations')
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
        ntfn_routes.get_devices req, res, (rsp) ->
          if +res.r.device_count > 0
            if req.query.dispatch_text?
              uniq = moment().format('YYYY-MM-DD HH:mm') + post.content + post.user_id
              post =
                content: req.query.dispatch_text
                user_id: '8082'
                hash: crypto.createHash('md5').update(uniq).digest('hex')
              Feed.forge
                hash: post.hash
              .fetch()
              .then (existing) ->
                if not existing
                  feed = Feed.forge post
                  feed
                  .save()
                  .then (feed) ->
                    feed_id = feed.get('feed_id')
                    if feed_id.length
                      for device in devices
                        tokens = [device.get('token')]
                        type = device.get('type')
                        user_id = device.get('user_id')
                        link = '/dispatch/'+feed_id
                        if type is 'ios' and user_id == '176'
                          note = new apn.Notification()
                          note.alert = req.query.notification_text
                          note.payload = {content: {}, type: 'feed_comment', link: link}
                          process.APN.pushNotification(note, tokens)
                        else if type is 'and' and user_id == '176'
                          message = new gcm.Message
                          collapseKey: "WDS Notifications"
                          data:
                            title: "WDS App"
                            message: str
                            id: post.hash
                            user_id: '8082'
                            content: req.query.notification_text
                            type: 'feed_comment'
                            link: link
                          process.gcmSender.send message, tokens, (err, result) ->
                      res.r.sent = true
                      next()
                else
                  res.r.msg = 'You already posted that!'
                  res.status(409)
                  next()
      else
        res.r.msg = "Missing parameters"
        next()


    get_devices: (req, res, cb) ->
      device_type = req.query.device
      devices = Devices.forge()
      registered = req.query.registered
      devices.query('join', 'users', 'users.user_id', '=', 'devices.user_id', 'left')
      if device_type != 'all'
        devices.query('where', 'devices.type', req.query.device)
      if registered != 'all'
        devices.query('join', 'registrations', 'registrations.user_id', '=', 'devices.user_id', 'left')
        if registered == 'yes'
          devices.query('where', 'registrations.year', '=', process.year)
        else
          devices.query('whereNull', 'registrations.year')
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
