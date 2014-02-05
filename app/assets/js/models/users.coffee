ap.User = XModel.extend
	defaults:
		model: 'Users'
	url: '/api/user'
	initialize: (opts = {})->
	saved: (rsp)->

# Create the Events collection and
# instantiate it
Users = XCollection.extend
	model: ap.User
	url: '/api/users/'
ap.Users = new Users()
