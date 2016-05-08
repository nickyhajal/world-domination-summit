ap.Views.admin_add_academy = XView.extend
	events:
		'submit #admin-add-event': 'addEvent_submit'

	initialize: ->
		@initRender()
	addEvent_submit: (e) ->
		e.preventDefault()
		el = $(e.currentTarget)
		post = el.formToJson()
		post.type = 'academy'
		post.who = ''
		post.active = '1'
		btn = _.btn($('.button', el), 'Adding...', 'Added!')
		ap.api 'post event', post, (rsp) ->
			ap.events = rsp.events
			btn.finish()
			setTimeout ->
				ap.navigate('admin/academies')
			, 200