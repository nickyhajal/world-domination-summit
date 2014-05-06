Shelf = require('./shelf')
_ = require('underscore')
Q = require('q')

Capability = Shelf.Model.extend
  tableName: 'capabilities'
  idAttribute: 'capability_id'
  hasTimestamps: true
  permittedAttributes: [
  	'capability_id', 'capability', 'user_id'
  ]

Capabilities = Shelf.Collection.extend
  model: Capability

module.exports = [Capability, Capabilities]