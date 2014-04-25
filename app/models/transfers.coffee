Shelf = require('./shelf')
_ = require('underscore')
Q = require('q')

Transfer = Shelf.Model.extend
  tableName: 'transfers'
  idAttribute: 'transfer_id'
  permittedAttributes: [
  	'transfer_id', 'new_attendee', 'year', 'service_id', 'status', 'user_id'
  ]

Transfers = Shelf.Collection.extend
  model: Transfer

module.exports = [Transfer, Transfers]