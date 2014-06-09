routes = (app) ->

	[User, Users] = require('../../models/users')

	admin =
		get_capabilities: (req, res, next) ->
			req.me.getCapabilities()
			.then (capable_me) ->
				req.me = capable_me
				next()
		export: (req, res, next) ->
			if req.me.hasCapability('manifest')
				# users csv processing
				res.r.msg = 'Success'
			else
				res.status(401)
		ambassadors: (req, res, next) ->
			Users.forge()
				.query('where', 'type', 'potential-ambassador')
				.fetch()
				.then (model) ->
					res.r.users = model
					next()

module.exports = routes
