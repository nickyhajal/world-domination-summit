Shelf = require('./shelf')

Event = Shelf.Model.extend
  tableName: 'events'
  idAttribute: 'event_id'
  hasTimestamps: true
  permittedAttributes: [
    'event_id', 'year', 'ignored', 'type', 'title', 'descr', 'what',
    'note', 'place', 'who', 'utc', 'end', 'venue', 'address', 'note', 'max'
  ]

Events = Shelf.Collection.extend
  model: Event

module.exports = [Event, Events]