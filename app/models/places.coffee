geocoder = require('geocoder')
Shelf = require('./shelf')
Place = Shelf.Model.extend
  tableName: 'places'
  idAttribute: 'place_id'
  permittedAttributes: [
    'place_id', 'place', 'lat', 'lon', 'place_type', 'pick', 'descr', 'address', 'name'
  ]
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
        Place.forge({place_id: @get('place_id')})
        .fetch()
        .then (place) ->
          location = data.results[0].geometry.location
          place.set
            lat: location.lat
            lon: location.lng
          place.save()
    , {key: process.env.GEOCODE_KEY}

Places = Shelf.Collection.extend
  model: Place


module.exports = [Place, Places]
