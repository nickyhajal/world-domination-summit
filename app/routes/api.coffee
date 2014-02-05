###
# Routes for the WDSfm API
###
jade = require('jade')
redis = require("redis")
rds = redis.createClient()
fs = require('fs')
_ = require('underscore')
execFile = require('child_process').execFile
[Entry, Entries] = require('../models/entries')
[User, Users] = require('../models/users')
[Duo, Duos] = require('../models/duos')

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

		app.get '/duo', (req, res, next) ->
			hash = req.query.hash ? req.query.duoid
			inc_entries = req.query.inc_entries ? false
			_Duos = Duos.forge()
			_Duos.getDuo(hash, req.me, inc_entries)
			.then (duo) ->
				if req.query.clean
					r.rsp = duo
				else
					r.rsp.duo = duo
				next()

		app.post '/duo', (req, res, next) ->
			invitee = req.query.invitee
			creatorid = req.me.get('userid')
			duo = 
				invitee: invitee
				creatorid: creatorid
			Duo.forge(duo)
			.save()
			.then (new_duo) ->
				r.rsp.duo = new_duo
				if req.me
					_Users = Users.forge()
					_Users.getUser(req.me.get('userid'))
					.then (user) ->
						user.getDuos()
						.then (user) ->
							r.rsp.me = user
							next()
				else
					next()
			, (err) ->
				res.statusCode = 400;
				errors.push(err.message)
				next()

		app.post '/invite', (req, res, next) ->
			duoid = req.query.duoid
			new Duo({duoid: duoid})
			.fetch()
			.then (duo) ->
				duo.sendInvite(req.me, req.query.email)
				next()

		app.post '/entry', (req, res, next) ->
			getObj = ->
				if req.query.entry?.entryid
					new Entry({entryid: req.query.entry.entryid}).fetch()
					.then (entry) ->
						update entry
				else
					entry = new Entry
						userid: req.me.get('userid')
						duoid: req.query.duoid
					update(entry)
			update = (entry) ->
				entry_text = req.query.entry_text ? ''
				if entry.get('public') is 0 and req.query.public is 1
					## CHECK IF PUBLIC AND SEND NOTIFICATION
					## Template name: New Duo
					## duo_buddy_first_name
					## duo_link
				entry.set
					entry_text: req.query.entry_text
					public: (req.query.public ? 0)
				entry.save()
				.then ->
					_Duos = Duos.forge()
					_Duos.getDuo(req.query.duoid, req.me, true)
					.then (duo) ->
						r.rsp.duo = duo
						r.rsp.entry_save = true
						r.rsp.entry = entry
						r.rsp.duo
						next()
				, (err) ->
					tk err

			getObj()



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
