Shelf = require('./shelf')

Checkin = Shelf.Model.extend
  tableName: 'checkins'
  hasTimestamps: true
  idAttribute: 'checkin_id'
  permittedAttributes: [
    'checkin_id', 'user_id', 'location_id', 'location_type'
  ]

Checkins = Shelf.Collection.extend
  model: Checkin

module.exports = [Checkin, Checkins]
