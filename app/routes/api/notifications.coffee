redis = require("redis")
rds = redis.createClient()
crypto = require('crypto')
apn = require('apn')
gcm = require('node-gcm')
_ = require('underscore')
async = require('async')
_s = require('underscore.string')
moment = require('moment')

FCM = require('fcm-node');
fcm = new FCM(process.env.FCM_KEY);

routes = (app) ->

  [Notification, Notifications] = require('../../models/notifications')
  [AdminNotification, AdminNotifications] = require('../../models/admin_notifications')
  [Device, Devices] = require('../../models/devices')
  [Registration, Registrations] = require('../../models/registrations')
  [Feed, Feeds] = require('../../models/feeds')

  ntfn_routes =
    check: (req, res, next) ->
      AdminNotifications.forge().sendUnsent().then (rsp) ->
        res.r.msg = "Checked"
        next()
    get_count: (req, res, next) ->
      if req.query.device? and req.query.registered?
        ntfn_routes.get_devices req, res, (devices) ->
          next()
      else
        res.r.msg = "Missing parameters"
        next()

    message: (req, res, next) ->
      if req.me? and req.me
        name = req.me.get('first_name')+' '+req.me.get('last_name')[0]+': '
        to_ids = req.query.user_id
        async.each to_ids, (to_id, cb) ->
          tk to_id
          Notification.forge
            channel_type: 'message'
            channel_id: req.query.chat_id
            user_id: to_id
          .fetch()
          .then (existing) ->
            if existing
              existing.set
                content: JSON.stringify
                  from_id: req.me.get('user_id')
                  content_str: _s.truncate(name+req.query.summary, 200)
                read: 0
                created_at: moment().format('YYYY-MM-DD HH:mm:ss')
                clicked: 0
              existing.save()
              existing.created()
              cb()
            else
              Notification.forge
                type: 'message'
                channel_type: 'message'
                channel_id: req.query.chat_id
                title: req.query.chat_name
                user_id: to_id
                content: JSON.stringify
                  from_id: req.me.get('user_id')
                  content_str: _s.truncate(name+req.query.summary, 200)
                link: '/message/'+req.query.chat_id
                emailed: 1
              .save()
              cb()

        next()
      else
        next()

    send: (req, res, next) ->
      tk 'send'
      if req.query.device? and req.query.registered?
        ntfn_routes.get_devices req, res, (devices) ->
          tk devices
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
              tk 'create feed'
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
                        if type is 'ios' # and user_id == 176
                          note = new apn.Notification()
                          note.alert = req.query.notification_text
                          note.payload = {content: '{"user_id":"8082"}', type: 'feed_comment', link: link}
                          # tk note
                          # tk tokens
                          process.APN.pushNotification(note, tokens)
                        else if type is 'and' # and user_id == 176
                          tk 'and'
                          token = device.get('token')
                          message =
                            to: token,
                            collapse_key: "WDS Notifications"
                            notification:
                              title: "WDS App"
                              body: req.query.notification_text
                            data:
                              id: post.hash
                              user_id: '8082'
                              content: '{"user_id":"8082"}'
                              type: 'feed_comment'
                              link:  link
                          tk message
                          tk 'SEND FCM'
                          fcm.send message, (err, result) ->
                            tk 'FCM RSP:'
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
      devices.query('where', 'attending'+process.yr, '1')
      # devices.query('where', 'devices.active', '1')
      # devices.query('whereNotNull', 'devices.uuid')
      if test == 'yes'
        devices.query('whereIn', 'devices.user_id', ['176']
        #, '6292', '179', '216', '1315', '6263', '8884', '6291']) #, '179', '216', '6292'])
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
