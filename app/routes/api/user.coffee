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
				user.getAnswers()
				.then (user) ->
					user.getInterests()
					.then (user) ->
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

		# Create a user
		create: (req, res, next) ->
				startUser = ->
					new_user = _.pick(req.query, ['first_name', 'last_name', 'email', 'password'])
					x = User.forge(new_user)
					.save()
					.then (new_user)->
						# login user
						new_user.login(req)
						finishUser new_user
					, (err) ->
						res.statusCode = 400;
						errors.push(err.message)
						next()

				finishUser = (user) ->
					new User(userid: user.attributes.id).fetch().then (user) ->
						res.r.user = user
						next()
				startUser()

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

module.exports = routes