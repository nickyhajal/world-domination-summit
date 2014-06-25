_ = require('underscore')
redis = require("redis")
async = require("async")
rds = redis.createClient()
twitterAPI = require('node-twitter-api')

routes = (app) ->

	twitter = new twitterAPI
		consumerKey: app.settings.twitter_consumer_key
		consumerSecret: app.settings.twitter_consumer_secret
		callback: process.dmn + '/api/user/twitter/callback'

	[User, Users] = require('../../models/users')
	[TwitterLogin, TwitterLogins] = require('../../models/twitter_logins')
	[Answer, Answers] = require('../../models/answers')
	[UserInterest, UserInterests] = require('../../models/user_interests')
	[CredentialChange, CredentialChanges] = require('../../models/credential_changes')
	[Connection, Connections] = require('../../models/connections')
	[Registration, Registrations] = require('../../models/registrations')
	[Notification, Notifications] = require('../../models/notifications')

	user =
		# Get logged in user
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
									res.r.me = user
									next()
			else
				res.r.me = false
				next()

		# Get a user
		get: (req, res, next) ->
			User.forge
				user_name: req.query.user_name
			.fetch()
			.then (user) ->
				user.getReadableCapabilities()
				.then (user) ->
					user.getAnswers()
					.then (user) ->
						user.getInterests()
						.then (user) ->
							user.getAllTickets()
							.then (user) ->
								res.r.user = user
								next()
							res.r.user = user
							next()
			, (err) ->
				console.error(err)
				res.status(400)
				errors.push(err.message)
				next()

		search: (req, res, next) ->
			_Users = Users.forge()
			all = {}
			async.each req.query.search.split(' '), (term, cb) ->
				_Users.query('orWhere', 'first_name', 'LIKE', term+'%')
				_Users.fetch()
				.then (byF) ->
					_Users = Users.forge()
					_Users.query('orWhere', 'last_name', 'LIKE', term+'%')
					.fetch()
					.then (byL) ->
						_Users = Users.forge()
						_Users.query('orWhere', 'email', 'LIKE', '%'+term+'%')
						_Users.fetch()
						.then (byE) ->
							for f in byF.models
								id = f.get('user_id')
								all[id] = f.attributes unless all[id]
								if all[id].score? then all[id].score += 2 else (all[id].score = 2)
							for l in byL.models
								id = l.get('user_id')
								all[id] = l.attributes unless all[id]
								if all[id].score? then all[id].score += 3 else (all[id].score = 3)
							for e in byE.models
								id = e.get('user_id')
								all[id] = e.attributes unless all[id]
								if all[id].score? then all[id].score += 1 else (all[id].score = 1)
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

		logout: (req, res, next) ->
			if req.session.ident?
				req.session.destroy()
			next()

		# Authenticate a user
		login: (req, res, next) ->
			finish = (user = false) ->
				if user
					user.login req
					user.getAnswers()
					.then (user) ->
						user.getInterests()
						.then (user) ->
							res.r.loggedin = true
							res.r.me = user
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
			user = User.forge(post)
			.save()
			.then (new_user, err) ->
				hash = require('crypto').createHash('md5').update(''+(+(new Date()))).digest("hex").substr(0,5)
				new_user.registerTicket('ADDED_BY_'+req.me.get('user_id')+'_'+hash)
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
						user.set('attending14', '1').save()
						res.r.msg = 'Registered'
					next()

		update: (req, res, next) ->
			post = _.pick(req.query, User.prototype.permittedAttributes)
			if req.me
				if req.me.get('user_id') is post.user_id or req.me.hasCapability('manifest')
					User.forge({user_id: post.user_id})
					.fetch()
					.then (user) ->
						user.set(post)
						user.save()
						.then (user) ->
							if user.addressChanged
								User.forge({user_id: post.user_id})
								.fetch()
								.then (addr_user) ->
									addr_user.processAddress()

							if req.query.answers?
								Answers
								.forge()
								.updateAnswers(post.user_id, JSON.parse(req.query.answers))

							if req.query.new_password? and req.query.new_password.length
								User.forge({user_id: post.user_id}).updatePassword(req.query.new_password)

							if req.query.capabilities_update
								user.getCapabilities
								if req.query.capabilities
									user.setCapabilities req.query.capabilities.split(",")
								else
									user.setCapabilities {}
							next()
						, (err) ->
							console.error(err)
			else
				res.status(401)
				next()

		reset: (req, res, next) ->
			if req.query.username?
				query = {user_name: req.query.username}
				if req.query.username.indexOf('@') > -1
					query = {email: req.query.username}
				User.forge(query)
				.fetch()
				.then (user) ->
					CredentialChange
					.forge()
					.create(user)
					.then (rsp) ->
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

		add_interest: (req, res, next) ->
			if req.me
				UserInterest.forge
					interest_id: req.query.interest_id
					user_id: req.me.get('user_id')
				.save()
				.then (row) ->
					res.r.msg = "Interest added!"
					next()
			else
				next()

		del_interest: (req, res, next) ->
			if req.me
				UserInterest.forge
					interest_id: req.query.interest_id
					user_id: req.me.get('user_id')
				.fetch()
				.then (row) ->
					if row
						row.destroy()
						res.r.msg = 'Interest deleted.'
						next()
					else
						res.rsp.msg = 'That interest already wasn\'t there'
						res.status(410)
						next()

		twitter_connect: (req, res, next) ->
			twitter.getRequestToken (err, reqToken, reqTokenSec, twitter_rsp) ->
				if err
					res.r.msg = err
					res.status = '400'
				else
					req.session.twitter_connect = [reqToken, reqTokenSec]
					res.redirect('https://twitter.com/oauth/authenticate?oauth_token='+reqToken)

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
									req.me.set
										twitter: rsp.screen_name
										pic: rsp.profile_image_url_https
									req.me.save()
									.then ->
										res.redirect('/welcome')
								, (err) ->
									console.error(err)
							else
								req.session.twitter_err = 1
								res.redirect('/welcome')

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
				Connection.forge({user_id: user_id, to_id: to_id, year: process.year})
				.save()
				.then (connection) ->
					req.me.getConnections()
					.then (user) ->
						res.r.connections = user.get('connections')
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
						req.me.getConnections()
						.then (user) ->
							res.r.connections = user.get('connections')
							res.r.connected_ids = user.get('connected_ids')
							next()
			else
				res.status(401)

		registrations: (req, res, next) ->
			regs = req.query.regs ? []
			successes = []
			async.each regs, (reg, cb) ->
				Registration.forge({user_id: reg.user_id, year: process.yr})
				.fetch()
				.then (existing) ->
					if existing and reg.action is 'unregister'
						existing.destroy().then ->
							res.r.msg = 'Unregistered!'
							successes.push(reg)
							cb()
					else if reg.action is 'register' and not existing
						Registration.forge({user_id: reg.user_id, year: process.yr})
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
				.query('where', 'year', '=', process.yr)
				.query('where', 'created_at', '>', (new Date(new Date().getTime() - 3600000)))
				.fetch()
				.then (past_hour) ->
					_Rs
					.query('where', 'year', '=', process.yr)
					.fetch()
					.then (all_time) ->
						res.r.reg_past_hour = past_hour.models.length
						res.r.reg_all = all_time.models.length
						res.r.successes = successes
						regs = {}
						for reg in all_time.models
							regs[reg.get('user_id')] = '1'
						res.r.registrations = regs
						next()
				, (err) ->
					console.error(err)


module.exports = routes
