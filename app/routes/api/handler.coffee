[User, Users] = require('../../models/users')
_ = require('underscore')
handler = 
	start: (req, res, next)->
		res.contentType 'json'
		req.query = _.defaults(req.body, req.query)
		res.r = {}
		res.errors = []

		# Get logged in user
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