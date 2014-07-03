crypto = require('crypto')
Q = require('q')
async = require('async')
_s = require('underscore.string')
redis = require("redis")
rds = redis.createClient()

##

[Ticket, Tickets] = require '../tickets'
[Answer, Answers] = require '../answers'
[UserInterest, UserInterests] = require '../user_interests'
[Connection, Connections] = require '../connections'
[Capability, Capabilities] = require '../capabilities'
[FeedLike, FeedLikes] = require '../feed_likes'
[Feed, Feeds] = require '../feeds'
[EventRsvp, EventRsvps] = require '../event_rsvps'
[EventHost, EventHosts] = require '../event_hosts'
[Registration, Registrations] = require '../registrations'
[Content, Contents] = require '../contents'
[Achievement, Achievements] = require '../achievements'
[RaceTask, RaceTasks] = require '../racetasks'

##

checks = {}
race = 

  achieved: (task_id, achs) ->
    count = 0
    if achs[task_id]
      return achs[task_id]
    else
      return false

  processPoints: ->
    dfr = Q.defer()
    Achievements::processPoints(@get('user_id'))
    .then (points) ->
      dfr.resolve(points)
    return dfr.promise

  getAchievements: ->
    dfr = Q.defer()
    Achievements.forge()
    .query('where', 'user_id', @get('user_id'))
    .query('join', 'racetasks', 'race_achievements.task_id', '=', 'racetasks.racetask_id', 'left')
    .fetch
      columns: ['task_id', 'slug', 'points']
    .then (achs) ->
      out = {}
      for ach in achs.models
        out[ach.get('slug')] = true
      dfr.resolve(out)
    return dfr.promise

  markAchieved: (task_slug, custom_points = 0) ->
    # More advanced racetask checking
    dfr = Q.defer()
    RaceTask.forge({slug: task_slug})
    .fetch()
    .then (task) =>
      task_id = task.get('racetask_id')
      Achievement.forge()
      .set
        user_id: @get('user_id')
        task_id: task_id
        custom_points: custom_points
      .save()
      .then (ach) =>
        rsp = 
          ach_id: ach.get('ach_id')
        @processPoints()
        .then (points) =>
          @set('points', points)
          .save()
          .then ->
            rsp.points = points
            dfr.resolve(rsp)
      , (err) ->
        console.error(err)
    return dfr.promise

  updateAchieved: (task_slug, custom_points = 0) ->
    dfr = Q.defer()
    RaceTask.forge({slug: task_slug})
    .fetch()
    .then (task) =>
      Achievement.forge
        task_id:task.get('racetask_id'), 
        user_id: @get('user_id')
      .fetch()
      .then (ach) =>
        ach
        .set
          custom_points: custom_points
        .save()
        .then (ach) ->
          dfr.resolve(ach)
      return dfr.promise

  raceCheck: ->
    dfr = Q.defer()
    user_key = @get('user_id')+'_racecheck'
    rds.get user_key, (err, check_done) =>
      if not check_done?
        user = this
        muts = []
        achs = []
        checks = {}
        start = +(new Date())

        user.getMutualFriends()
        .then (rsp_muts) ->
          muts = rsp_muts
          user.getAchievements()
          .then (rsp_achs) ->
            achs = rsp_achs
            async.each checks, (check, cb) ->
              check.call(user, cb)
            , ->
              user.processPoints()
              .then (points) ->
                tk ('Race check took: '+((new Date()) - start )+' milliseconds')
                dfr.resolve(points)
                rds.set user_key, 'true', ->
                  rds.expire user_key, 300
      else
        tk 'Skipped Race Check for '+@get('user_name')
        dfr.resolve()

    checks = [
      # Profile 
      (cb) ->
        if not @achieved('profile', achs)
          if +@get('intro') is 8
            @markAchieved('profile')
        cb()
      ,

      # Photo
      (cb) ->
        if not @achieved('pic', achs)
          if @get('pic').length > 1
            @markAchieved('pic')
        cb()
      ,
      # Host
      (cb) ->
        if not @achieved('host-meetup', achs)
          EventHosts.forge()
          .query('where', 'user_id', @get('user_id'))
          .fetch()
          .then (rsp) =>
            if rsp.models.length
              @markAchieved('host-meetup')
            cb()
        else
          cb()
      ,

      # RSVP
      (cb) ->
        if not @achieved('rsvp', achs)
          EventRsvps.forge()
          .query('where', 'user_id', @get('user_id'))
          .fetch()
          .then (rsp) =>
            if rsp.models.length
              @markAchieved('rsvp')
            cb()
        else
          cb()
      ,

      #Featured Tweet
      (cb) ->
        if not @achieved('featured-tweet', achs)
          Contents::getFeaturedTweeters()
          .then (user_ids) =>
            if user_ids.indexOf(@get('user_id')) > -1
              @markAchieved('featured-tweet')
            cb()
        else
          cb()
      ,

      # Register
      (cb) ->
        if not @achieved('register-at-wds', achs)
          Registrations.forge()
          .query('where', 'user_id', @get('user_id'))
          .fetch()
          .then (rsp) =>
            if rsp.models.length
              @markAchieved('register-at-wds')
            cb()
        else
          cb()
      ,

      # Ten Met
      (cb) ->
        if not @achieved('ten-met', achs)
          Connections.forge()
          .query('where', 'user_id', @get('user_id'))
          .fetch()
          .then (rsp) =>
            if rsp.models.length > 9
              @markAchieved('ten-met')
            cb()
        else
          cb()
      , 

      # Countries
      (cb) ->
          countries = []
          for friend in muts
            country = friend.get('country')
            if countries.indexOf(country) is -1
              countries.push country
          points = countries.length
          if @achieved('different-countries', achs)
            @updateAchieved('different-countries', points)
          else
            @markAchieved('different-countries', points)
          cb()
      ,    
      # Home Town
      (cb) ->
        if not @achieved('hometown', achs)
          mytown = _s.slugify(@get('location'))
          for friend in muts
            if mytown is _s.slugify(friend.get('location'))
              @markAchieved('hometown')
              break
        cb()
      ,
      # Furthest away
      (cb) ->
        if not @achieved('distance', achs)
          Connection.forge
            user_id: @get('user_id')
            to_id: '3712' # GET ACTUAL USER ID
          .fetch()
          .then (connection) =>
            if connection
              @markAchieved('distance')
            cb()
        else
          cb()
      , 
      # Post to Community
      (cb)->
        if not @achieved('wds-community', achs)
          Feeds.forge()
          .query('where', 'channel_type', 'interest')
          .query('where', 'user_id', @get('user_id'))
          .fetch()
          .then (rsp) =>
            if rsp.models.length
              @markAchieved('wds-community')
            cb()
        else
          cb()
    ]

    return dfr.promise

module.exports = race