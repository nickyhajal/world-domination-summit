Shelf = require('./shelf')
crypto = require('crypto')
geocoder = require('geocoder')
geolib = require('geolib')
Twit = require('twit')
Q = require('q')
async = require('async')

##

[Capability, Capabilities] = require './capabilities'

##

getters = require('./users/getters')
auth = require('./users/auth')
emails = require('./users/emails')
race = require('./users/race')
twitter = require('./users/twitter')
ticket = require('./users/ticket')

##

User = Shelf.Model.extend
  tableName: 'users'
  permittedAttributes: [
    'user_id', 'type', 'email', 'first_name', 'last_name', 'attending14',
    'email', 'hash', 'user_name', 'mf', 'twitter', 'facebook', 'site', 'pic', 'instagram'
    'address', 'address2', 'city', 'region', 'country', 'zip', 'lat', 'lon', 'distance',
    'pub_loc', 'pub_att', 'marker', 'intro', 'points', 'last_broadcast', 'last_shake', 
    'notification_interval', 'points'
    'pub_loc', 'pub_att', 'marker', 'intro', 'points', 'last_broadcast', 'last_shake', 'notification_interval'
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

  # Auth
  authenticate: auth.authenticate
  login: auth.login
  updatePassword: auth.updatePassword

  # Getters
  getPic: getters.getPic
  getMe: getters.getMe
  getUrl: getters.getUrl
  getDistanceFromPDX: getters.getDistanceFromPDX
  getAnswers: getters.getAnswers
  getCapabilities: getters.getCapabilities
  getInterests: getters.getInterests
  getConnections: getters.getConnections
  getFeedLikes: getters.getFeedLikes
  getAllTickets: getters.getAllTickets
  getRsvps: getters.getRsvps
  getAchievedTasks: getters.getAchievedTasks
  getFriends: getters.getFriends
  getFriendedMe: getters.getFriendedMe
  getLocationString: getters.getLocationString

  # Emails
  sendEmail: emails.sendEmail
  syncEmail: emails.syncEmail
  syncEmailWithTicket: emails.syncEmailWithTicket
  addToList: emails.addToList
  removeFromList: emails.removeFromList

  # Race
  raceCheck: race.raceCheck
  achieved: race.achieved
  markAchieved: race.markAchieved
  updateAchieved: race.updateAchieved
  processPoints: race.processPoints
  getAchievements: race.getAchievements

  # Twitter
  getTwit: twitter.getTwit
  sendTweet: twitter.sendTweet
  follow: twitter.follow
  isFollowing: twitter.isFollowing

  # Ticket
  registerTicket: ticket.registerTicket
  cancelTicket: ticket.cancelTicket


  # Capabilities
  hasCapability: (capability) ->
    if @get('capabilities')?
      for cap in @get('capabilities')
        test_capability = cap.get('capability')
        if test_capability is capability
          return true
        else
          for master_capability, sub_capability of User.capabilities_map
            if test_capability is master_capability and capability in sub_capability
              return true
    return false

  getReadableCapabilities: ->
    dfr = Q.defer()
    @set('available_top_level_capabilities', Object.keys(User.capabilities_map))
    Capabilities.forge()
    .query('where', 'user_id', @get('user_id'))
    .fetch()
    .then (rsp) =>
      if rsp.models.length
        retval = Array()
        for cap in rsp.models
          retval.push cap.get 'capability'
        @set('capabilities', retval)
      dfr.resolve this
    , (err) ->
      console.error err
    return dfr.promise

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


  getMutualFriends: (this_year = false)->
    dfr = Q.defer()
    mutual_ids = []
    mutuals = []

    # Get people I friended
    @getFriends(this_year)
    .then (my_friends) =>

      # Get people who friended me
      @getFriendedMe(this_year)
      .then (friended_mes) =>
        for my_friend in my_friends
          for friended_me in friended_mes
            if my_friend.get('to_id') isnt my_friend.get('user_id')
              if my_friend.get('to_id') is friended_me.get('user_id')
                mutual_ids.push(my_friend.get('to_id'))

        async.each mutual_ids, (mutual_id, cb) =>
          User.forge({user_id: mutual_id})
          .fetch()
          .then (mutual) ->
            mutuals.push mutual
            cb()
        , ->
          dfr.resolve(mutuals)
    return dfr.promise

User.capabilities_map =
  speakers: ["add-speaker", "speaker"]
  ambassadors: ["ambassador-review"]
  manifest: ['add-attendee', 'attendee', 'user']
  schedule: ['add-event', 'event', 'meetup', 'meetups', 'meetup-review', 'event-review']
  race: ['add-racetask', 'racetask', 'racetasks', 'rate']
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
