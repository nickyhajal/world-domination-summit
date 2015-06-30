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
		capabilities: ''
		available_top_level_capabilities: ''
	idAttribute: 'user_id'
	url: '/api/user'
	initialize: (opts = {})->
		@set('pic', 'http://avatar.wds.fm/'+@get('user_id'))
		@trackChangesSinceSave()

		# This should be done once on the server
	saved: (rsp)->

	getPic: (size) ->
		return 'http://avatar.wds.fm/'+@get('user_id')+'?width='+size
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

	achieved: (task_id) ->
		if ap.achievements?.length
			for ach in ap.achievements
				if ach.task_id is task_id
					return ach
				this.ach = 'andrea'
		return false

	isConnected: (user_id) ->
		if @get('connected_ids')?.length
			return @get('connected_ids').indexOf(user_id) > -1
		return false

	attendedBefore: ->
		for ticket in @get('tickets')
			if +ticket.year < +ap.year
				return true

	isAttendingEvent: (event) ->
		if event.get('type') is 'program'
			return true
		else
			if ap.me.get('rsvps')?.length
				return ap.me.get('rsvps').indexOf(event.get('event_id')) > -1
			else
				return false

	getFriends: (cb) ->
		if @get('friends')?
			cb(@get('friends'))
		else
			ap.api 'get user/friends', {}, (rsp) =>
				@set('friends', rsp.friends)
				@set('friended_me', rsp.friended_me)
				@set('similar', rsp.similar)
				cb(rsp.friends)



	setRank: ->
		user_id = @get('user_id')
		count = 1
		for rank in ap.ranks
			if rank.user_id is user_id
				@set('rank', count)
				@set('points', rank.points)
				break;
			count += 1

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
ap.login(ap.me)
