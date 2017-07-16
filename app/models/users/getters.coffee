# SS - User Model

Q = require('q')
async = require('async')
_s = require('underscore.string')
countries = require('country-data').countries
redis = require("redis")
rds = redis.createClient()

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
		Q.all([
			@getCurrentTickets()
			@getAnswers()
			@getInterests()
			@getConnections()
			@getFeedLikes()
			@getRsvps()
			@getFire()
			@getRegistration()
		])
		.then =>
			user = this
			if user.get('password')?.length
				user.set('has_pw', true)
			user.set('password', '')
			if user.get('user_name')?.length  is 40
				user.set('user_name', '')
			dfr.resolve(user)
		return dfr.promise

		# 	@getCurrentTickets()
		# .then (user) =>
		# 	tk 'Get Current'
		# 	last = (+(new Date()) / 1000)
		# 	tk (last - start)
		# 	@getAnswers()
		# 	.then (user) =>
		# 		tk 'Get Answers'
		# 		last1 = (+(new Date()) / 1000)
		# 		tk last1 - last
		# 		@getInterests()
		# 		.then (user) =>
		# 			tk 'Get Interests'
		# 			last2 = (+(new Date()) / 1000)
		# 			tk last2 - last1
		# 			@getConnections()
		# 			.then (user) =>
		# 				tk 'Get Connections'
		# 				last3 = (+(new Date()) / 1000)
		# 				tk last3 - last2
		# 				@getFeedLikes()
		# 				.then (user) =>
		# 					tk 'Get FeedLikes'
		# 					last4 = (+(new Date()) / 1000)
		# 					tk last4 - last3
		# 					@getRsvps()
		# 					.then (user) =>
		# 						tk 'Get Rsvp'
		# 						last5 = (+(new Date()) / 1000)
		# 						tk last5 - last4
		# 						@getFire()
		# 						.then (user) =>
		# 							tk 'Get Fire'
		# 							last6 = (+(new Date()) / 1000)
		# 							tk last6 - last5
		# 							@getRegistration()
		# 							.then (user) =>
		# 								tk 'Get Regi'
		# 								last7 = (+(new Date()) / 1000)
		# 								tk last7 - last6
		# 								if user.get('password')?.length
		# 									user.set('has_pw', true)
		# 								user.set('password', '')
		# 								if user.get('user_name')?.length  is 40
		# 									user.set('user_name', '')
		# 								dfr.resolve(user)

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
		id = 'answers_'+@get('user_id')
		rds.get id, (err, rsp) =>
			if rsp? and rsp and typeof JSON.parse(rsp) is 'object'
				@set('answers', rsp)
				dfr.resolve(this)
			else
				Answers.forge()
				.query('where', 'user_id', @get('user_id'))
				.fetch()
				.then (rsp) =>
					@set('answers', JSON.stringify(rsp.models))
					rds.set id, JSON.stringify(rsp), (err, rsp) ->
						rds.expire id, 300000, (err, rsp) ->
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
		id = 'interests_'+@get('user_id')
		rds.get id, (err, rsp) =>
			if rsp? and rsp and typeof JSON.parse(rsp) is 'object'
				@set('interests', JSON.parse(rsp))
				dfr.resolve(this)
			else
				UserInterests.forge()
				.query('where', 'user_id', @get('user_id'))
				.fetch()
				.then (rsp) =>
					interests = []
					for interest in rsp.models
						interests.push interest.get('interest_id')
					@set('interests', interests)
					rds.set id, JSON.stringify(interests), (err, rsp) ->
						rds.expire id, 300000, (err, rsp) ->
					dfr.resolve this
				, (err) ->
					console.error(err)
		return dfr.promise

	getConnections: ->
		dfr = Q.defer()
		id = 'connections_'+@get('user_id')
		rds.get id, (err, rsp) =>
			if rsp? and rsp and typeof JSON.parse(rsp) is 'object'
				@set('connected_ids', JSON.parse(rsp))
				dfr.resolve(this)
			else
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
					rds.set id, JSON.stringify(connected_ids), (err, rsp) ->
						rds.expire id, 300000, (err, rsp) ->
					dfr.resolve(this)
				, (err) ->
					console.error(err)
		return dfr.promise

	getFeedLikes: ->
		dfr = Q.defer()
		id = 'feed_likes_'+@get('user_id')
		rds.get id, (err, rsp) =>
			if rsp? and rsp and typeof JSON.parse(rsp) is 'object'
				@set('feed_likes', JSON.parse(rsp))
				dfr.resolve(this)
			else
				FeedLikes.forge()
				.query('where', 'user_id', @get('user_id'))
				.fetch()
				.then (likes) =>
					like_ids = []
					for like in likes.models
						like_ids.push like.get('feed_id')
					@set
						feed_likes: like_ids
					rds.set id, JSON.stringify(like_ids), (err, rsp) ->
						rds.expire id, 300000, (err, rsp) ->
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
		rds.expire id, 0
		id = 'current_tickets'+@get('user_id')
		rds.get id, (err, rsp) =>
			if rsp? and rsp and typeof JSON.parse(rsp) is 'object'
				@set('tickets', JSON.parse(rsp))
				dfr.resolve(this)
			else
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
					# qb.where('year', process.year)
						qb.where('year', '2018')
					qb.leftJoin('users as p', 'p.user_id', '=', 'tickets.user_id')
					qb.leftJoin('users as u', 'u.user_id', '=', 'tickets.user_id')
				.fetch({columns: columns})
				.then (rows) =>
					@set('tickets', rows.models)
					rds.set id, JSON.stringify(rows.models), (err, rsp) ->
						rds.expire id, 30, (err, rsp) ->
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
		id = 'rsvps_'+@get('user_id')
		rds.get id, (err, rsp) =>
			if rsp? and rsp and typeof JSON.parse(rsp) is 'object'
				@set('rsvps', JSON.parse(rsp))
				dfr.resolve(this)
			else
				EventRsvps.forge()
				.query('where', 'user_id', @get('user_id'))
				.fetch()
				.then (rsp) =>
					rsvps = []
					for rsvp in rsp.models
						rsvps.push rsvp.get('event_id')
					@set('rsvps', rsvps)
					rds.set id, JSON.stringify(rsvps), (err, rsp) ->
						rds.expire id, 30000, (err, rsp) ->
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
