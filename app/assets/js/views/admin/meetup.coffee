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
		window.start = start
		hour = start.format('HH')
		pm = 0
		if hour >= 12
			if hour > 12
				hour -= 12
			if hour < 10
				hour = '0'+hour
			pm = 12
		if hour is '00'
			hour = '12'
		$('select[name="date"]').select2('val', start.format('DD'))
		$('select[name="hour"]').select2('val', hour)
		$('select[name="minute"]').select2('val', start.format('mm'))
		$('select[name="pm"]').select2('val', pm)
		$('select[name="active"]').select2('val', @event.active)
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
