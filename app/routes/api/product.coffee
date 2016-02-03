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

	[Product, Products] = require('../../models/products')
	[Transaction, Transcations] = require('../../models/transactions')

	product =
		get: (req, res, next) ->
			if req.hasParams ['code'], req, res, next
				Product.forge
					code: req.query.code
				.fetch()
				.then (product) ->
					res.r.product = product
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
			if req.hasParams ['code', 'card_id'], req, res, next
				if req.isAuthd req, res, next
					tk req
					req.me.getCard(req.query.card_id)
					.then (card) ->
						tk 'GOT CARD'
						card.charge(req.query.code, req.query.purchase_data)
						.then (transaction) ->
							res.r.charge = transaction

module.exports = routes