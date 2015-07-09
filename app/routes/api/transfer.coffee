_ = require('underscore')
redis = require("redis")
rds = redis.createClient()
twitterAPI = require('node-twitter-api')
moment = require('moment')
crypto = require('crypto')
request = require('request')
async = require('async')

routes = (app) ->

	[Transfer, Transfers] = require('../../models/transfers')
	[User, Users] = require('../../models/users')

	#TMP XFER SYNC
	# Transfers.forge()
	# .query('where', 'status', 'paypal_return')
	# .fetch()
	# .then (rsp) ->
	# 	async.each rsp.models, (xfer, cb) ->
	# 		xfer.set({status: 'paid'})
	# 		.save()
	# 		.then ->
	# 			new_attendee = JSON.parse(xfer.get('new_attendee'))
	# 			new_attendee['attending'+process.yr] = 1
	# 			User.forge(new_attendee)
	# 			.save()
	# 			.then (new_user) ->
	# 				new_user.registerTicket('TRANSFER_FROM_'+xfer.get('user_id'), null, xfer.get('user_id'))
	# 				User.forge({user_id: xfer.get('user_id')})
	# 				.fetch()
	# 				.then (old_user) ->
	# 					old_user.sendEmail('transfer-receipt', 'Your ticket transfer was successful!', {to_name: new_attendee.first_name + ' '+new_attendee.last_name})
	# 					cb()

	transfer =
		add: (req, res, next) ->
			if req.me
				amount = '100.00'
				if ''+req.me.get('user_id') is '176'
					amount = '1.00'
				post = _.pick req.query, User.prototype.permittedAttributes
				xfer = {}
				xfer.new_attendee = JSON.stringify(post)
				xfer.user_id = req.me.get('user_id')
				xfer.year = process.year
				xfer.status = 'paypal_wait'
				Transfer.forge(xfer)
				.save()
				.then (transfer) ->
					params =
						item_name_1: 'WDS Ticket Transfer'
						amount_1: amount
						item_num_1: '1'
						quantity_1: '1'
						cmd: '_cart'
						current_code: 'USD'
						upload: '1'
						return: 'http://' + process.dmn + '/api/transfer/return'
						business: 'chris.guillebeau@gmail.com'
						notify_url: 'http://' + process.dmn + '/api/transfer/ipn'
						custom: transfer.get('transfer_id')
					data = ''
					for key,val of params
						data += '&'+key+'='+val
					res.redirect('https://www.paypal.com/cgi-bin/webscr?'+data.substr(1))
			else
				res.r.msg = 'You need to be logged in to transfer a ticket!'
				res.status(403)

		pdt: (req, res, next) ->
			req.session.paypal_tx = req.query.tx
			call =
				url: 'https://www.paypal.com'
				method: 'post'
				form:
					cmd: '_notify-synch'
					tx: req.query.tx
					at: process.env.PAYPAL_TOKEN
			request call, (err, code, body) ->
				parts = body.split('\n')
				success = parts[0]
				rsp = {}
				if success is 'SUCCESS'
					for part in parts.splice(1)
						bits = part.split('=')
						rsp[bits[0]] = bits[1]
					ticket_id = rsp['custom']
					Transfer.forge({transfer_id: rsp['custom']})
					.fetch()
					.then (xfer) ->
						if xfer.get('status') is 'paid'
							res.redirect('/your-transfer/'+ticket_id)
						else
							Transfer.forge({transfer_id: ticket_id, status: 'paypal_return'})
							.save()
							.then ->
								res.redirect('/your-transfer/'+ticket_id)
				else
					res.redirect('/your-transfer/'+ticket_id)

		ipn: (req, res, next) ->
			form = {}
			for key,val of req.query
				form[key] = val
			form.cmd  = '_notify-validate'
			call =
				url: 'https://www.paypal.com'
				method: 'post'
				form: form
			request call, (err, code, body) ->
				parts = body.split('\n')
				success = parts[0]
				if success is 'VERIFIED'
					rsp = {}
					for part in parts.splice(1)
						bits = part.split('=')
						rsp[bits[0]] = bits[1]
					Transfer.forge({transfer_id: req.query.custom})
					.fetch()
					.then (xfer) ->
						if xfer.get('status') is 'paid'
							res.redirect('/')
						else
							# We should check if we're transferring to an existing user
							Transfer.forge({transfer_id: req.query.custom, status: 'paid'})
							.save()
							.then ->
								new_attendee = JSON.parse(xfer.get('new_attendee'))
								new_attendee['attending'+process.yr] = 1
								User.forge(new_attendee)
								.save()
								.then (new_user) ->
									uniqid = +(new Date()) + ''
									hash = crypto.createHash('md5').update(uniqid).digest('hex').substr(0,5)
									new_user.registerTicket('TRANSFER_FROM_'+xfer.get('user_id')+'_'+hash, null, xfer.get('user_id'))
									User.forge({user_id: xfer.get('user_id')})
									.fetch()
									.then (old_user) ->
										old_user.cancelTicket()
										old_user.sendEmail('transfer-receipt', 'Your ticket transfer was successful!', {to_name: new_user.get('first_name')+' '+new_user.get('last_name')})
								, (err) ->
									console.error err
								next()
				else
					next()


		status: (req, res, next) ->
			Transfer.forge({transfer_id: req.query.transfer_id})
			.fetch()
			.then (xfer) ->
				res.r.status = xfer.get('status')
				new_atn = JSON.parse(xfer.get('new_attendee'))
				res.r.to = new_atn.first_name+' '+new_atn.last_name
				next()

module.exports = routes