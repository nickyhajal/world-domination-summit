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

module.exports = routes