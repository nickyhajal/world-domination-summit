geocoder = require('geocoder')

Shelf = require('./shelf')

Event = Shelf.Model.extend
  tableName: 'events'
  hasTimestamps: true
  idAttribute: 'event_id'
  permittedAttributes: [
    'event_id', 'year', 'ignored', 'type', 'title', 'descr', 'what', 'active',
    'note', 'place', 'who', 'utc', 'end', 'venue', 'address', 'note', 'max'
  ]
  defaults: {
  	descr: ''
  }

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

Events = Shelf.Collection.extend
  model: Event

module.exports = [Event, Events]