routes = (app) ->

	[Device, Devices] = require('../../models/devices')

	device =
		add: (req, res, next) ->
			if req.me
				if req.query.token && req.query.type
					Device.forge
						user_id: req.me.get('user_id')
						token: req.query.token
						type: req.query.type
					.save()
					.then ->
						res.r.saved_token = 1
						next()
				else
					res.r.msg = 'No token'
					res.status(401)
					next()
			else
				res.r.msg = 'You need to be logged in to transfer a ticket!'
				res.status(403)
				next()

module.exports = routes