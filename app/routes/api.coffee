###
	Routes for the WDS API
###

routes = (app) ->

	handler = require('./api/handler')

	admin= require('./api/admin')(app)
	assets = require('./api/assets')(app)
	content = require('./api/content')
	event = require('./api/event')(app)
	feed = require('./api/feed')(app)
	racetask = require('./api/racetask')(app)
	screens = require('./api/screens')(app)
	speaker = require('./api/speaker')(app)
	transfer = require('./api/transfer')(app)
	ticket = require('./api/ticket')(app)
	charge = require('./api/charge')(app)
	product = require('./api/product')(app)
	device = require('./api/device')(app)
	user = require('./api/user')(app)
	checkins = require('./api/checkins')(app)
	notifications = require('./api/notifications')(app)
	places = require('./api/places')(app)
	# contact = require('./api/contact')
	knex = require('knex')(process.db)
	express = require('express')
	expressGraphql = require('express-graphql')
	async = require('async');
	graphql = require('./api/graphql')
	existingAttendes = require('../util/existingAttendes');
	existingPurchasers = require('../util/existingPurchasers');

	apiRouter = express.Router()

	app.use('/api', apiRouter);
	
	# Setup
	apiRouter.all '/*', handler.start
	apiRouter.get '/assets', assets.get

	apiRouter.all '/graphql', graphql

	# Content
	apiRouter.get '/parse', content.parse
	apiRouter.get '/content', content.get

	# User
	apiRouter.get '/me', user.me
	apiRouter.get '/me/twitter', user.twitterCheck
	apiRouter.post '/me/claim-ticket', user.claim_ticket
	apiRouter.post '/me/give-ticket', user.give_ticket
	apiRouter.get '/users', user.search
	apiRouter.get '/user/events', user.get_events
	apiRouter.post '/user/update', user.update
	apiRouter.patch '/user', user.update
	apiRouter.put '/user', user.update
	apiRouter.get '/user/validate', user.validate
	apiRouter.get '/user', user.get
	apiRouter.get '/user/ticket', user.ticket
	apiRouter.get '/user/card', user.card
	apiRouter.get '/user/check_name', user.username_check
	apiRouter.post '/user', user.create
	apiRouter.post '/user/tickets', user.give_tickets
	apiRouter.post '/user/login', user.login
	apiRouter.post '/user/addToList', user.addToList
	apiRouter.post '/user/reset', user.reset
	apiRouter.post '/user/registrations', user.registrations
	apiRouter.post '/user/interest', user.add_interest
	apiRouter.post '/user/connection', user.add_connection
	apiRouter.post '/user/notifications', user.upd_notifications
	apiRouter.post '/user/story', user.post_story

	#
	apiRouter.post '/message', notifications.message

	#
	apiRouter.delete '/user/twitter', user.del_twitter
	apiRouter.delete '/user/connection', user.del_connection
	apiRouter.delete '/user/interest', user.del_interest
	apiRouter.post '/user/connection/delete', user.del_connection
	apiRouter.post '/user/interest/delete', user.del_interest
	apiRouter.post '/user/twitter/delete', user.del_twitter
	#

	apiRouter.get '/user/twitter/connect', user.twitter_connect
	apiRouter.get '/user/twitter/callback', user.twitter_callback
	apiRouter.post '/user/tweet', user.send_tweet
	apiRouter.post '/user/logout', user.logout
	apiRouter.post '/user/task', user.race_submission
	apiRouter.all '/user/achieved', user.achieved
	apiRouter.get '/user/racecheck', user.race_check
	apiRouter.get '/user/task', user.task
	apiRouter.get '/user/friends', user.get_friends
	apiRouter.get '/user/friends_by_type', user.get_friends_special
	apiRouter.post '/user/note', user.add_unote
	apiRouter.get '/user/notes', user.get_unotes
	apiRouter.post '/user/checkin', user.add_checkin
	apiRouter.get '/user/notification_tokens', user.get_notification_tokens
	apiRouter.get '/user/notifications', user.get_notifications
	apiRouter.get '/user/notifications/unread', user.get_unread_notifications
	apiRouter.get '/user/notifications/read', user.read_notifications
	apiRouter.post '/user/notifications/read', user.mark_read_notifications

	# Ticket
	apiRouter.get '/ticket', ticket.get
	apiRouter.post '/ticket/charge', ticket.charge
	apiRouter.post '/ticket/send', ticket.send
	apiRouter.get '/ticket/availability', ticket.availability

	# Product
	apiRouter.get '/product', product.get
	apiRouter.get '/product/availability', product.availability
	apiRouter.post '/product/charge', product.charge
	apiRouter.get '/transactions', product.get_transactions

	# Devices
	apiRouter.post '/device', device.add

	# Speakers
	apiRouter.put '/speaker', speaker.update
	apiRouter.post '/speaker', speaker.create

	# # Events
	apiRouter.get '/event', event.get
	apiRouter.get '/academies', event.academies
	apiRouter.get '/freeconf', event.send_confs
	apiRouter.post '/event/claim-academy', event.claim_academy
	apiRouter.post '/event', event.add
	apiRouter.put '/event', event.upd
	apiRouter.get '/event/attendees', event.get_attendees
	# apiRouter.get '/event/hosts', event.get_hosts
	apiRouter.post '/event/rsvp', (req, res, next) -> 
		event.rsvp(req, res, next)
	apiRouter.get '/event/pdf', event.get_pdf
	apiRouter.get '/event/addresses', event.addresses

	# # Feed
	apiRouter.post '/feed', feed.add
	apiRouter.put '/feed', feed.upd
	apiRouter.delete '/feed', feed.del
	apiRouter.post '/feed/delete', feed.del
	apiRouter.get '/feed', feed.get
	apiRouter.get '/feed/updates', feed.get_updates
	# apiRouter.get '/feed/count', feed.count
	# apiRouter.get '/feed/item', feed.get_item
	apiRouter.post '/feed/comment', feed.add_comment
	apiRouter.get '/feed/comments', feed.get_comments
	apiRouter.post '/feed/like', feed.add_like
	apiRouter.delete '/feed/like', feed.del_like
	apiRouter.post '/feed/like/delete', feed.del_like

	# # Ticket Transfers
	apiRouter.post '/transfer', transfer.add
	apiRouter.all '/transfer/ipn', transfer.ipn
	apiRouter.get '/transfer/return', transfer.pdt
	apiRouter.get '/transfer/status', transfer.status

	# # RaceTasks
	apiRouter.post '/racetask', racetask.add
	apiRouter.put '/racetask', racetask.upd
	apiRouter.get '/racetasks', racetask.search
	apiRouter.get '/racetask/submissions', racetask.get_submissions
	apiRouter.get '/racetask/all_submissions', racetask.get_all_submissions

	# # Places
	apiRouter.post '/place', places.add
	apiRouter.delete '/place', places.del
	apiRouter.put '/place', places.upd
	apiRouter.get '/places', places.get
	apiRouter.get '/place_types', places.get_types

	# # # Screens
	apiRouter.get '/screens', screens.get
	apiRouter.put '/screens', screens.update
	apiRouter.post '/screens/reset', screens.reset
	apiRouter.get '/screens/reset', screens.get_reset_time

	# # # Checkin
	apiRouter.get '/checkins', checkins.get
	apiRouter.get '/checkins/recent', checkins.get_recent


	# # Admin
	# # Anything in the /admin path will pull the users capabilities
	# # other paths require req.query.admin to be passed as true for
	# # capabilities to be grabbed automatically
	apiRouter.all '/admin/*', admin.get_capabilities
	apiRouter.get '/admin/download', admin.download
	apiRouter.post '/admin/helpscout', admin.hs_convo
	apiRouter.get '/admin/schedule', admin.schedule
	apiRouter.get '/admin/academies', admin.academies
	apiRouter.get '/admin/ambassadors', admin.ambassadors
	apiRouter.get '/admin/ambassador_accept', admin.ambassador_accept
	apiRouter.get '/admin/ambassador_reject', admin.ambassador_reject
	apiRouter.get '/admin/user_export', admin.export
	apiRouter.get '/admin/profile_stat', admin.export_profile_stat
	apiRouter.get '/admin/transfer_export', admin.transfer_export
	apiRouter.get '/admin/locations', admin.process_locations
	apiRouter.get '/admin/fixattendees', admin.process_attendees
	apiRouter.get '/admin/events', event.get_admin
	apiRouter.post '/admin/event-export', admin.event_export
	apiRouter.get '/admin/event_accept', event.accept
	apiRouter.get '/admin/transfers', admin.transfers
	apiRouter.get '/admin/event_reject', event.reject
	apiRouter.post '/admin/notification', notifications.send
	apiRouter.get '/admin/notification', notifications.get_count
	apiRouter.post '/admin/rate', admin.rate
	apiRouter.post '/admin/kind', admin.kind

	# apiRouter.get '/fire', (req, res, next) ->
	# 	process.fire.database().ref().child('/presales').push({
	# 		created_at: (+ new Date()) + 21600000,
	# 		name: 'Lindsay Stevens',
	# 		user_id: 378
	# 	})
	# 	process.fire.database().ref().child('/presales').push({
	# 		created_at: (+ new Date()) + 21600000,
	# 		name: 'Ron Frank',
	# 		user_id: 379
	# 	})
	# 	process.fire.database().ref().child('/presales').push({
	# 		created_at: (+ new Date()) + 21600000,
	# 		name: 'Jen Bridges',
	# 		user_id: 391
	# 	})
	# 	next()

	apiRouter.get '/fixpurchasers', (req, res, next) ->
		knex
		.select('email', 'users.user_id')
		.count('ticket_id as quantity')
		.from('tickets')
		.leftJoin('users', 'tickets.purchaser_id', 'users.user_id')
		.whereRaw("status!='canceled' AND tickets.year='2018'")
		.groupBy('purchaser_id')
		.then (rsp) ->
			out = { numAll: 0, addresses: [], numOut: 0}

			async.eachSeries rsp, (v, cb) ->
				[User, Users] = require('../models/users')
				if existingPurchasers.indexOf(v.email) is -1
					User.forge({ user_id: v.user_id})
					.fetch().then (user) ->
						obj = {
							user_id: user.get('user_id'),
							email: v.email,
							quantity: v.quantity,
							price: (v.quantity*707),
							tickets: if (+v.quantity > 1) then 'tickets' else 'ticket'
						}
						out.addresses.push(obj)
						tk (user.get('first_name')+' '+user.get('last_name')+': '+user.get('email'))
						user.addToList('WDS 2018 Purchasers')
						.then ->
							tk 'sent'
							promo = 'TicketReceipt'
							subject = "Aw yeah! Your purchase was successful!"
							params =
								quantity: obj.quantity
								price: obj.price
								claim_url: 'https://worlddominationsummit.com/assign/'+@get('hash')
								tickets: obj.tickets
							user.sendEmail(promo, subject, params)
							cb()
				else
					cb()
			, ->
				out.numAll = rsp.length
				out.numOut = out.addresses.length
				res.send(out);

	apiRouter.get '/fixattendees', (req, res, next) ->
		knex
		.select('email', 'users.user_id')
		.count('ticket_id as num')
		.from('tickets')
		.leftJoin('users', 'tickets.user_id', 'users.user_id')
		.whereRaw("status='active' AND tickets.year='2018'")
		.groupBy('user_id')
		.then (rsp) ->
			out = { numAll: 0, addresses: [], numOut: 0}

			rsp.forEach((v) -> 
				if existingAttendes.indexOf(v.email) is -1
					out.addresses.push(v.email)
			)
			out.numAll = rsp.length
			out.numOut = out.addresses.length
			res.send(out);

	# apiRouter.get '/fixandroid', (req, res, next) ->
	# 	async = require('async')
	# 	tk 'fix android'
	# 	[Transaction, Transactions] = require('../models/transactions')
	# 	Transactions.forge().query (qb) ->
	# 		qb.where('product_id', '9')
	# 		qb.where('created_at', '>', '2017-07-01 00:00:00')
	# 	.fetch()
	# 	.then (rsp) ->
	# 		tk rsp.models.length
	# 		[User, Users] = require('../models/users')
	# 		async.each rsp.models, (row, cb) ->
	# 			tk row.get('user_id')
	# 			User.forge
	# 				user_id: row.get('user_id')
	# 			.fetch()
	# 			.then (user) ->
	# 				user.registerTicket(row.get('quantity'), row.get('paid_amount'))
	# 				.then (tickets) ->
	# 					transaction.set('meta', JSON.stringify(tickets))
	# 					transaction.save()
	# 					cb()
	# 		, ->
	# 			next()


	apiRouter.get '/admin/stories', (req, res, next) ->
		knex = require('knex')(process.db)
		knex
		.select('first_name', 'last_name', 'email', 'stories.phone', 'story')
		.from('stories')
		.leftJoin('users', 'users.user_id', 'stories.user_id')
		.then (rsp) ->
			res.r.stories = rsp
			next()


	apiRouter.get 'tpl', (req, res, next) ->
		get_templates = require('../processors/templater')
		get_templates {}, 'pages', (tpls) ->
			get_templates tpls, '_content', (tpls) ->
				res.r.tpl = tpls['pages_'+req.query.tpl]
				next()

	# Finish
	apiRouter.all '/*', handler.finish
module.exports = routes
