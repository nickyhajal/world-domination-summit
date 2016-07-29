ap.Views.admin_notification = XView.extend
	ticketTimo: 0
	events:
		'submit #admin-confirm-notification': 'do_submit'
	initialize: ->
		ap.api 'get admin/events', {types: ['academy', 'meetup', 'activity', 'spark_session']}, (rsp) =>
			ehtml = ''
			evs = _.sortBy(rsp.events, (ev) -> [ev.type, ev.what])
			ehtml += '<option value="all">All</option>'
			for ev in evs
				type = _.titleize(ev.type.replace('_', ' '))
				ehtml += '<option value="'+ev.event_id+'">'+type+': '+_.truncate(ev.what, 45)+'</option>'
			@out = _.template @options.out, {events: ehtml}
			@initRender()

	rendered: ->
		@getCount()
		$('.select2', @el).change @getCount

	getCount: ->
		$f = $('#admin-confirm-notification')
		form = $f.formToJson()
		ap.api 'get admin/notification', form, (rsp) =>
			$('#notn-count').html(rsp.user_count)
	do_submit: (e) ->
		e.preventDefault()
		el = $(e.currentTarget)
		btn = _.btn($('.button', el), 'Checking...', 'Got it!')
		form = el.formToJson()

		ap.api 'get admin/notification', form, (rsp) =>
			btn.finish()
			html = '<div class="notification-confirm-head">Are you sure you want to send this notification to <b>'+rsp.user_count+' attendees</b> over <b>'+rsp.device_count+' devices</b>?</div>'
			html += '<h4>Notification</h4><p>'+form.notification_text+'</p>'
			html += '<h4>Dispatch Post</h4><p>'+form.dispatch_text+'</p>'
			html += '<a href="#" class="button">I\'m sure, send it!</a>'
			$('.modal-confirm-content').html(html)
			ap.Modals.open('confirm')
			$('.modal-confirm-content .button').click ->
				send_btn = _.btn($(this), 'Sending...', 'Sent!')
				ap.api 'post admin/notification', form, (rsp) =>
					send_btn.finish()
				return false
