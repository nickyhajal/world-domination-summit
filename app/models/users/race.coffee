crypto = require('crypto')
Q = require('q')
async = require('async')

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

##

checks = {}
race = 

  achieved: (task_id, achs) ->
    count = 0
    for ach in achs
      if task_id is ach.get('task_id')
        count += 1
    return count

  processPoints: ->
    dfr = Q.defer()
    Achievements.forge()
    .processPoints(@get('user_id'))
    .then (points) ->
      dfr.resolve(points)
    return dfr.promise

  getAchievements: ->
    dfr = Q.defer()
    Achievements.forge()
    .query('where', 'user_id', @get('user_id'))
    .fetch()
    .then (achs) ->
      dfr.resolve(achs.models)
    return dfr.promise

  markAchieved: (task_slug, custom_points = 0) ->
    dfr = Q.defer()
    Achievement.forge({slug:task_slug})
    .set
      user_id: @get('user_id')
      custom_points: custom_points
    .save()
    .then (ach) ->
      dfr.resolve(ach)
    return dfr.promise

  updateAchieved: (task_slug, custom_points = 0) ->
    dfr = Q.defer()
    Achievement.forge({slug:task_slug, user_id: @get('user_id')})
    .fetch()
    .then (ach) ->
      ach
      .set
        custom_points: custom_points
      .save()
      .then (ach) ->
        dfr.resolve(ach)
    return dfr.promise




  raceCheck: ->
    dfr = Q.defer()
    user = this
    muts = []
    achs = []

    @getMutualFriends()
    .then (rsp_muts) ->
      muts = rsp_muts
      @getAchievements()
      .then (rsp_achs) ->
        achs = rsp_achs
        async.each checks, (check, cb) ->
          check.call(user, cb)
        , ->
          user.processPoints()
          .then ->
            dfr.resolve()

    checks =
      profile: (cb) ->
        if not @achieved('profile')
          if +@get('intro') is 9
            @markAchieved('profile')
        cb()
      photo: (cb) ->
        if not @achieved('photo')
          if @get('pic').length > 1
            @markAchieved('pic')
        cb()
      host: (cb) ->
        if not @achieved('host-meetup')
          EventHosts.forge()
          .query('where', 'user_id', @get('user_id'))
          .fetch()
          .then (rsp) =>
            if rsp.models.length
              @markAchieved('host-meetup')
              cb()
            else
              cb()
        else
          cb()
      rsvp: (cb) ->
        if not @achieved('rsvp')
          EventRsvps.forge()
          .query('where', 'user_id', @get('user_id'))
          .fetch()
          .then (rsp) =>
            if rsp.models.length
              @markAchieved('rsvp')
              cb()
            else
              cb()
        else
          cb()
      featured_tweet: ->
        if not @achieved('featured-tweet')
          Contents::getFeaturedTweeters()
          .then (user_ids) =>
            if user_ids.indexOf(@get('user_id')) > -1
              @markAchieved('featured-tweet')
            cb()
        else
          cb()
      registration: ->
        if not @achieved('register-at-wds')
          Registrations.forge()
          .query('where', 'user_id', @get('user_id'))
          .fetch()
          .then (rsp) ->
            if rsp.models.length
              @markAchieved('register-at-wds')
            cb()
        else
          cb()
      ten_met: ->
        if not @achieved('ten-met')
          Connections.forge()
          .query('where', 'user_id', @get('user_id'))
          .fetch()
          .then (rsp) ->
            if rsp.models.length > 9
              @markAchieved('ten-met')
            cb()
        else
          cb()
      countries: ->
        countries = []
        for user in muts
          if not countries.indexOf(user.get('country'))
            countries.push user.get('country')
        points = countries.length
        if @achieved('different-countries')
          @updateAchieved('different-countries', points)
        else
          @markAchieved('different-countries', points)
      hometown: ->
        if not @achieved('hometown')
          mytown = _.slugify(@get('location'))
          for user in muts
            if mytown is _.slugify(user.get('location'))
              @markAchieved('hometown')
              break
        cb()
      




      distance: (cb) ->
        if not user.achieved('distance')


    return dfr.promise



module.exports = race