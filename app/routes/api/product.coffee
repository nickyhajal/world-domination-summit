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
@ids = []

routes = (app) ->

	[Product, Products] = require('../../models/products')
	[Transaction, Transactions] = require('../../models/transactions')

	product =
		get: (req, res, next) ->
			if req.hasParams ['code'], req, res, next
				Product.forge
					code: req.query.code
				.fetch()
				.then (product) ->
					res.r.product = product
					next()

		get_transactions: (req, res, next) ->
			columns = {columns: ['first_name', 'last_name', 'email', 'email_hash', 'users.hash', 'pic', 'user_name', 'transactions.*', 'products.name', 'products.code']}
			Transactions.forge()
			.query (qb) ->
				qb.innerJoin('users', 'users.user_id', 'transactions.user_id')
				qb.innerJoin('products', 'products.product_id', 'transactions.product_id')
				qb.orderBy('transaction_id', 'DESC')
			.fetch(columns)
			.then (rsp) ->
				res.r.transactions = rsp.models
				next()

		availability: (req, res, next) ->
			if req.hasParams ['code'], req, res, next
				Product.forge
					code: req.query.code
				.fetch()
				.then (product) ->
					res.r.active = product.get('active')
					if product.get('max_sales') > 0
						res.r.remaining = product.get('max_sales') - product.get('sales')
					next()

		charge: (req, res, next) ->
			tk 'START CHARGE'
			if req.hasParams ['code', 'card_id'], req, res, next
				tk 'PARAMS GOOD'
				if req.isAuthd req, res, next
					tk 'IS AUTHD'
					if @ids.indexOf(req.query.card_id) == -1
						if req.query.card_id.indexOf('tok_') > -1
							@ids.push req.query.card_id
						req.me.getCard(req.query.card_id)
						.then (card) ->
							if card.status? and card.status is 'declined'
								tk 'ERR'
								res.r.declined = true
								res.r.err = card.err
								next()
							else
								tk 'GUNNA DO THIS'
								via = req.query.via ? 'web'
								card.charge(req.query.code, via, req.query.purchase_data)
								.then (charge) ->
									res.r = _.extend res.r, charge.rsp
									if !res.r.declined?
										res.r.charge = charge.transaction
										res.r.charge_success = true
									next()
					else
						tk 'DROP REQUEST'

module.exports = routes