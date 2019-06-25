crypto = require('crypto')
moment = require('moment');
Q = require('q')
async = require('async')
_s = require('underscore.string')
knex = require('knex');
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
    if achs[task_id]
      return achs[task_id]
    else
      return false
  processPoints: ->
    return Achievements.forge()
    .processPoints(@get('user_id'))

  getAchievements: ->
    dfr = Q.defer()
    if @get('achs')?
      dfr.resolve(@get('achs'))
    else
      Achievements.forge()
      .query('where', 'user_id', @get('user_id'))
      .query('where', 'add_points', '<>', '-1')
      .query('join', 'racetasks', 'race_achievements.task_id', '=', 'racetasks.racetask_id', 'left')
      .fetch
        columns: ['task_id', 'slug', 'points']
      .then (achs) ->
        out = {}
        for ach in achs.models
          if not out[ach.get('slug')]?
            out[ach.get('slug')] = (+ach.get('points') + +ach.get('add_points') + +ach.get('custom_points'))
          # else
          #   out[ach.get('slug')] += 1
        dfr.resolve(out)
    return dfr.promise

  syncAchievements: (data) ->
    user_id = @get('user_id')
    achs = Achievements.forge()
    Q.all([
      @getAchievements(),
      achs.achsSince(moment().startOf('year').format('YYYY-MM-DD hh:mm:ss'), user_id),
      achs.achsSince(moment().subtract(24, 'h').format('YYYY-MM-DD hh:mm:ss'), user_id),
      achs.achsSince(moment().subtract(1, 'h').format('YYYY-MM-DD hh:mm:ss'), user_id),
    ])
    .then ([achs, achsAll, achsDay, achsHour]) => 
      process.fire.database().ref().child('race/user/'+@get('user_id')).set({
        achieved: achs
        achs: {
          all: achsAll
          day: achsDay
          hour: achsHour
        }
        points: data.points,
        ranks: data.ranks,
      })

  markAchieved: (task_slug, custom_points = 0) ->

    # More advanced racetask checking
    dfr = Q.defer()
    @getAchievements()
    .then (achs) =>
      RaceTask.forge({slug: task_slug})
      .fetch()
      .then (task) =>
        if task
          task_id = task.get('racetask_id')
          times = achs[task.get('slug')] ? 0
          if +times < +task.get('attendee_max')
            Achievement.forge
              user_id: @get('user_id')
              task_id: task_id
              custom_points: custom_points
            .save()
            .then (ach) =>
              rsp = 
                ach_id: ach.get('ach_id')
              @processPoints()
              .then (points) =>
                @set('points', points.all)
                .save()
                .then =>
                  @syncAchievements(points).then ->
                    rsp.points = points
                    dfr.resolve(rsp)
            , (err) ->
              console.error(err)
          else
            tk 'Above attendee max: ' + task_slug
            dfr.resolve(false)
        else
          tk 'TASK NOT FOUND: ' + task_slug
          dfr.resolve(false)
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
        .then (ach) =>
          @syncAchievements().then ->
            dfr.resolve(ach)
      return dfr.promise

  raceCheck: ->
    dfr = Q.defer()
    user_key = @get('user_id')+'_racecheck'
    user = this
    muts = []
    achs = []
    rds.get user_key, (err, check_done) =>
      if not check_done? or 1
        checks = getChecks()
        start = +(new Date())
        user.getMutualFriends(true)
        .then (rsp_muts) ->
          muts = rsp_muts
          user.getAchievements()
          .then (rsp_achs) ->
            achs = rsp_achs
            user.achs = achs
            async.each checks, (check, cb) ->
              check.call(user, cb)
            , ->
              user.processPoints()
              .then (points) ->
                tk ('Race check took: '+((new Date()) - start )+' milliseconds')
                user.set('points', points)
                .save().then()
                dfr.resolve(points)
                rds.set user_key, 'true', ->
                  rds.expire user_key, 90
      else
        tk 'Skipped Race Check for '+@get('user_name')
        dfr.resolve()

    getChecks = ->
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

        # Completed all drink tasks
        (cb) ->
          drink_tasks = ['drink-a-local-beer','drink-a-local-coffee','drink-a-local-spirit','drink-a-local-wine', 'drink-a-local-tea']
          if not @achieved('bonus-point-for-completing-all-5-drinking-challenges', achs)
            acheived = true
            for task in drink_tasks
              if not @achieved(task, achs)
                acheived = false
            if acheived
              @markAchieved('bonus-point-for-completing-all-5-drinking-challenges')
            cb()
          else
            cb()

        #Featured Tweet
        (cb) ->
          if not @achieved('get-one-of-your-tweets-featured-by-the-wds-team', achs)
            Contents::getFeaturedTweeters()
            .then (user_ids) =>
              if user_ids.indexOf(@get('user_id')) > -1
                @markAchieved('get-one-of-your-tweets-featured-by-the-wds-team')
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
        # (cb) ->
        #   if not @achieved('friend-10-attendees-on-wdsfm', achs)
        #     Connections.forge()
        #     .query('where', 'user_id', @get('user_id'))
        #     .fetch()
        #     .then (rsp) =>
        #       if rsp.models.length > 9
        #         @markAchieved('ten-met')
        #       cb()
        #   else
        #     cb()
        # , 
        # Five
        (cb) ->
            points = Math.floor(muts.length % 5)
            if @achieved('1-point-for-every-5-mutually-friended-attendees-on-wdsfm', achs)
              @updateAchieved('1-point-for-every-5-mutually-friended-attendees-on-wdsfm', points)
            else
              @markAchieved('1-point-for-every-5-mutually-friended-attendees-on-wdsfm', points)
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
            if @achieved('earn-1-point-for-each-attendee-you-mark-as-a-friend-from-a-different-country', achs)
              @updateAchieved('earn-1-point-for-each-attendee-you-mark-as-a-friend-from-a-different-country', points)
            else
              @markAchieved('earn-1-point-for-each-attendee-you-mark-as-a-friend-from-a-different-country', points)
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
              to_id: '2982'
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
      return checks
    return dfr.promise

module.exports = race