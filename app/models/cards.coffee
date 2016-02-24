Shelf = require('./shelf')
_ = require('underscore')
Q = require('q')
stripe = require('stripe')(process.env.STRIPE_SK)


[Product, Products] = require('./products')
[Transaction, Transcations] = require('./transactions')

Card = Shelf.Model.extend
	tableName: 'cards'
	idAttribute: 'card_id'
	hasTimestamps: true
	permittedAttributes: [
		'card_id', 'user_id', 'token', 'last4', 'exp'
	]

	charge: (code, purchase_data) ->
		dfr = Q.defer()
		Product.forge
			code: code
		.fetch()
		.then (product, meta) =>
			if product
				transaction = Transaction.forge
					product_id: product.get('product_id')
					user_id: @get('user_id')
					status: 'process'
					paid_amount: '0'
				product.pre_process({user_id: @get('user_id'), post: purchase_data})
				.then (pre) =>
					pre_rsp_params = pre.rsp ? {}
					stripe.charges.create
						amount: product.get('cost')
						currency: 'usd'
						customer: @get('customer')
						source: @get('token')
						description: product.get('name')+' - '+product.get('descr')
					.then (charge) =>
						transaction.set
							status: 'paid'
							paid_amount: product.get('cost')
							stripe_id: charge.id
							meta: pre.meta
						.save()
						.then =>
							product.post_process(transaction, charge)
							.then (post_rsp) =>
								post_rsp_params = post_rsp.rsp ? {}
								rsp_params = _.extend pre_rsp_params, post_rsp_params
								dfr.resolve({transaction: transaction, rsp: rsp_params})
					, (err) ->
						console.error err
		return dfr.promise



Cards = Shelf.Collection.extend
	model: Card

module.exports = [Card, Cards]