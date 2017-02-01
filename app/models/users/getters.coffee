# SS - User Model

Q = require('q')
async = require('async')
_s = require('underscore.string')
countries = require('country-data').countries

##

[Ticket, Tickets] = require '../tickets'
[Answer, Answers] = require '../answers'
[UserInterest, UserInterests] = require '../user_interests'
[Connection, Connections] = require '../connections'
[Capability, Capabilities] = require '../capabilities'
[FeedLike, FeedLikes] = require '../feed_likes'
[Feed, Feeds] = require '../feeds'
[EventRsvp, EventRsvps] = require '../event_rsvps'
[Achievement, Achievements] = require '../achievements'
[Registration, Registrations] = require '../registrations'

getters =
	getMe: ->
		dfr = Q.defer()
#    @raceCheck()
#    .then =>
		@getCurrentTickets()
		.then (user) =>
			@getAnswers()
			.then (user) =>
				@getInterests()
				.then (user) =>
					@getConnections()
					.then (user) =>
						@getFeedLikes()
						.then (user) =>
							@getRsvps()
							.then (user) =>
								@getFire()
								.then (user) =>
									@getRegistration()
									.then (user) =>
										user.set('password', '')
										if user.get('password')?.length
											user.set('has_pw', true)
										if user.get('user_name')?.length  is 40
											user.set('user_name', '')
										dfr.resolve(user)
		return dfr.promise

	getFire: ->
		dfr = Q.defer()
		existing = @get('firetoken')
		genFire = =>
			[User, Users] = require '../users'
			uid = @get('hash')
			params =
				first_name: @get('first_name')
				last_name: @get('last_name')
				email: @get('email')
				user_id: @get('user_id')
			process.fire.auth().createCustomToken(uid, params)
			.then (token) =>
				@set('firetoken', token)
				User.forge
					user_id: @get('user_id')
					firetoken: token
				.save()
				dfr.resolve(@)
			.catch (err) =>
				console.error(err)

		if existing? and existing.length
			genFire()
			# dfr.resolve(@)
		else
			genFire()
		return dfr.promise

	getFriends: (this_year = false, include_user = false) ->
		dfr = Q.defer()
		columns = null
		q = Connections.forge()
		.query('where', 'connections.user_id', @get('user_id'))
		if this_year
			q.query('where', 'created_at', '>', process.year+'-01-01 00:00:00')
		q.query('where', 'attending'+process.yr, '1')
		if include_user
			columns = {columns: ['users.user_id', 'first_name', 'last_name', 'user_name', 'pic']}
			q.query('join', 'users', 'connections.to_id', '=', 'users.user_id', 'inner')
		q.fetch(columns)
		.then (rsp) ->
			dfr.resolve(rsp.models)
		, (err) ->
			console.error(err)
		return dfr.promise

	getFriendedMe: (this_year = false, include_user = false) ->
		dfr = Q.defer()
		columns = null
		q = Connections.forge()
		.query('where', 'to_id', @get('user_id'))
		if this_year
			q.query('where', 'created_at', '>', process.year+'-01-01 00:00:00')

		# REMOVE AFTER EVENT TO SHOW ALL
		q.query('where', 'attending'+process.yr, '1')
		if include_user
			columns = {columns: ['users.user_id', 'first_name', 'last_name', 'user_name', 'pic']}
			q.query('join', 'users', 'connections.user_id', '=', 'users.user_id', 'inner')
		q.fetch(columns)
		.then (rsp) ->
			dfr.resolve(rsp.models)
		return dfr.promise

	getPic: ->
		pic = @get('pic')
		unless pic.indexOf('http') > -1
			pic = 'http://worlddominationsummit.com'+pic
		return pic

	getAchievedTasks: (with_submissions = false) ->
		dfr = Q.defer()
		achs = Achievements.forge()
		.query('where', 'race_achievements.user_id', @get('user_id'))
		.query('where', 'add_points', '<>', '-1')
		if with_submissions
			achs.query('join', 'race_submissions', 'race_achievements.ach_id', '=', 'race_submissions.ach_id', 'left')
		achs.fetch
			columns: ['task_id', 'custom_points', 'add_points']
		.then (achs) ->
			dfr.resolve(achs)
		return dfr.promise

	getUrl: (text = false, clss = false, id = false) ->
		user_name = @get('user_name')
		clss = if clss then ' class="'+clss+'"' else ''
		id = if id then ' id="'+id+'"' else ''
		if user_name.length isnt 32
			url = '/~'+user_name
		else
			url = '/slowpoke'
		href = 'http://'+process.dmn+url
		text = if text then text else href
		return '< href="'+href+'"'+clss+id+'>'+text+'</a>'

	# Distance from PDX
	getDistanceFromPDX: (units = 'mi', opts = {}) ->
		distance = @get('distance')
		if unit is 'km'
			out = (distance * 1.60934 ) + ' km'
		else
			out = distance + ' mi'
		return Math.ceil(out)

	getAnswers: ->
		dfr = Q.defer()
		Answers.forge()
		.query('where', 'user_id', @get('user_id'))
		.fetch()
		.then (rsp) =>
			@set('answers', JSON.stringify(rsp.models))
			dfr.resolve this
		, (err) ->
			console.error(err)
		return dfr.promise

	getCapabilities: ->
		dfr = Q.defer()
		Capabilities.forge()
		.query('where', 'user_id', @get('user_id'))
		.fetch()
		.then (rsp) =>
			if rsp.models.length
				@set('capabilities', rsp.models)
			dfr.resolve this
		, (err) ->
			console.error(err)
		return dfr.promise

	getInterests: ->
		dfr = Q.defer()
		UserInterests.forge()
		.query('where', 'user_id', @get('user_id'))
		.fetch()
		.then (rsp) =>
			interests = []
			for interest in rsp.models
				interests.push interest.get('interest_id')
			@set('interests', interests)
			dfr.resolve this
		, (err) ->
			console.error(err)
		return dfr.promise

	getConnections: ->
		dfr = Q.defer()
		Connections.forge()
		.query('where', 'user_id', @get('user_id'))
		.fetch()
		.then (connections) =>
			connected_ids = []
			for connection in connections.models
				connected_ids.push connection.get('to_id')
	#    connected_ids.push(176)
			connected_ids.push(179)
			@set
				connected_ids: connected_ids
			dfr.resolve(this)
		, (err) ->
			console.error(err)
		return dfr.promise

	getFeedLikes: ->
		dfr = Q.defer()
		FeedLikes.forge()
		.query('where', 'user_id', @get('user_id'))
		.fetch()
		.then (likes) =>
			like_ids = []
			for like in likes.models
				like_ids.push like.get('feed_id')
			@set
				feed_likes: like_ids
			dfr.resolve(this)
		, (err) ->
			console.error(err)
		return dfr.promise

	getAllTickets: ->
		dfr = Q.defer()
		Tickets.forge()
		.query('where', 'user_id', @get('user_id'))
		.fetch()
		.then (rows) =>
			@set('tickets', rows.models)
			dfr.resolve this
		, (err) ->
			console.error(err)
		return dfr.promise
	getCurrentTickets: ->
		dfr = Q.defer()
		columns = [
			'ticket_id', 'tickets.type', 'tickets.created_at', 'tickets.user_id', 'purchaser_id', 'status',
			'tickets.year',
			'p.first_name as purchaser_first_name',
			'p.last_name as purchaser_last_name',
			'p.email as purchaser_email',
			'u.first_name as attendee_first_name',
			'u.last_name as attendee_last_name',
			'u.email as attendee_email',
		]
		Tickets.forge()
		.query (qb) =>
			user = this;
			qb.where ->
				@where('tickets.user_id', user.get('user_id'))
				.orWhere('purchaser_id', user.get('user_id'))
			qb.where('year', process.year)
			qb.leftJoin('users as p', 'p.user_id', '=', 'tickets.user_id')
			qb.leftJoin('users as u', 'u.user_id', '=', 'tickets.user_id')
		.fetch({columns: columns})
		.then (rows) =>
			@set('tickets', rows.models)
			dfr.resolve this
		, (err) ->
			console.error(err)
		return dfr.promise

	getFollowingIds: ->

	getFullName: ->
		@get('first_name')+' '+@get('last_name')
		
	getRegistration: ->
		dfr = Q.defer()
		Registrations.forge().query (qb) =>
			qb.where('user_id', @get('user_id'))
			qb.where('event_id', '1')
			qb.where('year', process.yr)
		.fetch()
		.then (rsp) =>
			if rsp.models.length
				@set('registered', 1)
			else
				@set('registered', 0)
			dfr.resolve(@)
		dfr.promise

	getRsvps: ->
		dfr = Q.defer()
		EventRsvps.forge()
		.query('where', 'user_id', @get('user_id'))
		.fetch()
		.then (rsp) =>
			rsvps = []
			for rsvp in rsp.models
				rsvps.push rsvp.get('event_id')
			@set('rsvps', rsvps)
			dfr.resolve(@)
		return dfr.promise

	getLocationString: ->
		address = _s.titleize(@get('city'))+', '
		if (@get('country') is 'US' or @get('country') is 'GB') and @get('region')?
			address += @get('region')
		unless (@get('country') is 'US' or @get('country') is 'GB')
			if countries[@get('country')]?
				address += countries[@get('country')].name
		return address

module.exports = getters
