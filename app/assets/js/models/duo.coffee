ap.Duo = XModel.extend
	defaults:
		model: 'Duos'
		last_update: 'Never'
		num_updates: 0
	url: '/api/duo'
	idAttribute: 'duoid'
	initialize: (opts = {})->
	saved: (rsp)->

# Create the Events collection and
# instantiate it
Duos = XCollection.extend
	model: ap.Duo
	url: '/api/duos/'
ap.Duos = new Duos()
