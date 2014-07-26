# SS - User Model

Shelf = require('./shelf')
crypto = require('crypto')
geocoder = require('geocoder')
_ = require('underscore')
_.str = require('underscore.string')
Q = require('q')
async = require('async')

##

[Ticket, Tickets] = require './tickets'
[Answer, Answers] = require './answers'
[UserInterest, UserInterests] = require './user_interests'
[Connection, Connections] = require './connections'
[TwitterLogin, TwitterLogins] = require './twitter_logins'
[Capability, Capabilities] = require './capabilities'
[FeedLike, FeedLikes] = require './feed_likes'
[Feed, Feeds] = require './feeds'
[Notification, Notifications] = require './notifications'
[EventRsvp, EventRsvps] = require './event_rsvps'

getters = require('./users/getters')()

user = 

    return Math.ceil(out)

  getAnswers: getters.getAnswers
  getCapabilities: getters.getCapabilities
  getReadableCapabilities: getters.getReadableCapabilities

  hasCapability: (capability) ->
    if @get('capabilities')?
      for cap in @get('capabilities')
        test_capability = cap.get('capability')
        if test_capability is capability
          return true
        else
          for master_capability, sub_capability of @capabilities_map
            if test_capability is master_capability and capability in sub_capability
              return true
    return false

  setCapabilities: (new_capabilities) ->
    dfr = Q.defer()
    user_id = @get('user_id')
    Capabilities.forge()
    .query('where', 'user_id', user_id)
    .fetch()
    .then (rsp) =>
      db_capabilities = Array()
      
      if rsp.models.length
        db_capabilities = rsp.models

      actual_db_capabilities = Array()
      for db_capability in db_capabilities
        actual_db_capabilities.push(db_capability.get('capability'))
      for new_capability in new_capabilities
        if new_capability not in actual_db_capabilities
          Capability.forge({user_id: user_id, capability: new_capability}).save()
      for previous_capability in db_capabilities
        if previous_capability.get('capability') not in new_capabilities
          Capabilities.forge().query('where', 'capability_id', previous_capability.get('capability_id')).fetch().then (rsp2) =>
            if rsp2.models.length
              if rsp2.models.length > 1
                console.log "WARNING: more than one model for a single capability ID. Destroying first only"
              to_destroy = rsp2.models[0]
              to_destroy.destroy()
            else
              console.log("WARNING: Attempting to destroy non-existant capability")
            model.destroy()
      dfr.resolve this
    , (err) ->
      console.error(err)
    return dfr.promise


  getInterests: ->
    dfr = Q.defer()
    UserInterests.forge()
    .query('where', 'user_id', @get('user_id'))
    .fetch()
    .then (rsp) =>
      interests = []
      for interest in rsp.models
        interests.push interest.get('interest_id')
      @set('interests', JSON.stringify(interests))
      dfr.resolve this
    , (err) ->
      console.error(err)
    return dfr.promise

  getConnections: ->
    dfr = Q.defer()
    Connections.forge()
    .query('where', 'user_id', @get('user_id'))
    .fetch()
    .then (connections) =>
      connected_ids = []
      for connection in connections.models
        connected_ids.push connection.get('to_id')
      @set
        connections: connections
        connected_ids: connected_ids
      dfr.resolve(this)
    , (err) ->
      console.error(err)
    return dfr.promise

  getFeedLikes: ->
    dfr = Q.defer()
    FeedLikes.forge()
    .query('where', 'user_id', @get('user_id'))
    .fetch()
    .then (likes) =>
      like_ids = []
      for like in likes.models
        like_ids.push like.get('feed_id')
      @set
        feed_likes: like_ids
      dfr.resolve(this)
    , (err) ->
      console.error(err)
    return dfr.promise

  getAllTickets: ->
    dfr = Q.defer()
    Tickets.forge()
    .query('where', 'user_id', @get('user_id'))
    .fetch()
    .then (rows) =>
      @set('tickets', rows.models)
      dfr.resolve this
    , (err) ->
      console.error(err)
    return dfr.promise

  getRsvps: ->
    dfr = Q.defer()
    EventRsvps.forge()
    .query('where', 'user_id', @get('user_id'))
    .fetch()
    .then (rsp) =>
      rsvps = []
      for rsvp in rsp.models
        rsvps.push rsvp.get('event_id')
      @set('rsvps', rsvps)
      dfr.resolve(@)
    return dfr.promise

  ###########
  # ADDRESS #
  ###########

  processAddress: ->
    location = @getLocationString()
    @set 'location', location
    geocoder.geocode location, (err, data) =>
      if data.results[0]
        location = data.results[0].geometry.location
        distance = geolib.getDistance
          latitude: 45.51625
          longitude: -122.683558
        ,
          latitude: location.lat
          longitude: location.lng
      @set
        lat: location.lat
        lon: location.lng
        distance: ( (distance / 1000) * 0.6214 )
      @save(null, {method: 'update'})

  getLocationString: ->
    address = @get('city')+', '
    if (@get('country') is 'US' or @get('country') is 'GB') and @get('region')?
      address += @get('region')
    unless (@get('country') is 'US' or @get('country') is 'GB')
      if countries[@get('country')]?
        address += countries[@get('country')].name
    return address


  ###########
  # TICKETS #
  ###########

  registerTicket: (eventbrite_id, returning = false, transfer_from = null) ->
    dfr = Q.defer()
    Ticket.forge
      eventbrite_id: eventbrite_id
      user_id: @get('user_id')
      year: process.year
      transfer_from: transfer_from
    .save()
    .then (ticket) =>
      @addToList('WDS '+process.year+ ' Attendees')
      .then =>
        promo = 'Welcome'
        subject = "You're coming to WDS! Awesome! Now... Create your profile!"
        if returning
          promo = 'WelcomeBack'
        @sendEmail(promo, subject)
    , (err) ->
      tk err
    return dfr.promise

  cancelTicket: ->
    dfr = Q.defer()
    @set('attending'+process.yr, '-1')
    .save()
    .then =>
      Ticket.forge
        user_id: @get('user_id')
        year: process.year
      .fetch()
      .then (ticket) =>
        if ticket
          ticket.set
            status: 'canceled'
          save()
          .then =>
            @removeFromList('WDS '+process.year+' Attendees')
            .then =>
              @addToList('WDS '+process.year+' Canceled')
              dfr.resolve [this, ticket]
        dfr.reject("Doesn't have a ticket.")
    return dfr.promise

  ###########
  # TWITTER #
  ###########

  getTwit: ->
    dfr = Q.defer()
    TwitterLogin.forge
      user_id: @get('user_id')
    .fetch()
    .then (twitter_login) ->
      twit = new Twit
        consumer_key: process.env.TWIT_KEY
        consumer_secret: process.env.TWIT_SEC
        access_token: twitter_login.get('token')
        access_token_secret: twitter_login.get('secret')
      dfr.resolve(twit)
    return dfr.promise

  sendTweet: (tweet) ->
    dfr = Q.defer()
    @getTwit()
    .then (twit) ->
      twit.post 'statuses/update',
        status: tweet, (err, reply) ->
          dfr.resolve(err, reply)
    return dfr.promise

  follow: (screen_name, cb) ->
    dfr = Q.defer()
    @getTwit (twit) ->
      twit.post 'friendships/create',
        screen_name: screen_name, (err, reply) ->
          dfr.resolve(err, reply)
    return dfr.promise

  isFollowing: (screen_name, cb) ->
    dfr = Q.defer()
    @getTwit (twit) =>
      twit.get 'friendships/exists',
        screen_name_a: @twitter
        screen_name_b: screen_name
        , (err, reply) ->
          dfr.resolve(err, reply)
    return dfr.promise

  #########
  # EMAIL #
  #########

  sendEmail: (promo, subject, params = {}) ->
    mailer = require('./mailer')
    user_params =
      first_name: @get('first_name')
      last_name: @get('last_name')
      name: @get('first_name')
      email: @get('email')
      hash: @get('hash')
    params = _.defaults user_params, params
    mailer.send(promo, subject, @get('email'), params)
    .then (err, rsp) ->

  syncEmail: ->
    @removeFromList 'WDS '+process.year+' Attendees', @before_save['email']
    @addToList 'WDS '+process.year+' Attendees'

  syncEmailWithTicket: ->
    if @get('attending14') is '1'
      @addToList 'WDS '+process.year+' Attendees'
      @removeFromList 'WDS '+process.year+' Canceled'
    else
      @removeFromList 'WDS '+process.year+' Attendees'
      @addToList 'WDS '+process.year+' Canceled'

  addToList: (list) ->
    dfr = Q.defer()
    params =
      username: process.env.MM_USER
      api_key: process.env.MM_PW
      email: @get('email')
      first_name: @get('first_name')
      last_name: @get('last_name')
      unique_link: @get('hash')
    call =
      url: 'https://api.madmimi.com/audience_lists/'+list+'/add'
      method: 'post'
      form: params
    request call, (err, code, rsp) ->
      dfr.resolve(rsp)
    return dfr.promise

  removeFromList: (list, email = false) ->
    dfr = Q.defer()
    params =
      username: process.env.MM_USER
      api_key: process.env.MM_PW
      email: @get('email')
    if email
      params.email = email
    call =
      url: 'https://api.madmimi.com/audience_lists/'+list+'/remove'
      method: 'post'
      form: params
    request call, (err, code, rsp) ->
      dfr.resolve(rsp)
    return dfr.promise

  ########
  # RACE #
  ########

  raceCheck: ->
    dfr = Q.defer()
    user = this
    muts = []
    achs = []
    checks:
      check_distance: (cb) ->
        if not user.achieved('distance', 3)
          x =1

    @getAchievements()
    .then (achs) ->
      async.each checks, (check, cb) ->
        check(cb)
      , ->
        user.processPoints()
        .then ->
          dfr.resolve()
    return dfr.promise



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

