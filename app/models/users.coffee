# SS - User Model

Shelf = require('./shelf')
bcrypt = require('bcrypt')
crypto = require('crypto')
geocoder = require('geocoder')
geolib = require('geolib')
Twit = require('twit')
countries = require('country-data').countries
_ = require('underscore')
_.str = require('underscore.string')
Q = require('q')
request = require('request')

##

[Ticket, Tickets] = require './tickets'
[Answer, Answers] = require './answers'
[UserInterest, UserInterests] = require './user_interests'
[Connection, Connections] = require './connections'
[TwitterLogin, TwitterLogins] = require './twitter_logins'
[Capability, Capabilities] = require './capabilities'
[FeedLike, FeedLikes] = require './feed_likes'
[Notification, Notifications] = require './notifications'

User = Shelf.Model.extend
  tableName: 'users'
  permittedAttributes: [
    'user_id', 'type', 'email', 'first_name', 'last_name', 'attending14',
    'email', 'hash', 'user_name', 'mf', 'twitter', 'facebook', 'site', 'pic', 'instagram'
    'address', 'address2', 'city', 'region', 'country', 'zip', 'lat', 'lon', 'distance',
    'pub_loc', 'pub_att', 'marker', 'intro', 'points', 'last_broadcast', 'last_shake'
  ]
  defaults:
    pic: ''
    location: ''
    address: ''
    address2: ''
    region: ''
    city: ''
    zip: ''
    country: ''
  idAttribute: 'user_id'
  hasTimestamps: true
  initialize: ->
    this.on 'creating', this.creating, this
    this.on 'saved', this.saved, this
    this.on 'saving', this.saving, this

  creating: (e)->
    self = this
    userData = self.attributes
    email_hash = crypto.createHash('md5').update(self.get('email')).digest('hex')
    rand = (new Date()).valueOf().toString() + Math.random().toString()
    user_hash = crypto.createHash('sha1').update(rand).digest('hex')
    @set
      email_hash: email_hash
      user_name: user_hash
      hash: user_hash
    return true

  saving: (e) ->
    @saveChanging()

  saved: (obj, rsp, opts) ->
    @id = rsp
    addressChanged = @lastDidChange [
      'address', 'address2', 'city'
      'region', 'country', 'zip'
    ]
    @addressChanged = addressChanged

    if @lastDidChange ['email'] and @get('type') is 'attendee' and @get('attending14') is '1'
      @syncEmail()

    if @lastDidChange ['attending14']
      @syncEmailWithTicket()


  ########
  # AUTH #
  ########

  authenticate: (clear, req) ->
    dfr = Q.defer()
    bcrypt.compare clear, @get('password'), (err, matched) =>
      if matched
        if req
          @login req
          dfr.resolve(true)
        else
          dfr.resolve(false)
      else
          dfr.resolve(false)
    return dfr.promise

  login: (req) ->
    req.session.ident = JSON.stringify(this)
    req.session.save()

  updatePassword: (pw) ->
    dfr = Q.defer()
    if pw.length
      bcrypt.genSalt 10, (err, salt) =>
        bcrypt.hash pw, salt, (err, hash) =>
          @set('password', hash)
          @save()
          .then (res) ->
            x = res
          , (err) ->
            console.error(err)
          dfr.resolve(this)

    else
      dfr.resolve(false)
    return dfr.promise

  #######
  # GET #
  #######

  getUrl: (text = false, clss = false, id = false) ->
    user_name = @get('user_name')
    clss = if clss then ' class="'+clss+'"' else ''
    id = if id then ' id="'+id+'"' else ''
    if user_name.length isnt 32
      url = '/~'+user_name
    else
      url = '/slowpoke'
    href = 'http://'+process.dmn+url
    text = if text then text else href
    return '< href="'+href+'"'+clss+id+'>'+text+'</a>'

  # Distance from PDX
  getDistanceFromPDX: (units = 'mi', opts = {}) ->
    distance = @get('distance')
    if unit is 'km'
      out = (distance * 1.60934 ) + ' km'
    else
      out = distance + ' mi'
    return Math.ceil(out)

  getAnswers: ->
    dfr = Q.defer()
    Answers.forge()
    .query('where', 'user_id', @get('user_id'))
    .fetch()
    .then (rsp) =>
      @set('answers', JSON.stringify(rsp.models))
      dfr.resolve this
    , (err) ->
      console.error(err)
    return dfr.promise

  getCapabilities: ->
    dfr = Q.defer()
    Capabilities.forge()
    .query('where', 'user_id', @get('user_id'))
    .fetch()
    .then (rsp) =>
      if rsp.models.length
        @set('capabilities', rsp.models)
      dfr.resolve this
    , (err) ->
      console.error(err)
    return dfr.promise

  hasCapability: (capability) ->
    map =
      user: 'manifest'
      "add-attendee": 'manifest'
      speaker: 'speakers'
      "add-speaker": 'speakers'
      "ambassador-review": 'ambassadors'
      "add-event": 'schedule'
      "event": 'schedule'
      "meetup-review": 'schedule'
      "meetup": 'schedule'
      "meetups": 'schedule'
      "racetasks": "race"
      "add-racetask": "race"
      "racetask": "race"
    capability = map[capability] ? capability
    if @get('capabilities')?
      for cap in @get('capabilities')
        if cap.get('capability') is capability
          return true
    return false

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

  checkFeedActivity: ->
    

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
