Shelf = require('./shelf')

EventHost = Shelf.Model.extend
  tableName: 'event_hosts'
  idAttribute: 'host_id'
  permittedAttributes: [
  	'event_id', 'user_id'
  ]

EventHosts = Shelf.Collection.extend
  model: EventHost

module.exports = [EventHost, EventHosts]