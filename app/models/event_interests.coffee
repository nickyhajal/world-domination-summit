Shelf = require('./shelf')

EventInterest = Shelf.Model.extend
  tableName: 'event_interests'
  idAttribute: 'event_interest_id'
  permittedAttributes: [
  	'interest_id', 'event_id'
  ]

EventInterests = Shelf.Collection.extend
  model: EventInterest

module.exports = [EventInterest, EventInterests]