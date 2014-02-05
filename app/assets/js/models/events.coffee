ap.Event = XModel.extend
	defaults:
		model: 'Events'
	initialize: (opts = {})->
	saved: (rsp)->

# Create the Events collection and
# instantiate it
Events = XCollection.extend
	model: Event
	url: '/api/events/'
ap.Events = new Events()
