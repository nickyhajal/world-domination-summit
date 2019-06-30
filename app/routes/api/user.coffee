_ = require('underscore')
redis = require("redis")
async = require("async")
moment = require('moment');
rds = redis.createClient()
twitterAPI = require('node-twitter-api')
fs = require('fs')
crypto = require('crypto')
gm = require('gm')
Q = require('q')
mkdirp = require('mkdirp')
knex = require('knex')(process.db)
request = require('request')

routes = (app) ->

	twitter = new twitterAPI
		consumerKey: app.settings.twitter_consumer_key
		consumerSecret: app.settings.twitter_consumer_secret
		callback: 'https://api.worlddominationsummit.com/api/user/twitter/callback'

	[User, Users] = require('../../models/users')
	[EventRsvp, EventRsvps] = require('../../models/event_rsvps')
	[UserNote, UserNotes] = require('../../models/user_notes')
	[TwitterLogin, TwitterLogins] = require('../../models/twitter_logins')
	[Answer, Answers] = require('../../models/answers')
	[Ticket, Tickets] = require('../../models/tickets')
	[UserInterest, UserInterests] = require('../../models/user_interests')
	[Interest, Interests] = require('../../models/interests')
	[CredentialChange, CredentialChanges] = require('../../models/credential_changes')
	[Connection, Connections] = require('../../models/connections')
	[Registration, Registrations] = require('../../models/registrations')
	[Notification, Notifications] = require('../../models/notifications')
	[Device, Devices] = require('../../models/devices')
	[RaceSubmission, RaceSubmissions] = require('../../models/race_submissions')
	[RacePrize, RacePrizes] = require('../../models/RacePrizes')
	[RaceUserPrize, RaceUserPrizes] = require('../../models/RaceUserPrizes')
	[Checkin, Checkins] = require('../../models/checkins')
	[Card, Cards] = require('../../models/cards')

	user =
		# Get logged in user
		validate: (req, res, next) ->
			if req.me
				res.r.valid = 1
			next()

		twitterCheck: (req, res, next) ->
			if req.me
				res.r.twitter = req.me.get('twitter')
				next()

		me: (req, res, next) ->
			if req.me
				Users.forge().getUser(req.me.get('user_id'))
				.then (user) ->
					user.getAllTickets()
					.then (user) ->
						user.getAnswers()
						.then (user) ->
							user.getInterests()
							.then (user) ->
								user.getConnections()
								.then (user) ->
									if user.get('username')?.length is 40
										user.set('user_name', '')
									res.r.me = user
									next()
			else
				res.r.me = false
				next()
		get_notification_tokens: (req, res, next) ->
			if req.query.user_id?
				Devices.forge().query (qb) ->
					qb.where('user_id', req.query.user_id)
					qb.where('active', '1')
				.fetch()
				.then (rsp) ->
					res.r.tokens = rsp.models
					next()

		claim_ticket: (req, res, next) ->
			if req.me
				Tickets.forge().query (qb) ->
					qb.where('purchaser_id', req.me.get('user_id'))
					qb.where('status', 'unclaimed')
				.fetch()
				.then (rsp) ->
					ticket = rsp.models[0]
					req.me.connectTicket(ticket)
					.then ->
						rds.expire('current_tickets_'+req.me.get('user_id'), 0)
						req.me.getCurrentTickets()
						.then (user) ->
							res.r.tickets = user.get('tickets')
							next()
			else
				res.status(400)
				res.r.msg = 'No user'
				next()
		give_ticket: (req, res, next) ->
			giveTicket = (atn, tkt, returning) ->
					atn.assignTicket(tkt, returning, req.me)
					.then ->
						rds.expire('current_tickets_'+req.me.get('user_id'), 0)
						req.me.getCurrentTickets()
						.then (user) ->
							res.r.tickets = user.get('tickets')
							next()
			if req.me
				if req.query.first_name? and req.query.last_name? and req.query.email?
					Tickets.forge().query (qb) ->
						qb.where('purchaser_id', req.me.get('user_id'))
						qb.where('status', 'unclaimed')
						qb.where('year', process.tkyear)
					.fetch()
					.then (rsp) ->
						ticket = rsp.models[0]
						User.forge
							email: req.query.email
						.fetch()
						.then (existing) ->
							if existing
								Ticket.forge
									user_id: existing.get('user_id')
									year: process.tkyear
									status: 'active'
								.fetch()
								.then (existing_tkt) ->
									if existing_tkt
										res.errors.push('Looks like '+existing.get('first_name')+' already has a ticket to WDS '+process.tkyear+'. You could try someone else or contact concierge@wds.fm for help. ')
										next()
									else
										giveTicket(existing, ticket, true)
							else
								User.forge
									first_name: req.query.first_name
									last_name: req.query.last_name
									email: req.query.email
								.save()
								.then (user) ->
									giveTicket(user, ticket, false)
				else
					res.r.msg = "Hm, looks like you're missing some data."
			else
				res.status(400)
				res.r.msg = 'No user'
				next()

		card: (req, res, next) ->
			if req.me? and req.me
				Cards.forge()
				.query (qb) ->
					qb.where('user_id', req.me.get('user_id'))
					qb.orderBy('card_id', 'desc')
				.fetch()
				.then (rsp) ->
					if rsp.models.length
						res.r.card = _.pick rsp.models[0].attributes, Card::permittedAttributes
					else
						res.r.card = false
					next()
			else
				res.r.card = false
				next()
		updCard: (req, res, next) ->
			if req.me? and req.me
				req.me.getCard(req.query.card_id)
				.then (card) ->
					tk card
					if card.status? and card.status is 'declined'
						res.r.status = 'fail'
						res.r.msg = card.err
					else
						res.r.status = 'updated'
					next();
				.catch ->
					res.r.status = 'fail'
					next()
			else 
				res.r.status = 'fail'
				next()


		# Get a user
		username_check: (req, res, next) ->
			where = {}
			if req.query.user_name?
				User.forge
					user_name: req.query.user_name
				.fetch()
				.then (user) ->
					exists = (!_.isNull(user))
					res.r.exists = if exists then true else false
					next()
			else
				next()
		getsp: (req, res, next) ->
			if req.query.user_id
				User.forge({
					user_id: req.query.user_id
				})
				.fetch()
				.then (user) ->
					if user
						res.r.glb = user.get('glb')
						res.r.gsp = user.get('gsp')
						res.r.nsp = user.get('nsp')
						res.r.bentos = user.get('bentos')
						next()
					else
						next()
			else
				next()
		get: (req, res, next) ->
			where = {}
			if req.query.user_name? || req.query.user_id?
				if req.query.user_name?
					where.user_name = req.query.user_name
				else if req.query.user_id?
					where.user_id = req.query.user_id
				User.forge(where)
				.fetch()
				.then (user) ->
					if user
						user.getReadableCapabilities()
						.then (user) ->
							user.getAnswers()
							.then (user) ->
								user.getInterests()
								.then (user) ->
									user.getAllTickets()
									.then (user) ->
										user.set('password', null)
										unless req.query.inc_hash?
											block = []
											user.set('hash', null)
											if req.me and (req.me.get('user_id') != user.get('user_id'))
												block = ['address', 'phone', 'pub_loc', 'pub_att',
													'intro', 'intro14', 'last_shake', 'accommodation',
													'notification_interval', 'tour', 'academy'
												]
											for b in block
												delete user.attributes[b]
										res.r.user = user
										next()
					else
						res.r.not_existing = true
						next()
				, (err) ->
					res.status(400)
					errors.push(err.message)
					next()
			else
				res.status(400)
				res.r.msg = 'No user'
				next()

		get_events: (req, res, next) ->
			columns = { columns: [ 'events.event_id', 'what', 'type', 'start', 'place', 'address' ]}
			EventRsvps.forge().query (qb) ->
				qb.where('user_id', req.query.user_id)
				qb.where('year', process.yr)
				qb.leftJoin('events', 'event_rsvps.event_id', 'events.event_id')
			.fetch(columns)
			.then (rsp) ->
				res.r.events = rsp.models
				next()

		search: (req, res, next) ->
			_Users = Users.forge()
			all = {}
			years = []
			types = []
			if req.query.types?.length
				types = req.query.types?.split(',')
			if req.query.years?.length
				years = req.query.years?.split(',')
			if req.query.user_token
				years = [process.yr]
			doQuery = (col, q = false) ->
				dfr = Q.defer()
				_Users.query (qb) ->
					where = ''
					params = []
					if q
						where += col+' LIKE ?'
						params.push q
					if req.query.types?.length
						if q
							where += ' AND '
						where += 'ticket_type IN ('
						c = false
						for t in types
							where += ', ' if c
							where += '?'
							params.push t
							c = true
						where += ')'
					if years?.length
						# if q and req.query.types?.length
						where += ' AND ('
						c = false
						for y in years
							where += ' OR ' if c
							where += ' attending'+y+ '= ?'
							params.push '1'
							c = true
						where += ')'
					qb.whereRaw(where, params)
					qb.limit(100)
				.fetch()
				.then (rsp) ->
					dfr.resolve(rsp)
				, (err) ->
					console.error(err)
				return dfr.promise

			terms = if req.query.search? then req.query.search.split(' ') else []
			async.each terms, (term, cb) ->
				doQuery('first_name', term+'%')
				.then (byF) ->
					for f in byF.models
						id = f.get('user_id')
						all[id] = f.attributes unless all[id]
						if all[id].score? then all[id].score += 2 else (all[id].score = 4)
					doQuery('last_name', term+'%')
					.then (byL) ->
						# doQuery('email', '%'+term+'%')
						# .then (byE) ->
						# 	tk 'all here'
						for l in byL.models
							id = l.get('user_id')
							all[id] = l.attributes unless all[id]
							if all[id].score? then all[id].score += 5 else (all[id].score = 1)
						# for e in byE.models
						# 	id = e.get('user_id')
						# 	all[id] = e.attributes unless all[id]
						# 	if all[id].score? then all[id].score += 1 else (all[id].score = 1)
						cb()
			, (err) ->
				sortable = []
				for id,user of all
					sortable.push user
				sortable.sort (a, b) ->
					return a.score - b.score
				sortable.reverse()
				res.r.users = sortable
				next()

		post_story: (req, res, next) ->
			if req.me? and req.me and req.query.story? and req.query.phone?
				name = req.me.get('first_name')+' '+req.me.get('last_name')
				knex('stories')
				.insert({
					user_id: req.me.get('user_id')
					phone: req.query.phone
					story: req.query.story
				})
				.then (rsp) =>
					User.forge
						user_id: '216'
					.fetch()
					.then (jolie) ->
						params =
							story_name: name
							story_email: req.me.get('email')
							phone: req.query.phone
							story: req.query.story
						jolie.sendEmail('atnstory', 'New Attendee Story Submitted!', params)
						User.forge
							user_id: '176'
						.fetch()
						.then (nicky) ->
							params =
								story_name: name
								story_email: req.me.get('email')
								phone: req.query.phone
								story: req.query.story
							nicky.sendEmail('atnstory', 'New Attendee Story Submitted!', params)
				, (err) =>
					console.error(err)
			next()

		prize_notification: (req, res, next) ->
			tk 'tk: '+req.query
			if req.query.user_id and req.query.submission_id
				Notification.forge
					type: 'prize'
					user_id: req.query.user_id
					channel_type: '0'
					channel_id: '0'
					content: '{"user_id":'+req.query.user_id+'}'
					link: ''
				.save()
				.then ->
					RaceUserPrize.forge
						submission_id: req.query.submission_id
						user_id: req.query.user_id
					.fetch()
					.then (p) ->
						p.set('notified', 1).save()
					next()

		get_notifications: (req, res, next) ->
			if req.me? and req.me
				Notifications.forge()
				.query (qb) ->
					qb.where('user_id', req.me.get('user_id'))
					qb.orderBy('created_at', 'DESC')
					qb.limit(25)
				.fetch()
				.then (rsp) ->
					notns = []
					async.eachSeries rsp.models, (notn, cb) ->
						Notifications::notificationText(notn, false, true)
						.then (ntrsp) ->
							if ntrsp
								notn.set('text', ntrsp[0])
								notn.set('from', _.pick(ntrsp[1].attributes, ['user_id', 'first_name', 'last_name']))
								notns.push notn
							cb()
					, ->
						res.r.notifications = (_.sortBy notns, 'notification_id')
						next()
			else
				next()

		upd_notifications: (req, res, next) ->
			if req.me? and req.me and req.query.notifications
				async.each req.query.notifications, (notn, cb) ->
					Notification.forge
						notification_id: notn.notification_id
					.fetch()
					.then (row) ->
						if row? and row and row.get('user_id') == req.me.get('user_id')
							for state in ['read', 'clicked', 'emailed']
								row.set(state, notn[state]) if notn[state]?
							row.save()
							cb()
						else
							cb()
					notn
				, ->
					next()
			else
				next()

		mark_read_notifications: (req, res, next) ->
			if req.me? and req.me
				knex('notifications')
				.where('user_id', req.me.get('user_id'))
				.update
					read: '1'
				.then (rsp) ->
					tk rsp
				, (err) ->
					console.error(err)
			next()

		logout: (req, res, next) ->
			if req.session.ident?
				req.session.destroy()
			next()

		# Authenticate a user
		login: (req, res, next) ->
			finish = (user = false) ->
				if user
					user.login req
					user.getMe()
					.then (user) ->
						res.r.loggedin = true
						res.r.me = user
						if req.query.request_user_token? and req.query.request_user_token
							user.requestUserToken(req.headers['x-real-ip'])
							.then (token) ->
								res.r.user_token = token
								next()
						else
							next()
				else
					res.r.loggedin = false
					next()

			if req.query.hash?
				User.forge(hash: req.query.hash)
				.fetch()
				.then (user) ->
					finish(user)
			else
				query = {user_name: req.query.username}
				if req.query.username.indexOf('@') > -1
					query = {email: req.query.username}
				User.forge(query)
				.fetch()
				.then (user) ->
					if user
						user.authenticate(req.query.password, req)
						.then (authd)->
							if authd
								finish(user)
							else
								finish()
					else
						finish()

		create: (req, res, next) ->
			post = _.pick(req.query, User.prototype.permittedAttributes)
			giveTicket = (u) ->
				hash = require('crypto').createHash('md5').update(''+(+(new Date()))).digest("hex").substr(0,5)
				u.registerTicket('ADDED_BY_'+req.me.get('user_id')+'_'+hash)
			User.forge
				email: post.email
			.fetch()
			.then (existing) ->
				if existing
					if req.query.t?
						giveTicket(existing)
						next()
					else if req.query.ignore_existing?
						if req.query.login
							existing.login(req)
							res.r.me = _.pick(existing.attributes, User::limitedAttributes)
						next()
					else
						res.r.existing = true
						next()
				else
					user = User.forge(post)
					.save()
					.then (new_user) ->
						if req.query.t?
							giveTicket(new_user)
						if req.query.login
							new_user.login(req)
							res.r.me = _.pick(new_user.attributes, User::limitedAttributes)
						next()

		ticket: (req, res, next) ->
			res.r.msg = 'ieanrst'
			if req.query.user_id? and req.me?
				User.forge({user_id: req.query.user_id})
				.fetch()
				.then (user) ->
					if (user)
						hash = require('crypto').createHash('md5').update(''+(+(new Date()))).digest("hex").substr(0,5)
						user.registerTicket('ADDED_BY_176_'+hash)
						user.set('attending'+process.tkyr, '1').save()
						res.r.msg = 'Registered'
					next()

		give_tickets: (req, res, next) ->
			if req.query.attendees?
				atns = []
				for atn in req.query.attendees
					atns.push atn if typeof atn is 'object'
				giveTicket = (user, ticket_id, cb) ->
					Ticket.forge
						ticket_id: ticket_id
					.fetch()
					.then (ticket) ->
						if ticket.get('user_id') is req.me.get('user_id') and ticket.get('status') is 'purchased'
							user.connectTicket(ticket)
							.then ->
								cb()
						else
							cb()
				async.eachSeries atns, (val, cb) ->
					userPost = _.pick val, User::permittedAttributes
					User.forge
						email: val.email
					.fetch()
					.then (existing) ->
						if existing?
							giveTicket(existing, val.ticket_id, cb)
						else
							User.forge(userPost)
							.save()
							.then (user) ->
								giveTicket(user, val.ticket_id, cb)
				, ->
					next()
			else
				res.status(410)
				next()

		update: (req, res, next) ->
			post = _.pick(req.query, User.prototype.permittedAttributes)
			if req.me
				if post.calling_code?
					bits = post.calling_code.split('-');
					post.calling_code = bits[0]

				if post.user_name? and !post.user_name.length
					post = _.omit post, ['user_name']

				# Todo: better job ensuring user_name
				# if post.user_name?
				# 	post = _.omit(post, ['user_name'])
				if +req.me.get('user_id') is +post.user_id or req.me.hasCapability('manifest')
					User.forge({user_id: post.user_id})
					.fetch()
					.then (user) ->
						user.set(post)
						user.set('last_broadcast', new Date(user.get('last_broadcast')))
						user.save()
						.then (user) ->
							if req.query.answers?
								Answers
								.forge()
								.updateAnswers(post.user_id, JSON.parse(req.query.answers))
								setTimeout ->
									rds.expire('answers_'+post.user_id, 0)
								, 2000

							if req.query.new_password? and req.query.new_password.length
								User.forge({user_id: post.user_id}).updatePassword(req.query.new_password)

							if req.query.capabilities_update
								user.getCapabilities
								if req.query.capabilities
									user.setCapabilities req.query.capabilities.split(",")
								else
									user.setCapabilities {}

							if user.addressChanged
								User.forge({user_id: post.user_id})
								.fetch()
								.then (addr_user) ->
									addr_user.processAddress (user) ->
										res.r.user = _.pick user.attributes, User.prototype.permittedAttributes
										next()
							else
								next()
						, (err) ->
							res.r.err = err.clientError
							msg = err.message.split(',')
							res.r.err_msg = msg[0]
							console.error(err)
							next()
			else
				res.status(401)
				next()

		addToList: (req, res, next) ->
			if req.query.email? and req.query.name?
				bits = req.query.name.split(' ');
				user = User.forge
					email: req.query.email
					first_name: bits[0]
					last_name: bits[1]
				custom = '{}'
				custom = req.query.custom if req.query.custom?
				user.addToList(req.query.list, JSON.parse(custom));
				next()
			else
				next()

		reset: (req, res, next) ->
			if req.query.username?
				query = {user_name: req.query.username}
				if req.query.username.indexOf('@') > -1
					query = {email: req.query.username}
				User.forge(query)
				.fetch()
				.then (user) ->
					if user
						domain = if req.query.domain? then req.query.domain else false
						path = if req.query.path? then req.query.path else false
						CredentialChange
						.forge()
						.create(user, req.headers['x-real-ip'], domain, path)
						.then (rsp) ->
							next()
					else
						res.r.not_existing = true
						next()
			else if req.query.hash? && req.query.password?
				CredentialChange.forge({hash: req.query.hash})
				.fetch()
				.then (change) ->
					if change.isValid()
						User.forge({user_id: change.get('user_id')})
						.fetch()
						.then (user) ->
							user.updatePassword(req.query.password)
							.then ->
								change.use()
								next()
					else
						res.r.msg = 'That reset request isn\'t valid'
						res.status(401)
						next()

		add_interest: (req, res, next) ->
			if req.me
				user_id = req.me.get('user_id')
				UserInterest.forge
					interest_id: req.query.interest_id
					user_id: user_id
				.save()
				.then (row) ->
					UserInterests.forge().countInterests(req.query.interest_id)
					.then (rsp) ->
						rds.expire('interests_'+user_id, 0)
						res.r.members = rsp[0].get('memberCount')
						res.r.msg = "Interest added!"
						next()
			else
				next()

		del_interest: (req, res, next) ->
			if req.me
				user_id = req.me.get('user_id')
				UserInterest.forge
					interest_id: req.query.interest_id
					user_id: user_id
				.fetch()
				.then (row) ->
					if row
						row.destroy()
						UserInterests.forge().countInterests(req.query.interest_id)
						.then (rsp) ->
							rds.expire('interests_'+user_id, 0)
							res.r.members = rsp[0].get('memberCount')
							res.r.msg = 'Interest deleted.'
							next()
					else
						res.r.msg = 'That interest already wasn\'t there'
						res.status(410)
						next()

		twitter_connect: (req, res, next) ->
			tk 'con'
			twitter.getRequestToken (err, reqToken, reqTokenSec, twitter_rsp) ->
				tk err
				if err
					res.r.msg = err
					res.status = '400'
					next();
				else
					req.session.twitter_connect = [reqToken, reqTokenSec]
					url = 'https://twitter.com/oauth/authenticate?oauth_token='+reqToken+'&oauth_callback=https://'+encodeURI('api.worlddominationsummit.com/user/twitter/callback')
					res.redirect(url)

		twitter_callback: (req, res, next) ->
			if req.me and req.session.twitter_connect?
				twitter_connect = req.session.twitter_connect
				twitter.getAccessToken twitter_connect[0], twitter_connect[1], req.query.oauth_verifier, (err, accessToken, accessTokenSecret, results) ->
					TwitterLogin.forge
						user_id: req.me.get('user_id')
					.fetch()
					.then (login) ->
						# We do this to get the full twitter profile
						twitter.verifyCredentials accessToken, accessTokenSecret, (err, rsp) ->
							if not err
								if not login
									login = TwitterLogin.forge({user_id: req.me.get('user_id')})
								login.set
									token: accessToken
									secret: accessTokenSecret
								login.save()
								.then (login) ->
									request 'https://avatar.wds.fm/flush/'+req.me.get('user_id'), (error, response, body) ->
									req.me.set
										twitter: rsp.screen_name
										pic: rsp.profile_image_url_https
									req.me.save()
									.then ->
										res.send('');
								, (err) ->
									console.error(err)
							else
								req.session.twitter_err = 1
								res.send('<script type="text/javascript>window.close();</script>');

		del_twitter: (req, res, next) ->
			if req.me
				req.me.set('twitter', '')
				.save()
				.then ->
					login = TwitterLogin.forge({user_id: req.me.get('user_id')})
					.fetch()
					.then (login) ->
						if login
							login.destroy()
						res.r.msg = 'Disconnected from Twitter'
						next()
			else
				res.status(401)
				next()

		send_tweet: (req, res, next) ->
			if req.me
				req.me.sendTweet(req.query.tweet)
				.then ->
					res.r.msg = 'Tweet sent!'
					next()
			else
				res.status(401)
				next()

		add_connection: (req, res, next) ->
			if req.me
				user_id = req.me.get('user_id')
				to_id = req.query.to_id
				Connection.forge({user_id: user_id, to_id: to_id})
				.fetch()
				.then (existing) ->
					if existing?
						next()
					else
						Connection.forge({user_id: user_id, to_id: to_id, year: process.year})
						.save()
						.then (connection) ->
							rds.expire('connections_'+user_id, 0)
							req.me.getConnections()
							.then (user) ->
								#res.r.connections = user.get('connections')
								res.r.connected_ids = user.get('connected_ids')
								if req.me.get('user_id') isnt to_id
									Notification.forge
										type: 'connected'
										channel_type: 'connection'
										channel_id: '0'
										user_id: to_id
										content: JSON.stringify
											from_id: req.me.get('user_id')
										link: '~'+req.me.get('user_name')
									.save()
								next()
				, (err) ->
					console.error(err)
			else
				res.status(401)
				next()

		del_connection: (req, res, next) ->
			if req.me
				user_id = req.me.get('user_id')
				to_id = req.query.to_id
				Connection.forge({user_id: user_id, to_id: to_id})
				.fetch()
				.then (connection) ->
					connection.destroy()
					.then ->
						rds.expire('connections_'+user_id, 0)
						req.me.getConnections()
						.then (user) ->
						#	res.r.connections = user.get('connections')
							res.r.connected_ids = user.get('connected_ids')
							next()
			else
				res.status(401)

		register_extra: (req, res, next) ->
			cols = ['glb', 'gsp', 'bentos']
			if req.query.col and cols.indexOf(req.query.col) > -1 && req.query.user_id && req.query.val
				col = req.query.col
				User.forge({user_id: req.query.user_id})
				.fetch()
				.then (user) ->
					if (user)
						user.set(col, req.query.val)
						user.save().then -> 
							User.forge({user_id: req.query.user_id})
							.fetch()
							.then (rs) ->
								res.r[col] = rs.get(col)
								next()
					else
						next()
			else
				next()

		show_race_instructions: (req, res, next) ->
			console.log('mark', req.me.get('user_id'))
			if req.me
				console.log('MARK')
				req.me.markAchieved('race-guide')

			next()


		registrations: (req, res, next) ->
			regs = req.query.regs ? []
			successes = []
			async.each regs, (reg, cb) ->
				Registration.forge
					user_id: reg.user_id
					year: process.yr
					event_id: reg.event_id
				.fetch()
				.then (existing) ->
					if existing and reg.action is 'unregister'
						existing.destroy().then ->
							res.r.msg = 'Unregistered!'
							successes.push(reg)
							cb()
					else if reg.action is 'register' and not existing
						Registration.forge
							user_id: reg.user_id
							year: process.yr
							event_id: reg.event_id
						.save()
						.then ->
							successes.push(reg)
							res.r.msg = 'Registered!'
							cb()
						, (err) ->
							console.error(err)
					else
						successes.push(reg)
						cb()
			, ->
				_Rs = Registrations.forge()
				_Rs
				.query('where', 'created_at', '>', moment(new Date(new Date().getTime() - 3600000)).format('YYYY-MM-DD HH:mm:ss'))
				.query('where', 'year', '=', process.yr)
				.fetch()
				.then (past_hour) ->
					res.r.reg_past_hour = past_hour.models.length
					_Rs
					.query('where', 'year', '=', process.yr)
					.fetch()
					.then (all_time) ->
						res.r.reg_all = all_time.models.length
						res.r.successes = successes
						regs = {}
						for reg in all_time.models
							regs[reg.get('user_id')+'_'+reg.get('event_id')] = '1'
						res.r.registrations = regs
						next()
				, (err) ->
					console.error(err)

		race_check: (req, res, next) ->
			if req.me
				req.me.raceCheck()
				.then (points) ->
					req.me.getAchievedTasks()
					.then (achievements) ->
						res.r.achievements = achievements
						res.r.points = points
						next()
			else if req.query.user_id
				User.forge
					user_id: req.query.user_id
				.fetch()
				.then (user) ->
					user.raceCheck()
					.then (points) ->
						user.getAchievedTasks()
						.then (achievements) ->
							res.r.achievements = achievements
							res.r.points = points
							next()

		add_unote: (req, res, next) ->
			if req.me
				post = _.pick req.query, UserNote::permittedAttributes
				post.user_id = req.me.get('user_id')
				post.year = process.year
				UserNote.forge(post)
				.save()
				.then ->
					next()
				, (err) ->
					console.error(err)
			else
				res.status(401)
				next()

		get_unotes: (req, res, next) ->
			if req.me
				select = UserNotes.forge()
				if req.query.about_id?
					select.query('where', 'about_id', req.query.about_id)
				select.query('where', 'user_id', req.me.get('user_id'))
				select.query('orderBy', 'unote_id', 'DESC')
				select.fetch()
				.then (rsp) ->
					res.r.notes = rsp.models
					next()
			else
				res.status(401)
				next()

		achieved: (req, res, next) ->
			if req.me
				req.me.markAchieved(req.query.slug)
				.then ->
					next()

		get_friends: (req, res, next) ->
			if req.me
				req.me.getFriends()
				.then (friend_rsp) ->
					req.me.getFriendedMe()
					.then (friended_me_rsp) ->
						req.me.similar_attendees()
						.then (similar_rsp) ->
							friended_me = []
							friends = []
							similar = []
							for fr_me in friended_me_rsp
								friended_me.push fr_me.get('user_id')
							for friend in friend_rsp
								friends.push friend.get('to_id')
							for attendee in similar_rsp
						  	similar.push attendee
							res.r.friends = friends
							res.r.friended_me = friended_me
							res.r.similar = similar
							next()
			else
				next()

		get_friends_special: (req, res, next) ->
			if req.query.type? && req.me
				inc_user = req.query.include_user?
				if req.query.type == 'friends'
					req.me.getFriends(false, inc_user)
					.then (rsp) ->
						res.r.user = rsp
						next()
				else if req.query.type == 'friended me'
					req.me.getFriendedMe(false, inc_user)
					.then (rsp) ->
						res.r.user = rsp
						next()
				else if req.query.type == 'match me'
					req.me.similar_attendees(inc_user, 20)
					.then (rsp) ->
						res.r.user = rsp
						next()
				else
					next()
			else
				next()

		get_prizes: (req, res, next) ->
			if req.me
				RaceUserPrizes.forge().query('where', 'user_id', req.me.get('user_id'))
				.fetch()
				.then (user_prizes) ->
					res.r.user_prizes = user_prizes
					RacePrizes.forge()
					.fetch
						columns: ['prize_id', 'description', 'name']
					.then (prizes) ->
						res.r.prizes = prizes
						next()
			else
				next()
		claim_prize: (req, res, next) ->
			if req.me and req.query.prize_id
				RaceUserPrize.forge
					user_id: req.me.get('user_id')
					race_user_prize_id: req.query.prize_id
				.fetch()
				.then (prize) ->
					if prize
						prize.set('redeemed', '1')
						.save()
						.then ->
							res.r.redeemed = true
							next()
					else
						tk 'Tried to claim a prize that doesn\'t exist for that user'
						tk 'user_id: '+req.me.get('user_id')+', prize_id: '+req.query.prize_id
						res.r.redeemed = false
						next()
			else
				next()
		task: (req, res, next) ->
			task_slug = req.query.task_slug
			RaceSubmissions.forge()
			.query('where', 'slug', task_slug)
			.query('where', 'rating', '>', 1)
			.fetch()
			.then (examples) ->
				res.r.examples = examples.models
				if req.me
					RaceSubmissions.forge()
					.query('where', 'slug', task_slug)
					.query('where', 'user_id', req.me.get('user_id'))
					.fetch()
					.then (mine) ->
						res.r.mine = mine.models
						next()
				else
					next()
			, (err) ->
				console.error(err)

		race_sync: (req, res, next) ->
			if (req.query.user_id)
				User.forge({user_id: req.query.user_id})
				.fetch()
				.then (user) ->
					user.processPoints()
					.then (points) ->
						user.set('points', points.all)
						.save()
						.then ->
							user.syncAchievements(points).then ->
								next()
			else
				next()
		race_submission: (req, res, next) ->
			syncSubmission = (id, attempt = 0) ->
				if attempt < 3
					call =
						url: 'https://us-central1-worlddominationsummit.cloudfunctions.net/notifySubmission?submission_id='+id
						method: 'get'
					request call, (err, rsp) ->
						tk 'sub sync rsp for '+id+':'
						if (err || rsp.statusCode != 200)
							setTimeout ->
								syncSubmission(id, attempt+1)
							, 2000
			if req.me and req.query.slug?.length
				slug = req.query.slug
				req.me.markAchieved(slug)
				.then (ach_rsp) ->
					RaceSubmission.forge
						user_id: req.me.get('user_id')
						ach_id: ach_rsp.ach_id
						slug: slug
						hash: req.query.media
					.save()
					.then (sub) ->
						req.me.getAchievedTasks()
						.then (achievements) ->
							short_achs = []
							for ach in achievements.models
								short_achs.push
									t: ach.get('task_id')
									c: ach.get('custom_points')
									a: ach.get('add_points')

							rsp = JSON.stringify
								points: ach_rsp.points
								new_points: ach_rsp.points - req.query.cur_points
								task_id: req.query.task_id
								achievements: short_achs

							# Expire rank cache so next rank request
							# is recalculated
							rds.expire 'ranks', 0
							
							res.r ={
								points: ach_rsp.points
								new_points: ach_rsp.points - req.query.cur_ponts
								task_id: req.query.task_id
								achievements: short_achs
							}
							if sub.get("hash") != "submitted" and +sub.get("ach_id") != 0
								syncSubmission(sub.get('submission_id'), 0)
							next()
					, (err) ->
						console.error(err)
						next()
			else
				next()

		add_checkin: (req, res, next) ->
			if req.me and req.query.location_id and req.query.location_type
				if req.query.location_id == '64' || req.query.location_id == '15'
					req.query.location_id = '2'
				Checkin.forge
					user_id: req.me.get('user_id')
					location_id: req.query.location_id
					location_type: req.query.location_type
				.save()
				.then ->
					req.me.markAchieved('check-in')
					next()
				, (err) ->
				 	console.error(err)
			else
				next()

		# get_notifications: (req, res, next) ->
		# 	if req.me
		# 		Notifications.forge()
		# 		.query("where", "user_id", "=", req.me.get('user_id'))
		# 		.fetch()
		# 		.then (notifications) ->
		# 			res.r.notifications = notifications.models
		# 			next()
		# 		, (err) ->
		# 			console.error err
		# 	else
		# 		next()

		get_unread_notifications: (req, res, next) ->
			if req.me
				Notifications.forge()
				.query("where", "user_id", "=", req.me.get('user_id'))
				.query("where", "read", "=", 0)
				.fetch()
				.then (notifications) ->
					res.r.notifications = notifications.models
					next()
				, (err) ->
					console.error err
			else
				next()

		read_notifications: (req, res, next) ->
			if req.me
				Notifications.forge()
				.query("where", "user_id", "=", req.me.get('user_id'))
				.query("where", "read", "=", 0)
				.fetch()
				.then (notifications) ->
					for notification in notifications.models
						notification.set("read", 1).save()
					tk "MARK READ NOTFICATIONS"
					next()
				, (err) ->
					console.error err
			else
				next()

module.exports = routes
