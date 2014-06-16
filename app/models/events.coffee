Shelf = require('./shelf')

Event = Shelf.Model.extend
  tableName: 'events'
  hasTimestamps: true
  idAttribute: 'event_id'
  permittedAttributes: [
    'event_id', 'year', 'ignored', 'type', 'title', 'descr', 'what',
    'note', 'place', 'who', 'utc', 'end', 'venue', 'address', 'note', 'max'
  ]
	defaults: {
		descr: ''
	}
	test: 'coffee-script treating this object weird'

Events = Shelf.Collection.extend
  model: Event
  getAll: ->
  	Events.forge()
  	.fetch()

module.exports = [Event, Events]