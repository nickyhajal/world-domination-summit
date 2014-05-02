###

	Used to import from database prior to 2014
	
###


[User, Users] = require('./models/users')
[Ticket, Tickets] = require './models/tickets'
Q = require('q')
fs = require('fs')


each = (set, action, inx = 0) ->
	dfr = Q.defer()
	if set[inx]?
		action(set[inx])
		each(set, action, (inx+1))
	else
		dfr.resolve()
	return dfr.promise

fs.readFile __dirname + '/export.json', "utf-8", (err, data) ->
	data = JSON.parse(data)
	each data.users, (user) ->
		user = User.forge(user)
		user
		.off('saving')
		.off('created')
		.off('creating')
		.off('saved')
		.save(null, {method: 'insert'})
		.then ->
			x = 0
		, (err) ->
			tk err
	each data.tickets, (ticket) ->
		Ticket.forge
			user_id: ticket.user_id
			year: ''+ticket.year
			eventbrite_id: 'IMPORT_'+ticket.year+'_'+ticket.user_id
			status: 'active'
		.save(null, {method: 'insert'})
		.then ->
			x = 0
		, (err) ->
			tk err
