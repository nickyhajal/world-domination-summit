geocoder = require('geocoder')
Q = require('q')
async = require('async')
moment = require('moment')

Shelf = require('./shelf')


Event = Shelf.Model.extend
  tableName: 'events'
  hasTimestamps: true
  idAttribute: 'event_id'
  permittedAttributes: [
    'event_id', 'year', 'ignored', 'type', 'for_type', 'title', 'descr', 'what', 'active',
    'note', 'place', 'who', 'utc', 'end', 'venue', 'address', 'note', 'max', 'bios',
    'free_max', 'format', 'outline', 'venue_note', 'price', 'pay_link'
  ]
  defaults: {
  	descr: ''
  }
  initialize: ->
    this.on 'saved', this.saved, this
    this.on 'saving', this.saving, this

  updateRsvpCount: ->
    [EventRsvp, EventRsvps] = require('./event_rsvps')
    event_id = @get('event_id')
    EventRsvps.forge()
    .query('where', 'event_id', event_id)
    .fetch()
    .then (rsp) =>
      if rsp.models?.length?
        @set 'num_rsvps', rsp.models.length
      @save()

  saving: (e) ->
    @saveChanging()

  saved: (obj, rsp, opts) ->
    @id = rsp
    tk 'saved'
    addressChanged = @lastDidChange ['address']
    tk addressChanged
    if (addressChanged and @get('address')?.length) || (@get('address')?.length && !@get('lat')?)
      @processAddress()
    return true

  processAddress: ->
    address = @get('address')
    if address.indexOf('Portland') < 0
      address += ', Portland'
    if address.indexOf('OR') < 0
      address += ', OR'
    geocoder.geocode address, (err, data) =>
      if data.results[0]
        Event.forge({event_id: @get('event_id')})
        .fetch()
        .then (event) ->
          location = data.results[0].geometry.location
          event.set
            lat: location.lat
            lon: location.lng
          event.save()

  list: ->
    process.year+ ' Academy: '+ @get('what').substr(0, 32)

  sendAcademyConfirmation: (user_id) ->
    [User, Users] = require('./users')
    User.forge
      user_id: user_id
    .fetch()
    .then (user) =>
      if user
        user.addToList(@list())
        .then =>
          user.sendEmail 'academy-confirmation', 'You\'re registered for a WDS Academy!',
            what: @get('what')
            venue: @get('place')
            start: moment(@get('start')).format('MMMM Do [at] h:mma')
  sendRsvpConfirmation: (user_id) ->
    [User, Users] = require('./users')
    User.forge({user_id: user_id})
    .fetch()
    .then (user) =>
      promo = 'event_confirmation_paid' #'event_confirmation_'+user.get('ticket_type')
      start = (@get('start')+'').split(' GMT')
      start = moment(start[0])
      start = start.format('YYYY-MM-DD HH:mm:ss')
      timeStr = moment(start).format('h:mm a')
      dayStr = moment(start).format('dddd[,] MMMM Do')
      params =
        venue: @get('place')
        event_name: @get('what')
        startStr: dayStr+' at '+timeStr
      subName = @get('what')
      if subName.length > 35
        subName = subName.substr(0, 32)+'...'
      subject = "See you at \""+subName+'"'
      user.sendEmail promo, subject, params
  hosts: ->
    [User, Users] = require './users'
    dfr = Q.defer()
    Users.forge()
    .query('join', 'event_hosts', 'event_hosts.user_id', '=', 'users.user_id', 'inner')
    .query('join', 'events', 'events.event_id', '=', 'event_hosts.event_id', 'inner')
    .query("where", "events.event_id", @get('event_id'))
    .fetch()
    .then (rsp) ->
      hosts = rsp.models
      dfr.resolve(hosts)
    , (err) ->
      console.error err
    return dfr.promise

Events = Shelf.Collection.extend
  model: Event
  processAddresses: ->
    Events.query (qb) -> 
      qb.where('year', process.yr)
    .fetch()
    .then (rsp) ->

      async.eachSeries rsp.models, (ev, cb) ->
          ev.processAddress()
          setTimeout ->
            cb()
          , 1000

module.exports = [Event, Events]
