Shelf = require('./shelf')

PlaceType = Shelf.Model.extend
  tableName: 'place_types'
  idAttribute: 'placetypeid'
  permittedAttributes: [
    'type_name', 'ordr', 'stamp'
  ]

PlaceTypes = Shelf.Collection.extend
  model: PlaceType

module.exports = [PlaceType, PlaceTypes]
