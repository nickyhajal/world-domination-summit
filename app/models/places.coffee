Shelf = require('./shelf')

Place = Shelf.Model.extend
  tableName: 'places'
  idAttribute: 'place_id'
  permittedAttributes: [
    'place_id', 'place', 'lat', 'lon', 'place_type'
  ]

Places = Shelf.Collection.extend
  model: Place

module.exports = [Place, Places]
