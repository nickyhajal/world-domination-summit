Shelf = require('./shelf')
async = require('async')
Q = require('q')
juice = require('juice')
_s = require('underscore.string')
apn = require('apn')
gcm = require('node-gcm')

[Device, Devices] = require './devices'

Notification = Shelf.Model.extend
	tableName: 'notifications'
	idAttribute: 'notification_id'
	hasTimestamps: true
	permittedAttributes: [
		'notification_id', 'user_id', 'notification', 'read', 'emailed'
	]
	initialize: ->
		this.on 'created', this.created, this
	created: ->
		user_id = @get('user_id')
		Notifications::notificationText(this, false, true)
		.then (ntrsp) =>
			str = ntrsp[0]
			user = ntrsp[1]
			Devices.forge()
			.query('where', 'user_id', user_id)
			.query('where', 'type', 'ios')
			.fetch()
			.then (rsp) =>
				devices = rsp.models
				tokens = []
				note = new apn.Notification()
				note.alert = str
				note.payload = {content: @get('content'), type: @get('type'), link: @get('link')}
				note.badge = 3;
				note.expiry = Math.floor(Date.now() / 1000) + 3600;
				for device in devices
					d = new apn.Device(device.get('token'))
					tk d
					tk process.APN.pushNotification(note, d)
			Devices.forge()
			.query('where', 'user_id', user_id)
			.query('where', 'type', 'and')
			.fetch()
			.then (rsp) =>
				devices = rsp.models
				tokens = []
				for device in devices
					tokens.push device.get('token')
				if tokens.length
					message = new gcm.Message
						collapseKey: "WDS Notifications"
						data:
							title: "WDS App"
							message: str
							id: @get("notification_id")
							user_id: user.get('user_id')
							content: @get('content')
							type: @get('type')
							link: @get('link')
					# tk "GCM SEND:"
					process.gcmSender.send message, tokens, (err, result) ->
						# if err
						# 	# tk "GCM ERR"
						# 	# console.error err
						# else
						# 	tk "GCM SENT"
						# 	tk result

Notifications = Shelf.Collection.extend
	model: Notification
	process: ->
		[User, Users] = require './users'
		now = (+(new Date())) / 1000
		Notifications.forge()
		.query('where', 'emailed', '0')
		.query('where', 'read', '0')
		.query('groupBy', 'user_id')
		.fetch()
		.then (rsp) =>
			sentCount = 0
			async.each rsp.models, (check, cb) =>
				user_id = check.get('user_id')
				User.forge({user_id: user_id})
				.fetch()
				.then (user) =>
					interval = user.get('notification_interval')
					if interval > 0 and (user.get('last_notification') + interval) < now
						user.set
							last_notification: now
						.save()
						.then =>
							Notifications.forge()
							.query('where', 'emailed', '0')
							.query('where', 'read', '0')
							.query('where', 'user_id', user.get('user_id'))
							.fetch()
							.then (rsp) =>
								if rsp.models.length
									html = @notificationHtml(rsp.models)
									.then (html) ->
										async.each rsp.models, (notn, cb) ->
											notn.set('emailed', '1')
											.save()
											.then ->
												cb()
										, ->

											notn_str = if rsp.models.length is 1 then 'notification' else 'notifications'

											user.sendEmail 'notification', rsp.models.length+' new '+notn_str+' from the WDS Community',
												notification_html: html
								else
									cb()
					else
						cb()
			, ->
				tk 'Done sending notifications to '+sentCount+' users'
				setTimeout ->
					Notifications::process()
				, 1800000
	notificationText: (notn, html = true, inc_user = false) ->
		[User, Users] = require './users'
		dfr = Q.defer()
		data = JSON.parse(notn.get('content'))
		link = notn.get('link')
		text = ''

		switch notn.get('type')
			when 'feed_like'
				User.forge({user_id: data.liker_id})
				.fetch()
				.then (user) ->
					if html
						link = '<a href="http://worlddominationsummit.com'+link+'">'
						text += link+'<img src="'+user.getPic()+'" class="notn-av"/></a></td><td>'
						text += link+user.get('first_name')+' '+user.get('last_name')+' liked your post!</a>'
						text += '</a>'
					else
						text += user.get('first_name')+' '+user.get('last_name')+' liked your post!'
					if inc_user then dfr.resolve([text, user]) else dfr.resolve(text)

			when 'feed_comment'
				User.forge({user_id: data.commenter_id})
				.fetch()
				.then (user) ->
					if html
						link = '<a href="http://worlddominationsummit.com'+link+'">'
						text += link+'<img src="'+user.getPic()+'" class="notn-av"/></a></td><td>'
						text += link+user.get('first_name')+' '+user.get('last_name')+' commented on your post!</a>'
						text += '</a>'
					else
						text += user.get('first_name')+' '+user.get('last_name')+' commented on your post!'
					if inc_user then dfr.resolve([text, user]) else dfr.resolve(text)
			when 'connected'
				User.forge({user_id: data.from_id})
				.fetch()
				.then (user) ->
					if html
						link = '<a href="http://worlddominationsummit.com/'+link+'">'
						text += link+'<img src="'+user.getPic()+'" class="notn-av"/></a></td><td>'
						text += link+user.get('first_name')+' '+user.get('last_name')+' friended you!</a>'
						text += '</a>'
					else
						text += user.get('first_name')+' '+user.get('last_name')+' friended you!'
					if inc_user then dfr.resolve([text, user]) else dfr.resolve(text)

		return dfr.promise

	notificationHtml: (notns) ->
		html = '
		<style type="text/css">
			.notn-av {
				width:40px;
				height: 40px;
			}
			.notn-table {
				width: 530px;
			}
			.notn-table a {
				display:block;
				color: #E27F1C;
				font-weight:bold;
			}
			.notn-table td {
				padding:2px 5px 2px 15px;
			}
			.notn-table tr {
				background:#F2F2EA;
				border-bottom:1px solid #fff;
			}
			.notn-table tr td:first-of-type {
				padding:5px 5px 2px 5px;
				width: 30px;
			}
			.freqmsg {
				font-size: 8pt;
				margin-top: 24px;
				padding: 15px;
				line-height: 142%;
				background:#F2F2EA;
			}
		</style>
		<table class="notn-table">'
		dfr = Q.defer()
		async.each notns, (notn, cb) =>
			@notificationText(notn)
			.then (text) ->
				html += '<tr><td>'+text+'</td></tr>'
				cb()
		, ->
			html += '</table><div class="freqmsg">
				You can change the frequency or turn off these
				notifications at
				<a href="http://worlddominationsummit.com/settings">http://worlddominationsummit.com/settings</a>
				</div>
			'

			juice.juiceContent html,
				url: 'http://worlddominationsummit.com'
			, (err, html) ->
				dfr.resolve(html)
		return dfr.promise






module.exports = [Notification, Notifications]