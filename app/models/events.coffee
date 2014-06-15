Shelf = require('./shelf')

Event = Shelf.Model.extend
  tableName: 'events'
  hasTimestamps: true
  permittedAttributes: [
    'event_id', 'year', 'ignored', 'type', 'title', 'descr', 'what',
    'note', 'place', 'who', 'utc', 'end', 'venue', 'address', 'note', 'max'
  ]
	defaults:
		descr: ''
  idAttribute: 'event_id'

Events = Shelf.Collection.extend
  model: Event
  getAll: ->
  	Events.forge()
  	.fetch()

module.exports = [Event, Events]