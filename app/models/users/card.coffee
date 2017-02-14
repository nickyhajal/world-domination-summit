Q = require('q')
bcrypt = require('bcrypt')
redis = require("redis")
rds = redis.createClient()
RedisSessions = require("redis-sessions");
rs = new RedisSessions();
##
stripe_key = process.env.STRIPE_SK
stripe = require('stripe')(stripe_key)

[Card, Cards] = require '../cards'

charge =
	getStripeCustomer: (card_id) ->
		dfr = Q.defer()
		createStripeUser = ->
		stripeUserId = @get('stripe')
		if stripeUserId? and stripeUserId
			stripe.customers.retrieve(stripeUserId)
			.then (stripeUser) =>
				stripe.customers.update stripeUser.id,
					source: card_id
				.then =>
					dfr.resolve(stripeUser)
		else
			stripe.customers.create
				source: card_id
				email: @get('email')
				description: @getFullName()
			.then (stripeUser) =>
				@set('stripe', stripeUser.id).save()
				dfr.resolve(stripeUser)

		return dfr.promise

	getCard: (card_id, fireRef) ->

		dfr = Q.defer()
		fireRef.update({status: 'start-card', name: @getFullName()})
		tk 'Getting '+@getFullName()+'\'s card from '+card_id+'...'
		if card_id.indexOf('tok_') > -1
			tk 'Generating a Stripe card for '+@getFullName()+'...'
			Card.forge
				token: card_id
			.fetch()
			.then (exists) =>
				if exists
					dfr.resolve(exists)
				else
					fireRef.update({status: 'create-customer'})
					@getStripeCustomer(card_id)
					.then((customer) =>
						stripe.tokens.retrieve(card_id)
						.then((token) =>
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
								fireRef.update
									status: 'error'
									declined: true
									error: err
								tk err
						).catch((err) =>
							tk err
							fireRef.update
								status: 'error'
								declined: true
								error: err
							dfr.resolve({status: 'declined', err: err})
						)
					)
					.catch((err) =>
						tk err
						tk 'Card add error'
						dfr.resolve({status: 'declined', err: err})
					)
		else
			tk 'Using existing card in our DB...'
			Card.forge
				hash: card_id
			.fetch()
			.then (exists) =>
				dfr.resolve(exists)
		return dfr.promise

module.exports = charge
