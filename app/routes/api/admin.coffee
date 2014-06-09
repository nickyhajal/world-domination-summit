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
		ambassador_accept: (req, res, next) ->
			if req.me.hasCapability('ambassadors')
				User.forge
					user_id: req.query.id
				.fetch()
				.then (model) ->
					model.set('type', 'ambassador')
					model.set('attending14', 1)
					model.save()
					res.redirect('/admin/ambassadors')
			else
				res.status(401)
				next()
		ambassador_reject: (req, res, next) ->
			if req.me.hasCapability('ambassadors')
				User.forge
					user_id: req.query.id
				.fetch()
				.then (model) ->
					model.set('type', 'rejected-ambassador')
					model.save()
					res.redirect('/admin/ambassadors')
			else
				res.status(401)
				next()

module.exports = routes
