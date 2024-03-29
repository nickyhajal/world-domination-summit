Shelf = require('./shelf')
async = require('async')
Q = require('q')
juice = require('juice')
_s = require('underscore.string')
apn = require('apn')

# https://github.com/node-apn/node-apn/wiki/Preparing-Certificates

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
		this.on 'saving', this.saving, this
		this.on 'fetched', this.fetched, this
	saving: ->
		title = @get('title')
		if title? and (title is '0' or title is 0 or title is '')
			@set('title', null)

	fetched: ->
		title = @get('title')
		if title? and (title is '0' or title is 0 or title is '')
			@set('title', null)

	created: ->
		user_id = @get('user_id')
		tk 'Create notification for: '+user_id
		[User, Users] = require './users'
		if user_id is 9883
			user_id = 176
		User.forge
			user_id: user_id
		.processNotifications()
		.then (count) =>
			Notifications::notificationText(this, false, true)
			.then (ntrsp) =>
				if count < 1
					count = -1
				str = ntrsp[0]
				user = ntrsp[1]
				Devices.forge()
				.query('where', 'user_id', user_id)
				.query('where', 'type', 'ios')
				.query('where', 'active', '1')
				.fetch()
				.then (rsp) =>
					devices = rsp.models
					tk 'ios #: '+devices.length
					tokens = []
					note = new apn.Notification()
					note.alert = { body: str }
					note.payload = {content: @get('content'), type: @get('type'), link: @get('link')}
					if @get('title')?.length
						note.payload.title = @get('title')
						note.alert.title = @get('title')
					note.badge = -1
					note.sound = 'wds_notify.wav'
					note.topic = 'com.worlddominationsummit.wdsios'
					note.expiry = Math.floor(Date.now() / 1000) + 3600;
					for device in devices
						# d = new apn.Device(device.get('token'))
						tk 'sending to'+device.get('token')
						process.APN.send(note, device.get('token')).then (response) ->
							tk 'rs: ', response
							response.sent.forEach (token) -> 
								console.log('sent to', token)
							response.failed.forEach (failure) ->
								if (failure.error)
									tk 'transport error', failure.device, failure.error
								else
									tk 'transport error', failure.device, failure.response, failure.status
				Devices.forge()
				.query('where', 'user_id', user_id)
				.query('where', 'type', 'and')
				.query('where', 'active', '1')
				.fetch()
				.then (rsp) =>
					devices = rsp.models
					tk 'and #: '+devices.length
					tokens = []
					for device in devices
						token = device.get('token')
						message = {
							to: token,
							collapse_key: "WDS Notifications"
							notification:
								title: "WDS App"
								body: str
							data:
								title: "WDS App"
								id: @get("notification_id")
								user_id: user.get('user_id')
								body: str
								content: @get('content')
								type: @get('type')
								link: @get('link')
						}
						tk "FCM SEND:"
						tk token
						process.fcm.send message, (err, result) ->
							if err
								tk "FCM ERR"
								console.error err
							else
								tk err
								tk result
								tk "FCM SENT FROM MODEL"
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
			when 'prize'
				User.forge({user_id: data.user_id})
				.fetch()
				.then (user) ->
					text = "Awesome! You just received a prize playing the Unconventional Race!"
					if inc_user then dfr.resolve([text, user]) else dfr.resolve(text)
			when 'feed_like'
				tk "liker: "+data.liker_id
				User.forge({user_id: data.liker_id})
				.fetch()
				.then (user) ->
					if user
						if html
							link = '<a href="http://worlddominationsummit.com'+link+'">'
							text += link+'<img src="'+user.getPic()+'" class="notn-av"/></a></td><td>'
							text += link+user.get('first_name')+' '+user.get('last_name')+' liked your post!</a>'
							text += '</a>'
						else
							text += user.get('first_name')+' '+user.get('last_name')+' liked your post!'
						if inc_user then dfr.resolve([text, user]) else dfr.resolve(text)
					else
						dfr.resolve(false)
			when 'feed_comment'
				tk "cmntr: "+data.commenter_id
				User.forge({user_id: data.commenter_id})
				.fetch()
				.then (user) ->
					if user
						if html
							link = '<a href="http://worlddominationsummit.com'+link+'">'
							text += link+'<img src="'+user.getPic()+'" class="notn-av"/></a></td><td>'
							text += link+user.get('first_name')+' '+user.get('last_name')+' commented on your post!</a>'
							text += '</a>'
						else
							text += user.get('first_name')+' '+user.get('last_name')+' commented on your post!'
						if inc_user then dfr.resolve([text, user]) else dfr.resolve(text)
					else
						dfr.resolve false
			when 'feed_comment_on_commented'
				tk "cmtn_cmntr: "+data.commenter_id
				User.forge({user_id: data.commenter_id})
				.fetch()
				.then (user) ->
					if user
						if html
							link = '<a href="http://worlddominationsummit.com'+link+'">'
							text += link+'<img src="'+user.getPic()+'" class="notn-av"/></a></td><td>'
							text += link+user.get('first_name')+' '+user.get('last_name')+' commented on a discuss you\'re part of.</a>'
							text += '</a>'
						else
							text += user.get('first_name')+' '+user.get('last_name')+' commented on a discussion you\'re part of.'
						if inc_user then dfr.resolve([text, user]) else dfr.resolve(text)
					else
						dfr.resolve false
			when 'feed_comment_on_liked'
				User.forge({user_id: data.commenter_id})
				.fetch()
				.then (user) ->
					if user
						if html
							link = '<a href="http://worlddominationsummit.com'+link+'">'
							text += link+'<img src="'+user.getPic()+'" class="notn-av"/></a></td><td>'
							text += link+user.get('first_name')+' '+user.get('last_name')+' commented on a discussion you liked</a>'
							text += '</a>'
						else
							text += user.get('first_name')+' '+user.get('last_name')+' commented on a discussion you liked.'
						if inc_user then dfr.resolve([text, user]) else dfr.resolve(text)
					else
						dfr.resolve false
			when 'feed_for_event_host'
				User.forge({user_id: data.commenter_id})
				.fetch()
				.then (user) ->
					if user
						if html
							link = '<a href="http://worlddominationsummit.com'+link+'">'
							text += link+'<img src="'+user.getPic()+'" class="notn-av"/></a></td><td>'
							text += link+user.get('first_name')+' '+user.get('last_name')+'  posted to your event dispatch.</a>'
							text += '</a>'
						else
							text += user.get('first_name')+' '+user.get('last_name')+' posted to your event dispatch.'
						if inc_user then dfr.resolve([text, user]) else dfr.resolve(text)
					else
						dfr.resolve false
			when 'connected'
				User.forge({user_id: data.from_id})
				.fetch()
				.then (user) ->
					if user
						if html
							link = '<a href="http://worlddominationsummit.com/'+link+'">'
							text += link+'<img src="'+user.getPic()+'" class="notn-av"/></a></td><td>'
							text += link+user.get('first_name')+' '+user.get('last_name')+' friended you!</a>'
							text += '</a>'
						else
							text += user.get('first_name')+' '+user.get('last_name')+' friended you!'
						if inc_user then dfr.resolve([text, user]) else dfr.resolve(text)
					else
						dfr.resolve(false)

			when 'message'
				User.forge({user_id: data.from_id})
				.fetch()
				.then (user) ->
					if user
						if html
							link = '<a href="http://worlddominationsummit.com/'+link+'">'
							text += link+'<img src="'+user.getPic()+'" class="notn-av"/></a></td><td>'
							text += link+user.get('first_name')+' '+user.get('last_name')+' sent you a message!</a>'
							text += '</a>'
						else
							text += JSON.parse(notn.get('content')).content_str
						if inc_user then dfr.resolve([text, user]) else dfr.resolve(text)
					else
						dfr.resolve false

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
			if notn.get('type') != 'message'
				@notificationText(notn)
				.then (text) ->
					if text
						html += '<tr><td>'+text+'</td></tr>'
					cb()
			else
				cb()
		, ->
			html += '</table><div class="freqmsg">
				You can change the frequency or turn off these
				notifications at
				<a href="http://worlddominationsummit.com/settings">http://worlddominationsummit.com/settings</a>
				</div>
			'

			juice.juiceResources html,
				url: 'http://worlddominationsummit.com'
			, (err, html) ->
				dfr.resolve(html)
		return dfr.promise






module.exports = [Notification, Notifications]
