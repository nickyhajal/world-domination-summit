ap.Views.admin_add_racetask = XView.extend
	events: 
		'submit #admin-add-racetask': 'addRaceTask_submit'
	initialize: ->
		@initRender()
	addRaceTask_submit: (e) ->
		e.preventDefault()
		el = $(e.currentTarget)
		post = el.formToJson()
		btn = _.btn($('.button', el), 'Adding...', 'Added!')
		ap.api 'post racetask', post, (rsp) ->
			btn.finish()
			setTimeout ->
				ap.navigate('admin/racetasks')
			, 200