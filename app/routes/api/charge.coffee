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

routes = (app) ->

	[Transfer, Transfers] = require('../../models/transfers')
	[Ticket, Tickets] = require('../../models/tickets')
	[User, Users] = require('../../models/users')

	charge =
		ticket: (req, res, next) ->
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
module.exports = routes