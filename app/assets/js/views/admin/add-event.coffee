ap.Views.admin_add_event = XView.extend
	events:
		'submit #admin-add-event': 'addEvent_submit'
	initialize: ->
		@initRender()
	addEvent_submit: (e) ->
		e.preventDefault()
		el = $(e.currentTarget)
		post = el.formToJson()
		btn = _.btn($('.button', el), 'Adding...', 'Added!')
		post.price = post.price * 100
		ap.api 'post event', post, (rsp) ->
			ap.events = rsp.events
			btn.finish()
			setTimeout ->
				ap.navigate('admin/schedule')
			, 200