geocoder = require('geocoder')
Q = require('q')
moment = require('moment')

Shelf = require('./shelf')


Event = Shelf.Model.extend
  tableName: 'events'
  hasTimestamps: true
  idAttribute: 'event_id'
  permittedAttributes: [
    'event_id', 'year', 'ignored', 'type', 'for_type', 'title', 'descr', 'what', 'active',
    'note', 'place', 'who', 'utc', 'end', 'venue', 'address', 'note', 'max', 'bios',
    'free_max', 'format', 'outline', 'venue_note'
  ]
  defaults: {
  	descr: ''
  }

  updateRsvpCount: ->
    [EventRsvp, EventRsvps] = require('./event_rsvps')
    event_id = @get('event_id')
    tk "update rsvp count"
    tk event_id
    EventRsvps.forge()
    .query('where', 'event_id', event_id)
    .fetch()
    .then (rsp) ->
      if rsp.models?.length?
        tk rsp.models.length
        @set 'num_rsvps', rsp.models.length
      @save()
  initialize: ->
    this.on 'saving', this.saving, this
    this.on 'saved', this.saved, this

  saving: (e) ->
    @saveChanging()

  saved: (obj, rsp, opts) ->
    @id = rsp
    addressChanged = @lastDidChange ['address']
    if addressChanged and @get('address')?.length
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
        tk user.get('email')
        tk @list()
        user.addToList(@list())
        .then =>
          user.sendEmail 'academy-confirmation', 'You\'re registered for a WDS Academy!',
            what: @get('what')
            start: moment(@get('start')).format('MMMM Do [at] h:mma')
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

module.exports = [Event, Events]
