_ = require('underscore')
redis = require("redis")
async = require("async")
rds = redis.createClient()
twitterAPI = require('node-twitter-api')
fs = require('fs')
crypto = require('crypto')
gm = require('gm')
mkdirp = require('mkdirp')

routes = (app) ->

	twitter = new twitterAPI
		consumerKey: app.settings.twitter_consumer_key
		consumerSecret: app.settings.twitter_consumer_secret
		callback: process.dmn + '/api/user/twitter/callback'

	[User, Users] = require('../../models/users')
	[UserNote, UserNotes] = require('../../models/user_notes')
	[TwitterLogin, TwitterLogins] = require('../../models/twitter_logins')
	[Answer, Answers] = require('../../models/answers')
	[UserInterest, UserInterests] = require('../../models/user_interests')
	[CredentialChange, CredentialChanges] = require('../../models/credential_changes')
	[Connection, Connections] = require('../../models/connections')
	[Registration, Registrations] = require('../../models/registrations')
	[Notification, Notifications] = require('../../models/notifications')
	[RaceSubmission, RaceSubmissions] = require('../../models/race_submissions')
	[Checkin, Checkins] = require('../../models/checkin')

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
					user.getMe()
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
						user.set('last_broadcast', new Date(user.get('last_broadcast')))
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
					.create(user, req.headers['x-real-ip'])
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

		race_check: (req, res, next) ->
			if req.me
				req.me.raceCheck()
				.then (points) ->
					req.me.getAchievedTasks()
					.then (achievements) ->
						res.r.achievements = achievements
						res.r.points = points
						next()

		add_unote: (req, res, next) ->
			if req.me
				post = _.pick req.query, UserNote::permittedAttributes
				post.user_id = req.me.get('user_id')
				UserNote.forge(post)
				.save()
				.then ->
					next()
			else
				res.status(401)
				next()

		get_unotes: (req, res, next) ->
			if req.me
				select = UserNotes.forge()
				if req.query.about_id?
					select.query('where', 'about_id', req.query.select_id)
				select.query('where', 'user_id', req.me.get('user_id'))
				select.fetch()
				.then (rsp) ->
					res.r.notes = rsp.models
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


		race_submission: (req, res, next) ->
			if req.me and req.query.slug?.length
				slug = req.query.slug
				if req.files
					req.me.markAchieved(slug)
					.then (ach_rsp) ->
						ext = req.files.pic.path.split('.')
						ext = ext[ext.length - 1]
						hash = crypto.createHash('md5').update((new Date().getTime())+'').digest("hex").substr(0, 5)
						name = hash+'.'+ext
						newPath = __dirname + '/../../../images/race_submissions/'+req.me.get('user_name')+'/'+slug
						fullPath = newPath+'/'+name
						smallPath = newPath+'/w600_'+name
						mkdirp newPath, (err, path) ->
							gm(req.files.pic.path)
							.autoOrient()
							.resize('1024^')
							.write fullPath, (err) ->
								gm(fullPath)
								.resize('600^')
								.write smallPath, (err) ->
									RaceSubmission.forge
										user_id: req.me.get('user_id')
										ach_id: ach_rsp.ach_id
										slug: slug
										hash: hash
										ext: ext
									.save()
									.then ->
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
												new_points: ach_rsp.points - req.query.cur_ponts
												task_id: req.query.task_id
												achievements: short_achs
											tk rsp

											# Expire rank cache so next rank request
											# is recalculated
											rds.expire 'ranks', 0
											tk 'REDIR'
											res.redirect('/upload-race?rsp='+rsp)
									, (err) ->
										console.error(err)


										next()

		add_checkin: (req, res, next) ->
			if req.me and req.query.location_id and req.query.location_type
				Checkin.forge
					user_id: req.me.get('user_id')
					location_id: req.query.location_id
					location_type: req.query.location_type
				.save()
				.then ->
					next()
				, (err) ->
				 	console.error(err)
			else
				next()

		get_notifications: (req, res, next) ->
			if req.me
				Notifications.forge()
				.query("where", "user_id", "=", req.me.get('user_id'))
				.fetch()
				.then (notifications) ->
					res.r.notifications = notifications.models
					next()
				, (err) ->
					tk err
			else
				next()

module.exports = routes
