[User, Users] = require('../../models/users')
RedisSessions = require("redis-sessions");
rs = new RedisSessions();
_ = require('underscore')
handler = 
	start: (req, res, next)->
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
				req.session.ident = JSON.stringify({id: rsp.id})
				getMe()
		else
			getMe()


	finish: (req, res) ->
		res.setHeader('Content-Type', 'application/json')
		if not req.query.clean?
			if res.errors.length
				res.r.errors = errors
				res.r.err = 1
			else
				res.r.suc = 1

		render = 
			layout: false
			rsp: res.r
			cb: (req.query.callback ? '')

		res.render '../views/api', render
		me = false
		ident = false
		errors = []

module.exports = handler