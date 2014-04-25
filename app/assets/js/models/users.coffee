ap.User = window.XModel.extend
	defaults:
		model: 'Users'
		answers: []
		tickets: []
		questions: ''
		interests: ''
		pic: ''
		distance: 0
	idAttribute: 'user_id'
	url: '/api/user'
	initialize: (opts = {})->
		@trackChangesSinceSave()

		# This should be done once on the server
	saved: (rsp)->

	toggleConnection: (to_id, cb = false) ->
		if @isConnected(to_id)
			ap.api 'delete user/connection', {to_id: to_id}, (rsp) =>
				@set
					connections: rsp.connections
					connected_ids: rsp.connected_ids
				if cb
					cb()
		else
			ap.api 'post user/connection', {to_id: to_id}, (rsp) =>
				@set
					connections: rsp.connections
					connected_ids: rsp.connected_ids
				if cb
					cb()

	isConnected: (user_id) ->
		if @get('connected_ids')?.length
			return @get('connected_ids').indexOf(user_id) > -1
		return false

	attendedBefore: ->
		for ticket in @get('tickets')
			if +ticket.year < +ap.year
				return true

# Create the Events collection and
# instantiate it
Users = XCollection.extend
	model: ap.User
	url: '/api/users/'
ap.Users = new Users()
