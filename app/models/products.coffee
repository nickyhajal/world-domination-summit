Shelf = require('./shelf')
_ = require('underscore')
Q = require('q')
chance = require('chance')()
async = require('async')

[Transfer, Transfers] = require('./transfers')
[Transaction, Transcations] = require('./transactions')
[Ticket, Tickets] = require('./tickets')
[EventRsvp, EventRsvps] = require('./event_rsvps')

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
			.then (data) ->
				dfr.resolve(data)
		else
			dfr.resolve()
		dfr.promise

Products = Shelf.Collection.extend
	model: Product


PRE =
	academy: (meta) ->
		dfr = Q.defer()
		[User, Users] = require('./users')
		User.forge
			user_id: meta.user_id
		.fetch()
		.then (user) ->
			rsp = {meta: meta.post.event_id}
			if user? and parseInt(user.get('attending'+process.yr)) is 1
				rsp.price = 2900
			dfr.resolve(rsp)
		return dfr.promise
	wds2017: (meta) ->
		dfr = Q.defer()
		dfr.resolve({})
		return dfr.promise
	xfer: (meta) ->
		dfr = Q.defer()
		Transfer.forge
			new_attendee: JSON.stringify(meta.post)
			user_id: meta.user_id
			year: process.year
			status: 'pending'
		.save()
		.then (transfer) ->
			dfr.resolve
				meta: transfer.get('transfer_id')
		, (err) ->
			console.error(err)
		return dfr.promise
	connect: (meta) ->
		dfr = Q.defer()
		ids = []
		arr = [0...+meta.post.quantity]
		async.eachSeries arr, (i, cb) ->
			Ticket.forge
				type: 'connect'
				stripe_id: meta.post.transaction_id
				year: process.year
				user_id: meta.user_id
				status: 'pending'
			.save()
			.then (ticket) =>
				ids.push ticket.get('ticket_id')
				cb()
		, ->
			dfr.resolve {meta: JSON.stringify(ids)}
		return dfr.promise

POST =
	academy: (transaction, meta) ->
		[Event, Events] = require('./events')
		dfr = Q.defer()
		event_id = transaction.get('meta')
		user_id = transaction.get('user_id')
		rsvp = EventRsvp.forge
			user_id: user_id
			event_id: event_id
		rsvp.fetch()
		.then (existing) ->
			if existing
				dfr.resolve({rsvp_id: existing.get('rsvp_id')})
			else
				rsvp.save()
				.then (newrsvp) ->
					dfr.resolve({rsvp_id: newrsvp.get('rsvp_id')})
					Event.forge
						event_id: event_id
					.fetch()
					.then (ev) ->
						ev.updateRsvpCount()
						ev.sendAcademyConfirmation(user_id)
		return dfr.promise

	xfer: (transaction, meta) ->
		[User, Users] = require('./users')
		dfr = Q.defer()
		transfer_id = transaction.get('meta')
		Transfer.forge
			transfer_id: transfer_id
		.fetch()
		.then (xfer) ->
			new_attendee = JSON.parse(xfer.get('new_attendee'))
			delete new_attendee.transaction_id
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
					ticket_type = old_user.get('ticket_type')
					new_user.set('ticket_type', ticket_type)
					new_user.save()
					old_user.cancelTicket()
					old_user.sendEmail('transfer-receipt', 'Your ticket transfer was successful!', {to_name: new_user.get('first_name')+' '+new_user.get('last_name')})
					xfer.set
						status: 'paid'
					.save()
					.then ->
						dfr.resolve({rsp: {transfer_id: xfer.get('transfer_id')}})
			, (err) ->
				console.error err
		dfr.promise
	connect: (transaction, meta) ->
		[User, Users] = require('./users')
		dfr = Q.defer()
		ids = JSON.parse(transaction.get('meta'))
		tickets = []
		user = false

		# Get the transaction user
		User.forge
			user_id: transaction.get('user_id')
		.fetch()
		.then (user) ->
			async.eachSeries ids, (id, cb) ->
				# Create the tickets
				Ticket.forge
					ticket_id: id
				.fetch()
				.then (ticket) =>
					ticket.set 'status', 'purchased'
					ticket.save()
					tickets.push(ticket)
					cb()
			, ->
				dfr.resolve({rsp: {tickets: tickets, user: user}})
		return dfr.promise
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

