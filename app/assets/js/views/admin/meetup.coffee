ap.Views.admin_meetup = XView.extend
	ticketTimo: 0
	events:
		'submit #admin-meetup-update': 'meetup_submit'
	initialize: ->
		theEvent = false
		ap.api 'get admin/events', {type: 'meetup'}, (rsp) =>
			events = rsp.events
			for ev in events
				if +ev.event_id is +@options.extra
					theEvent = ev
					break
			@options.out = _.template @options.out, theEvent
			@event = theEvent
			@initRender()

	rendered: ->
		start = moment.utc(@event.start)
		end = moment.utc(@event.end)
		hour = start.format('HH')
		end_hour = end.format('HH')
		pm = 0
		if hour >= 12
			if hour > 12
				hour -= 12
			if hour < 10
				hour = '0'+hour
			pm = 12
		if hour is '00'
			hour = '12'
		end_pm = 0
		if end_hour >= 12
			if end_hour > 12
				end_hour -= 12
			if end_hour < 10
				end_hour = '0'+end_hour
			end_pm = 12
		if end_hour is '00'
			end_hour = '12'
		$('select[name="date"]').select2('val', start.format('DD'))
		$('select[name="hour"]').select2('val', hour)
		$('select[name="minute"]').select2('val', start.format('mm'))
		$('select[name="pm"]').select2('val', pm)
		$('select[name="end_hour"]').select2('val', end_hour)
		$('select[name="end_minute"]').select2('val', end.format('mm'))
		$('select[name="end_pm"]').select2('val', end_pm)
		$('select[name="active"]').select2('val', @event.active)
		$('select[name="format"]').select2('val', @event.format)
		if +@event.active
			$('h1 a')
			.html('Back to Meetups')
			.attr('href', '/admin/meetups')

	meetup_submit: (e) ->
		e.preventDefault()
		el = $(e.currentTarget)
		btn = _.btn($('.button', el), 'Saving...', 'Saved!')
		form = el.formToJson()
		ap.api 'put event', form, (rsp) =>
			btn.finish()
			if +@event.active
				ap.navigate('admin/meetups')
			else
				ap.navigate('admin/meetup-review')
