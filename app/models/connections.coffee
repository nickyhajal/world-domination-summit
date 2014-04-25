Shelf = require('./shelf')
_ = require('underscore')
Q = require('q')

Connection = Shelf.Model.extend
  tableName: 'connections'
  idAttribute: 'connection_id'
  hasTimestamps: true
  permittedAttributes: [
  	'connection_id', 'user_id', 'year'
  ]

Connections = Shelf.Collection.extend
  model: Connection

module.exports = [Connection, Connections]