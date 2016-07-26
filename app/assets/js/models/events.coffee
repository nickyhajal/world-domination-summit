ap.Event = window.XModel.extend
	defaults:
		model: 'Event'
		classes: 'event-button'
	idAttribute: 'event_id'
	url: '/api/event'
	initialize: ->
		descr = _.autop(@get('descr'))
		@set
			descr: descr

Events = XCollection.extend
	model: ap.Event
	url: '/api/events/'
	comparator: (model) ->
		return model.get('start')
	getBySlug: (slug) ->
		for model in @models
			if _.slugify(model.get('what')) is slug || model.get('slug') is slug
				return model
		return false

ap.Events = new Events()

_.whenReady 'events', ->
	for event in ap.events
		event = new ap.Event(event)
		ap.Events.add event
