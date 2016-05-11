Q = require('q')
bcrypt = require('bcrypt')
redis = require("redis")
rds = redis.createClient()
RedisSessions = require("redis-sessions");
rs = new RedisSessions();
##

[Card, Cards] = require '../cards'

charge =
	getCard: (card_id, test = false) ->
		stripe_key = process.env.STRIPE_SK
		# stripe_key = process.env.STRIPE_SK_TEST if test
		stripe = require('stripe')(stripe_key)
		dfr = Q.defer()
		tk 'c1'
		if card_id.indexOf('tok_') > -1
			tk 'c2'
			Card.forge
				token: card_id
			.fetch()
			.then (exists) =>
				tk 'c3'
				if exists
					tk 'c4'
					dfr.resolve(exists)
				else
					tk 'c5'
					stripe.customers.create
						source: card_id
						email: @get('email')
					.then (customer) =>
						tk 'c6'
						stripe.tokens.retrieve card_id, (err, token) =>
							c = token.card
							Card.forge
								user_id: @get('user_id')
								brand: c.brand
								exp_month: c.exp_month
								exp_year: c.exp_year
								last4: c.last4
								customer: customer.id
								token: c.id
							.save()
							.then (card) =>
								dfr.resolve(card)
							, (err) ->
								tk err
		else
			tk 'cc1'
			Card.forge
				hash: card_id
			.fetch()
			.then (exists) =>
				dfr.resolve(exists)
		return dfr.promise

module.exports = charge
