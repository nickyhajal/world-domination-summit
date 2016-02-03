Shelf = require('./shelf')
_ = require('underscore')
Q = require('q')
chance = require('chance')()

[Transfer, Transfers] = require('./transfers')
[Transaction, Transcations] = require('./transactions')
[Ticket, Tickets] = require('./tickets')

Product = Shelf.Model.extend
	tableName: 'products'
	idAttribute: 'product_id'
	hasTimestamps: true
	permittedAttributes: [
		'product_id', 'name', 'descr', 'cost', 'sales'
	]
	pre_process: (meta = false) ->
		dfr = Q.defer()
		if PRE[@get('code')]?
			PRE[@get('code')](meta)
			.then (transfer_id) ->
				dfr.resolve(transfer_id)
		else
			dfr.resolve()
		return dfr.promise

	post_process: (meta = false) ->
		dfr = Q.defer()
		if POST[@get('code')]?
			POST[@get('code')](meta)
			.then ->
				dfr.resolve()
		else
			dfr.resolve()
		dfr.promise

Products = Shelf.Collection.extend
	model: Product


PRE =
	xfer: (meta) ->
		dfr = Q.defer()
		Transfer.forge
			new_attendee: JSON.stringify(meta.post)
			user_id: meta.user_id
			year: process.year
			status: 'pending'
		.save()
		.then (transfer) ->
			dfr.resolve(transfer.get('transfer_id'))
		, (err) ->
			tk err
		return dfr.promise

POST =
	xfer: (transaction, meta) ->
		[User, Users] = require('./users')
		dfr = Q.defer()
		transfer_id = transaction.get('meta')
		Transfer.forge
			transfer_id: transfer_id
		.fetch()
		.then (xfer) ->
			new_attendee = JSON.parse(xfer.get('new_attendee'))
			new_attendee['attending'+process.yr] = 1
			User.forge(new_attendee)
			.save()
			.then (new_user) ->
				uniqid = +(new Date()) + ''
				new_user.registerTicket('TRANSFER_FROM_'+xfer.get('user_id')+'_'+process.year, null, xfer.get('user_id'))
				new_user.processAddress()
				User.forge({user_id: xfer.get('user_id')})
				.fetch()
				.then (old_user) ->
					old_user.cancelTicket()
					old_user.sendEmail('transfer-receipt', 'Your ticket transfer was successful!', {to_name: new_user.get('first_name')+' '+new_user.get('last_name')})
					xfer.set
						status: 'paid'
					.save()
					.then ->
						dfr.resolve()
			, (err) ->
				console.error err
		dfr.promise
	connect: ->
	t360: (meta) ->
		Ticket.forge
			stripe_id: meta.id,
			year: process.year
			hash: chance.string({pool: 'abcdefghijklmnopqrstuvwxyz', length:6})
			meta_data: JSON.stringify
				shipping: meta.shipping
				source: meta.source
		.save()
		.then (ticket) ->
			res.r.ticket_success = true
			res.r.ticket = ticket
			next()


module.exports = [Product, Products]

