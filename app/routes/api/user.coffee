[User, Users] = require('../../models/users')
_ = require('underscore')
redis = require("redis")
rds = redis.createClient()

user = 

	# Get logged in user
	me: (req, res, next) ->
		if req.me
			_Users = Users.forge()
			_Users.getUser(req.me.get('userid'))
			.then (user) ->
				user.getDuos()
				.then (user) ->
					res.r.me = user
					next()
		else
			res.r.me = false
			next()

	# Get a user
	get: (req, res, next) ->
		userid = req.query.userid
		_Users = Users.forge()
		_Users.query('where', 'userid', '=', userid)
		.fetch()
		.then (rsp) ->
			user = rsp.models[0]
			user.getDuos()
			.then (user) ->
				res.r.user = user
				next()
		, (err) ->
			res.statusCode = 400
			errors.push(err.message)
			next()

	# Authenticate a user
	login: (req, res, next) ->
		new User(email: req.query.email)
		.fetch()
		.then (user) ->
			if user
				user.authenticate(req.query.password, req)
				.then (authd)->
					if authd
						user.getDuos()
						.then (user) ->
							res.r.me = user
							res.r.loggedin = true
							next()
					else
						res.r.loggedin = false
						next()
			else 
				res.r.loggedin = false
				next()

	# Update a user
	update: (req, res, next) ->
			startUser = ->
				new_user = _.pick(req.query, ['first_name', 'last_name', 'email', 'password'])
				x = User.forge(new_user)
				.save()
				.then (new_user)->
					# login user
					new_user.login(req)
					if req.query.joining_duo
						new Duo({hash: req.query.joining_duo})
						.fetch()
						.then (duo) ->
							duo.accept(new_user)
							.then (rsp) ->
								finishUser new_user
					else
						finishUser new_user
				, (err) ->
					res.statusCode = 400;
					errors.push(err.message)
					next()

			finishUser = (user) ->
				new User(userid: user.attributes.id).fetch().then (user) ->
					user.getDuos()
					.then (user) ->
						res.r.user = user
						next()
			startUser()
module.exports = user