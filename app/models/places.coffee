Shelf = require('./shelf')

Place = Shelf.Model.extend
  tableName: 'places'
  idAttribute: 'place_id'
  permittedAttributes: [
    'place', 'lat', 'lon', 'place_type', 'pick', 'descr'
  ]

Places = Shelf.Collection.extend
  model: Place

module.exports = [Place, Places]
