ap.Views.admin_event = XView.extend
	ticketTimo: 0
	events: 
		'submit #admin-event-update': 'event_submit'
	initialize: ->
		speaker = event
		ap.api 'get admin/schedule', (rsp) ->
			events = rsp.events
			theEvent = false
			for ev of events
				if +ev.event_id is +@options.extra
					theEvent = ev
		@options.out = _.template @options.out, theEvent
		@event = theEvent
		@initRender()

	rendered: ->
		$('select[name="type"]').val(@speaker.type)

	event_submit: (e) ->
		e.preventDefault()
		el = $(e.currentTarget)
		btn = _.btn($('.button', el), 'Saving...', 'Saved!')
		form = el.formToJson()
		ap.api 'put event', form, (rsp) ->
			#ap.schedule = rsp.schedule
			btn.finish()
