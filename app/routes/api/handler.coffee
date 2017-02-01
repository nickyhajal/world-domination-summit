[User, Users] = require('../../models/users')
RedisSessions = require("redis-sessions");
rs = new RedisSessions();
_ = require('underscore')
handler =
	start: (req, res, next)->
		# tk '>>> START'
		# tk req.session
		req.hasParams = (params, req, res, next) ->
			allow = true
			for p in params
				unless req.query[p]?
					allow = false
			if allow
				return true
			else
				res.r.msg = 'Missing required values!'
				res.status(400)
				next()
				return false

		req.hasSomeParams = (params, req, res, next, cb) ->
			allow = false
			for p in params
				if req.query[p]?
					allow = true
			if allow
				return true
			else
				res.r.msg = 'Missing required values!'
				res.status(400)
				next()
				return false

		req.isAuthd = (req, res, next) ->
			if req.me
				return true
			else
				res.r.msg = 'You\'re not logged in!'
				res.status(403)
				next()
				return false

		res.notAuthd = (next) ->
			res.r.msg = 'You don\'t have permission to do that.'
			res.status(403)
			next()

		res.contentType 'json'
		req.query = _.defaults(req.body, req.query)
		res.r = {}
		res.errors = []
		getMe = ->
			# Get logged in user
			Users.forge().getMe(req)
			.then (me) ->
				if me
					req.me = me
				if req.query.admin?
					req.me.getCapabilities()
					.then (capable_me) ->
						req.me = capable_me
						next()
				else
					next()
		if req.query.user_token?
			rs.get
				app: process.rsapp
				token: req.query.user_token
				ttl: 31536000
			, (err, rsp) ->
				if rsp.id?
					req.session.ident = JSON.stringify({id: rsp.id})
					getMe()
				else
					res.r.token_invalid = true
					next()
		else
			getMe()


	finish: (req, res) ->
		res.setHeader('Content-Type', 'application/json')
		if not req.query.clean?
			if res.errors.length
				res.r.errors = res.errors
				res.r.err = 1
			else
				res.r.suc = 1

		# if req.query.via? and req.query.via == 'android'
		# 	res.r = JSON.stringify(res.r)

		render =
			layout: false
			rsp: res.r
			cb: (req.query.callback ? '')

		res.render '../views/api', render
		me = false
		ident = false
		errors = []

module.exports = handler