User.capabilities_map =
  speakers: ["add-speaker", "speaker"]
  ambassadors: ["ambassador-review"]
  manifest: ['add-attendee', 'attendee', 'user']
  schedule: ['add-event', 'event', 'meetup', 'meetups', 'meetup-review', 'event-review']
  race: ['add-racetask', 'racetask', 'racetasks']
  downloads: ['admin_downloads']

Users = Shelf.Collection.extend
  model: User
  getMe: (req) ->
    dfr = Q.defer()
    ident = if req.session.ident then JSON.parse(req.session.ident) else false
    if ident
      id = ident.user_id ? ident.id
      Users.forge().query('where', 'user_id', id)
      .fetch()
      .then (rsp) ->
        if rsp.models.length
          dfr.resolve rsp.models[0]
        else
          dfr.resolve false
    else
      dfr.resolve false
    return dfr.promise

  getUser: (user_id, remove_sensitive = true) ->
    dfr = Q.defer()
    _Users = Users.forge()

    # Get user accepts user_id or email
    if typeof +user_id is 'number'
      type = 'user_id'
    else if typeof user_id is 'string'
      type = 'email'

    # Run query
    _Users.query('where', type, '=', user_id)
    .fetch()
    .then (rsp)->
      results = []
      if rsp.models?[0]?
        results = rsp.models[0]
        if remove_sensitive
          results.password = null
          results.hash = null
      dfr.resolve(results)
    return dfr.promise

module.exports = [User, Users]
