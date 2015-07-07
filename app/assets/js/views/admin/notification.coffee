ap.Views.admin_notification = XView.extend
	ticketTimo: 0
	events:
		'submit #admin-confirm-notification': 'do_submit'
	initialize: ->
		@initRender()

	rendered: ->

	do_submit: (e) ->
		e.preventDefault()
		el = $(e.currentTarget)
		btn = _.btn($('.button', el), 'Getting...', 'Got it!')
		form = el.formToJson()

		ap.api 'get admin/notification', form, (rsp) =>
			btn.finish()
