###
# Routes for the WDSfm API
###
jade = require('jade')
redis = require("redis")
rds = redis.createClient()
fs = require('fs')
gm = require('gm')
_ = require('underscore')
execFile = require('child_process').execFile
[User, Users] = require('../models/users')
[Content, Contents] = require('../models/contents')
[Answer, Answers] = require('../models/answers')

routes = (app) ->
	ident = false

	app.namespace '/api', (req, res, next)->
		[view, r] = [null, null]
		errors = []

		app.all '/*', (req, res, next)->
			_req = req
			res.contentType 'json'
			req.query = _.defaults(req.body, req.query)
			view = "../views/api"
			r =
				cb: (req.query.callback ? '')
				rsp: {}
				layout: false
			ident = if req.session.ident then JSON.parse(req.session.ident) else false
			if ident
				id = ident.userid ? ident.id
				_Users = Users.forge()
				_Users.query('where', 'userid', id)
				.fetch()
				.then (rsp) ->
					if rsp.models.length
						req.me = rsp.models[0]
					next()
			else
				next()

		# CONTENT
		#########
		app.get '/parse', (req, res, next) ->
			_Contents = Contents.forge()
			_Contents
			.query('where', 'type', '=', 'flickr_stream')
			.query('where', 'contentid', '>', '390')
			.fetch()
			.then (contents) ->
				processImg = (content) ->
					data = JSON.parse content.get('data')
					url = data.the_img
					unless data.width?
						tk content.get('contentid')
						gm(url)
						.size (err, size) ->
							tk content.get('contentid')
							data.height = size.height
							data.width = size.width
							if size.width > size.height
								data.orientation = 'landscape'
							else
								data.orientation = 'portrait'
							content.set
								data:  JSON.stringify(data)
							content.save()

				for cont in contents.models
					processImg cont
				next()

		app.get '/content', (req, res, next) ->
			offset = Math.floor( Math.random() * (0 - 3000 + 1) ) + 3000
			_Users = Users.forge()
			_Contents = Contents.forge()
			_Answers = Answers.forge()
			_Contents
			.query('where', 'contentid', '>', '0')
			.query('orderBy', 'contentid', 'desc')
			.fetch(
				columns: ['contentid', 'type', 'data']
			)
			.then (contents) ->
				_Users
				.query('where', 'pub_loc', '=', '1')
				.query('where', 'attending14', '=', '1')
				.query('where', 'pic', '<>', '')
				.query('orderBy', 'attendeeid', 'desc')
				.fetch(
					columns: ['attendeeid', 'fname', 'lname', 'uname', 'distance', 'lat', 'lon', 'pic']
				)
				.then (attendees) ->
					_Answers
					.query('join', 'attendees', 'answers.userid', '=', 'attendees.attendeeid')
					.query('where', 'attendees.attending14', '=', '1')
					.query('limit', '500')
					.query('offset', offset)
					.query('orderBy', 'attendeeid', 'desc')
					.fetch(
						columns: ['userid', 'questionid', 'answer']
					)
					.then (answers) ->
						r.rsp.answers = answers
						r.rsp.content = contents
						r.rsp.attendees = attendees
						next()
				, (err) ->
					tk err
			, (err) ->
				tk err



		###########
		## USERS ##
		###########

		app.post '/user', (req, res, next) ->
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
						r.rsp.user = user
						next()
			startUser()

		app.post '/user/login', (req, res, next) ->
			new User(email: req.query.email)
			.fetch()
			.then (user) ->
				if user
					user.authenticate(req.query.password, req)
					.then (authd)->
						if authd
							user.getDuos()
							.then (user) ->
								r.rsp.me = user
								r.rsp.loggedin = true
								next()
						else
							r.rsp.loggedin = false
							next()
				else 
					r.rsp.loggedin = false
					next()
		app.get '/me', (req, res, next) ->
			if req.me
				_Users = Users.forge()
				_Users.getUser(req.me.get('userid'))
				.then (user) ->
					user.getDuos()
					.then (user) ->
						r.rsp.me = user
						next()
			else
				r.rsp.me = false
				next()

		app.get '/user', (req, res, next) ->
			userid = req.query.userid
			_Users = Users.forge()
			_Users.query('where', 'userid', '=', userid)
			.fetch()
			.then (rsp) ->
				user = rsp.models[0]
				user.getDuos()
				.then (user) ->
					r.rsp.user = user
					next()
			, (err) ->
				res.statusCode = 400
				errors.push(err.message)
				next()

		###
		Finish
		###
		app.all '/*', (req, res) ->
			res.setHeader('Content-Type', 'application/json')
			if not req.query.clean?
				if errors.length
					r.rsp.errors = errors
					r.rsp.err = 1
				else
					r.rsp.suc = 1
			res.render view, r
			me = false
			ident = false
			errors = []
module.exports = routes
