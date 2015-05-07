Shelf = require('./shelf')

Device = Shelf.Model.extend
  tableName: 'devices'
  idAttribute: 'device_id'
  hasTimestamps: true
  permittedAttributes: [
  	'device_id', 'user_id', 'type', 'token'
  ]

Devices = Shelf.Collection.extend
  model: Device

module.exports = [Device, Devices]