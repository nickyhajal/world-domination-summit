Shelf = require('./shelf')

EventRsvp = Shelf.Model.extend
  tableName: 'event_rsvps'
  idAttribute: 'rsvp_id'
  permittedAttributes: [
  	'rsvp_id', 'user_id', 'event_id'
  ]

EventRsvps = Shelf.Collection.extend
  model: EventRsvp

module.exports = [EventRsvp, EventRsvps]