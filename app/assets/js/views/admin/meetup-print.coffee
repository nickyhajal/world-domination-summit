ap.Views.admin_meetup_print = XView.extend
	ticketTimo: 0
	events:
		'submit #admin-get-pdf': 'do_submit'
	initialize: ->
		@initRender()

	rendered: ->

	do_submit: (e) ->
		e.preventDefault()
		el = $(e.currentTarget)
		btn = _.btn($('.button', el), 'Getting...', 'Got it!')
		form = el.formToJson()
		ap.api 'get event/pdf', form, (rsp) =>
			location.href = '/meetups-printable.pdf'
			btn.finish()
