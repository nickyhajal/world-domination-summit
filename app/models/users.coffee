Shelf = require('./shelf')
crypto = require('crypto')
geocoder = require('geocoder')
geolib = require('geolib')
moment = require('moment')
Twit = require('twit')
_ = require('underscore')
Q = require('q')
async = require('async')

##


raceRef = require('../util/raceRef')
[Capability, Capabilities] = require './capabilities'
[Event, Events] = require './events'
[Ticket, Tickets] = require './tickets'

##

getters = require('./users/getters')
auth = require('./users/auth')
emails = require('./users/emails')
race = require('./users/race')
twitter = require('./users/twitter')
ticket = require('./users/ticket')
card = require('./users/card')

##

User = Shelf.Model.extend
  tableName: 'users'
  permittedAttributes: [
    'user_id', 'type', 'email', 'title', 'first_name', 'last_name', 'attending14', 'attending15', 'attending16',
    'email', 'hash', 'user_name', 'mf', 'twitter', 'facebook', 'site', 'pic', 'instagram', 'phone',
    'address', 'address2', 'city', 'region', 'country', 'zip', 'lat', 'lon', 'distance', 'calling_code',
    'pub_loc', 'pub_att', 'marker', 'intro', 'points', 'last_broadcast', 'last_shake', 'accommodation',
    'notification_interval', 'points', 'tour', 'ticket_type', 'academy', 'size', 'attending17',
    'pub_loc', 'pub_att', 'marker', 'intro', 'points', 'last_broadcast', 'last_shake', 'notification_interval'
  ]
  limitedAttributes: [
    'user_id', 'type', 'email', 'title', 'first_name', 'last_name', 'attending14', 'attending15', 'attending16', 'attending17',
    'instagram', 'lat', 'lon', 'distance', 'pub_loc', 'location', 'ticket_type', 'tour', 'intro', 'size',
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
    @transferFrom = null
    this.on 'creating', this.creating, this
    this.on 'saved', this.saved, this
    this.on 'saving', this.saving, this
  creating: (e)->
    self = this
    userData = self.attributes
    email_hash = crypto.createHash('md5').update(self.get('email')).digest('hex')
    rand = (new Date()).valueOf().toString() + Math.random().toString()
    user_hash = crypto.createHash('sha1').update(rand).digest('hex')
    type = this.get('type') || 'attendee'
    @set
      email_hash: email_hash
      user_name: user_hash
      last_broadcast: moment().subtract(1, 'days').format('YYYY-MM-DD')
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

    # if @lastDidChange ['points']
    #   process.fire.database().ref().child(raceRef()+'/user/'+@get('user_id')+'/points').set(@get('points'))
    if @lastDidChange ['email'] and @get('attending'+process.yr) is '1'
      @syncEmail()

    if @lastDidChange ['attending'+process.yr]
      tk 'DID CHANGE YEAR'
      @syncEmailWithTicket()
      attending = @get('attending'+process.yr)
      tk @transferFrom
      if attending is '1' and @transferFrom
        @registerTicket(1, 0, @transferFrom)
        .then =>
          Tickets.forge().query (qb) =>
            qb.where('user_id', @get('user_id'))
            qb.where('status', 'unclaimed')
          .fetch()
          .then (rsp) =>
            ticket = rsp.models[0]
            @connectTicket(ticket, false, true)
      else if attending is '0'
        tk 'CANCEL'
        @cancelTicket()


  markAsTransfer: (transferFrom) ->
    @transferFrom = transferFrom
    return @

  syncAttending: ->
    dfr = Q.defer()
    @getCurrentTickets().then (user) =>
      atnStr = 'attending'+process.yr
      attending = @get('tickets').find (t) =>
        return (t.get('user_id') is @get('user_id') and t.get('status') is 'active')
      saysAttending = @get(atnStr) is '1'
      if (attending)
        saysAttending = '1'
        type = @get('tickets')[0].get('type')
      else if(!attending and saysAttending)
        saysAttending = '-1'
        type = ''
      update = {};
      update[atnStr] = saysAttending
      update.ticket_type = type
      @save(update, {patch: true}).then =>
        dfr.resolve(this)
    return dfr.promise

  processNotifications: ->
    dfr = Q.defer()
    [Notification, Notifications] = require('./notifications')
    Notifications.forge().query (qb) =>
      qb.where('user_id', @get('user_id'))
      qb.where('read', '0')
    .fetch()
    .then (rsp) =>
      notns = rsp.models
      process.fire.database().ref().child('users/'+@get('user_id')+'/notification_count').set(notns.length)
      dfr.resolve(notns.length)
    dfr.promise
      # out = []
      # for n in notns
      # 	if n.get('type') != 'message'
      # 		out.push n.attributes
      # 	else
      # 		# We don't want 20 notifications from the same message
      # 		# so we always replace the last with the newest
      # 		chat_id = n.get('link').replace('/message/', '')
      # 		found = false
      # 		for i in [0..(out.length-1)]
      # 			m = out[i]
      # 			if m.type == 'message'
      # 				if m.link.indexOf(chat_id)
      # 					found = true
      # 					out[i] = n.attributes
      # 		unless found
      # 			out.push n.attributes
      # o = {}
      # c = 0
      # for el in out
      # 	o[''+c] = el
      # 	c += 1
      # process.fire.database().ref().child('notifications/'+@get('user_id')+'/').set(o)


  # Auth
  authenticate: auth.authenticate
  login: auth.login
  updatePassword: auth.updatePassword
  requestUserToken: auth.requestUserToken

  # Card
  getCard: card.getCard
  getStripeCustomer: card.getStripeCustomer

  # Getters
  getPic: getters.getPic
  getFullName: getters.getFullName
  getMe: getters.getMe
  getUrl: getters.getUrl
  getDistanceFromPDX: getters.getDistanceFromPDX
  getAnswers: getters.getAnswers
  getCapabilities: getters.getCapabilities
  getInterests: getters.getInterests
  getConnections: getters.getConnections
  getFeedLikes: getters.getFeedLikes
  getAllTickets: getters.getAllTickets
  getCurrentTickets: getters.getCurrentTickets
  getRsvps: getters.getRsvps
  getAchievedTasks: getters.getAchievedTasks
  getFriends: getters.getFriends
  getFriendedMe: getters.getFriendedMe
  getLocationString: getters.getLocationString
  getFire: getters.getFire
  getRegistration: getters.getRegistration

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
  syncAchievements: race.syncAchievements
  updateAchieved: race.updateAchieved
  processPoints: race.processPoints
  markAchievedSimple: race.markAchievedSimple
  getAchievements: race.getAchievements

  # Twitter
  getTwit: twitter.getTwit
  sendTweet: twitter.sendTweet
  follow: twitter.follow
  isFollowing: twitter.isFollowing

  # Ticket
  preregisterTicket: ticket.preregisterTicket
  registerTicket: ticket.registerTicket
  connectTicket: ticket.connectTicket
  assignTicket: ticket.assignTicket
  transferTicket: ticket.transferTicket
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

  processAddress: (cb = false) ->
    location = @getLocationString()
    @set 'location', location
    geocoder.geocode location, (err, data) =>
      if data.results[0]
        latlon = data.results[0].geometry.location
        distance = geolib.getDistance
          latitude: 45.51625
          longitude: -122.683558
        ,
          latitude: latlon.lat
          longitude: latlon.lng
        @set
          lat: latlon.lat
          lon: latlon.lng
          distance: ( (distance / 1000) * 0.6214 )
      if !@get('region')? or !@get('region').length or !(+@get('region'))
        if data?.results[0]?.address_components?[4]?
          short = data.results[0].address_components[4].short_name
          long = data.results[0].address_components[4].long_name
          @set
            region: (if @get('country') == 'US' then short else long)
      try
        @save(null, {method: 'update'})
      catch
        console.log('no address update')
      if cb
        cb(@)
    , {key: process.env.GEOCODE_KEY} 

  similar_meetups: ->
    dfr = Q.defer()
    Events.forge()
    .query('join', 'event_interests', 'events.event_id', '=', 'event_interests.event_id', 'inner')
    .query('join', 'user_interests', 'user_interests.interest_id', '=', 'event_interests.interest_id', 'inner')
    .query('where', 'user_id', @get('user_id'))
    .query('where', 'type', 'meetup')
    .query('where', 'active', '1')
    .fetch()
    .then (events) ->
      meetups = events.models
      #Shuffle the meetups and return the top 5

      for i in [meetups.length-1..1]
        j = Math.floor Math.random() * (i + 1)
        [meetups[i], meetups[j]] = [meetups[j], meetups[i]]
      dfr.resolve meetups[0...5]
    , (err) ->
      console.error err
    return dfr.promise


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

  similar_attendees: (include_user = false, quantity = 5) ->
    dfr = Q.defer()
    @getInterests()
    .then (user) ->
      columns = {columns: ['users.user_id']}
      if include_user
        columns = {columns: ['users.user_id', 'first_name', 'last_name', 'user_name', 'pic']}
      Users.forge()
      .query('join', 'user_interests', 'user_interests.user_id', '=', 'users.user_id', 'inner')
      .query('where', 'user_interests.interest_id', 'in', [user.get('interests')])
      #.query('where', 'users.attending'+process.yr, '1')
      .fetch(columns)
      .then (users) ->
        users = _.shuffle users.models
        retval = []
        for user in users[0...quantity]
          if include_user
            retval.push user
          else
            retval.push user.get('user_id')
        dfr.resolve retval
      , (err) ->
        console.error err
    dfr.promise


User.capabilities_map =
  speakers: ["add-speaker", "speaker"]
  ambassadors: ["ambassador-review"]
  manifest: ['add-attendee', 'attendee', 'user', 'transactions', 'transfers']
  places: ['add-place', 'place']
  schedule: ['add-event', 'event', 'meetup', 'meetups', 'meetup-review', 'event-review', 'meetup-print', 'add-academy', 'academies', 'academy', 'event-export']
  race: ['add-racetask', 'racetask', 'racetasks', 'rate', 'race-review']
  downloads: ['admin_downloads']
  screens: ['screens']
  notification: ['notification']

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
    if (''+user_id).indexOf('@') > 0
      type = 'email'
    else if (''+user_id).length == 40
      type = 'hash'
    else
      type = 'user_id'

    # Run query
    _Users.query('where', type, '=', user_id)
    .fetch()
    .then (rsp)->
      results = []
      if rsp.models?[0]?
        results = rsp.models[0]
        if remove_sensitive
          if results.password? and results.password.length
            results.has_pw = true
          results.password = null
          results.hash = null
      dfr.resolve(results)
    return dfr.promise
  
  search: (query) ->
    dfr = Q.defer()
    _Users = Users.forge()
    all = {}
    years = []
    types = []
    if query.types?.length
      types = query.types?.split(',')
    if query.years?.length
      years = query.years?.split(',')
    if query.user_token
      years = [process.yr]
    years = [process.yr] if !years.length
    types = ['360', 'connect'] if !types.length
    doQuery = (col, q = false) ->
      idfr = Q.defer()
      _Users.query (qb) ->
        where = ''
        params = []
        if q
          where += col+' LIKE ?'
          params.push q
        # if query.types?.length
        #   if q
        #     where += ' AND '
        #   where += 'ticket_type IN ('
        #   c = false
        #   for t in types
        #     where += ', ' if c
        #     where += '?'
        #     params.push t
        #     c = true
        #   where += ')'
        # if years?.length
        #   # if q and q.query.types?.length
        #   where += ' AND ('
        #   c = false
        #   for y in years
        #     where += ' OR ' if c
        #     where += ' attending'+y+ '= ?'
        #     if (y == '18')
        #       where += ' OR '
        #       where += ' pre'+y+ '= ?'
        #       params.push '1'
        #     params.push '1'
        #     c = true
        #   where += ')'
        qb.whereRaw(where, params)
        qb.limit(100)
      .fetch()
      .then (rsp) ->
        idfr.resolve(rsp)
      , (err) ->
        tk 'err'
        console.error(err)
      return idfr.promise

    terms = if query.search? then query.search.split(' ') else []
    if (terms.length == 1 && (terms[0].length == 40 || terms[0].indexOf('@') > 0))
      Users.forge().getUser(terms[0]).then (user) -> 
        dfr.resolve([user.attributes])
    else
      async.each terms, (term, cb) ->
        doQuery('first_name', term+'%')
        .then (byF) ->
          for f in byF.models
            id = f.get('user_id')
            all[id] = f.attributes unless all[id]
            if all[id].score? then all[id].score += 2 else (all[id].score = 4)
          doQuery('last_name', term+'%')
          .then (byL) ->
            # doQuery('email', '%'+term+'%')
            # .then (byE) ->
            for l in byL.models
              id = l.get('user_id')
              all[id] = l.attributes unless all[id]
              if all[id].score? then all[id].score += 5 else (all[id].score = 1)
            # for e in byE.models
            # 	id = e.get('user_id')
            # 	all[id] = e.attributes unless all[id]
            # 	if all[id].score? then all[id].score += 1 else (all[id].score = 1)
            cb()
      , (err) ->
        sortable = []
        for id,user of all
          if user['attending'+process.yr] is '1'
            user.score += 10
          sortable.push user
        sortable.sort (a, b) ->
          return a.score - b.score
        sortable.reverse()
        dfr.resolve(sortable)
    return dfr.promise

module.exports = [User, Users]
