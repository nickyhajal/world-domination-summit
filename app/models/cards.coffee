Shelf = require('./shelf')
_ = require('underscore')
Q = require('q')


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
		key = if code is 'connect' then process.env.STRIPE_SK_TEST else process.env.STRIPE_SK
		stripe = require('stripe')(key)
		dfr = Q.defer()
		Product.forge
			code: code
		.fetch()
		.then (product, meta) =>
			quantity = if purchase_data.quantity then purchase_data.quantity else 1
			if product
				transaction = Transaction.forge
					product_id: product.get('product_id')
					user_id: @get('user_id')
					status: 'process'
					quantity: quantity
					paid_amount: '0'
				.save()
				.then (transaction) =>
					purchase_data.transaction_id = transaction.get('transaction_id')
					product.pre_process({user_id: @get('user_id'), post: purchase_data})
					.then (pre) =>
						pre_rsp_params = pre?.rsp ? {}
						price = product.get('cost')
						price *= 	quantity
						stripe.charges.create
							amount: price
							currency: 'usd'
							customer: @get('customer')
							source: @get('token')
							description: product.get('name')+' - '+product.get('descr')
						.then (charge) =>
							Transaction.forge
								transaction_id: transaction.get("transaction_id")
							.fetch()
							.then (transaction) =>
								transaction.set
									status: 'paid'
									paid_amount: price
									stripe_id: charge.id
									meta: if pre?.meta? then pre.meta else null
								.save()
								.then =>
									product.post_process(transaction, charge)
									.then (post_rsp) =>
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