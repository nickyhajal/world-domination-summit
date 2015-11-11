_ = require('underscore')
redis = require("redis")
rds = redis.createClient()
twitterAPI = require('node-twitter-api')
moment = require('moment')
crypto = require('crypto')
request = require('request')
async = require('async')
stripe = require('stripe')(process.env.STRIPE_SK)
chance = require('chance')()
request = require('request')

routes = (app) ->

	[Transfer, Transfers] = require('../../models/transfers')
	[Ticket, Tickets] = require('../../models/tickets')
	[User, Users] = require('../../models/users')
	mailer = require('../../models/mailer')

	ticket =
		charge: (req, res, next) ->
			if req.query.token?
				stripe.charges.create
					amount: 64700
					currency: 'usd'
					source: req.query.token
					description: 'World Domination Summit 2016'
				.then (charge) ->
					res.r.charge_success = true
					Ticket.forge
						stripe_id: charge.id,
						year: process.year
						hash: chance.string({pool: 'abcdefghijklmnopqrstuvwxyz', length:6})
						meta_data: JSON.stringify
							shipping: charge.shipping
							source: charge.source
					.save()
					.then (ticket) ->
						res.r.ticket_success = true
						res.r.ticket = ticket
						next()
		get: (req, res, next) ->
			if req.query.hash?
				Ticket.forge
					hash: req.query.hash
				.fetch()
				.then (ticket) ->
					res.r.ticket = ticket
					next()

		availability: (req, res, next) ->
			res.r.num = '300'
			next()

		send: (req, res, next) ->
			if req.query.first_name && req.query.last_name? && req.query.sender_name? && req.query.email? && req.query.claim_link?
				list = 'WDS Sent Tickets'
				sender_name = req.query.sender_name
				claim_link = req.query.claim_link
				params =
		      username: process.env.MM_USER
		      api_key: process.env.MM_PW
		      email: req.query.email
		      first_name: req.query.first_name
		      last_name: req.query.last_name
		    call =
		      url: 'https://api.madmimi.com/audience_lists/'+list+'/add'
		      method: 'post'
		      form: params
		    request call, (err, code, rsp) ->
		    	mailer.send('send-ticket', req.query.sender_name+' sent you a ticket to WDS'+process.year+'!', req.query.email, {sender_name: sender_name, claim_link: claim_link})
		    	next()
module.exports = routes