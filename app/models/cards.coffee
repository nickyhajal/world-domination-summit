Shelf = require('./shelf')
_ = require('underscore')
Q = require('q')
crypto = require('crypto')


[Product, Products] = require('./products')
[Transaction, Transcations] = require('./transactions')

Card = Shelf.Model.extend
	tableName: 'cards'
	idAttribute: 'card_id'
	hasTimestamps: true
	permittedAttributes: [
		'card_id', 'hash', 'user_id', 'brand', 'last4', 'exp_month', 'exp_year'
	]
	initialize: ->
		this.on 'creating', this.creating, this

	creating: (e)->
		rand = (new Date()).valueOf().toString() + Math.random().toString()
		hash = crypto.createHash('sha1').update(rand).digest('hex')
		@set
			hash: hash

	charge: (code, purchase_data) ->
		tk 'r1'
		key = if code is false then process.env.STRIPE_SK_TEST else process.env.STRIPE_SK
		stripe = require('stripe')(key)
		dfr = Q.defer()
		Product.forge
			code: code
		.fetch()
		.then (product, meta) =>
			tk 'r2'
			quantity = if purchase_data.quantity then purchase_data.quantity else 1
			if product
				tk 'r3'
				transaction = Transaction.forge
					product_id: product.get('product_id')
					user_id: @get('user_id')
					status: 'process'
					quantity: quantity
					paid_amount: '0'
				.save()
				.then (transaction) =>
					tk 'r4'
					purchase_data.transaction_id = transaction.get('transaction_id')
					product.pre_process({user_id: @get('user_id'), post: purchase_data})
					.then (pre) =>
						tk 'r5'
						pre_rsp_params = pre?.rsp ? {}
						price = if pre.price? then pre.price else product.get('cost')
						price *= 	quantity
						stripe.charges.create
							amount: price
							currency: 'usd'
							customer: @get('customer')
							source: @get('token')
							description: product.get('name')+' - '+product.get('descr')
						.then (charge) =>
							tk 'r6'
							Transaction.forge
								transaction_id: transaction.get("transaction_id")
							.fetch()
							.then (transaction) =>
								tk 'r7'
								transaction.set
									status: 'paid'
									paid_amount: price
									stripe_id: charge.id
									meta: if pre?.meta? then pre.meta else null
								.save()
								.then =>
								tk 'r8'
									product.post_process(transaction, charge)
									.then (post_rsp) =>
										tk 'POST DONE'
										post_rsp_params = post_rsp?.rsp ? {}
										rsp_params = _.extend pre_rsp_params, post_rsp_params
										dfr.resolve({transaction: transaction, rsp: rsp_params})
								, (err) -> console.error(err)
						, (err) ->
							console.error err
					, (err) ->
						console.error err
		return dfr.promise



Cards = Shelf.Collection.extend
	model: Card

module.exports = [Card, Cards]