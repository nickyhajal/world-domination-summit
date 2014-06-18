ap.User = window.XModel.extend
	defaults:
		model: 'Users'
		answers: []
		tickets: []
		feed_likes: []
		questions: ''
		interests: ''
		pic: '/images/default-avatar.png'
		distance: 0
	idAttribute: 'user_id'
	url: '/api/user'
	initialize: (opts = {})->
		if not @get('pic').length
			@set('pic', '/images/default-avatar.png')
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
Users = Backbone.Collection.Lunr.extend
	model: ap.User
	url: '/api/users/'
	lunroptions: 
    fields: [
        { name: "first_name", boost: 10 }
        { name: "last_name", boost: 5 }
        { name: "user_name"}
        { name: "email"}
    ]
  getByUsername: (username, cb) ->
  	results = @search(username)
  	for atn in results
  		if atn.get('user_name') is username
  			return atn
  	return false

ap.Users = new Users()
