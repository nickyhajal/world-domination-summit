ap.Views.admin_racetask = XView.extend
	events: 
		'submit #admin-racetask-update': 'update'
	initialize: ->
		theTask = false
		ap.api 'get racetasks', {}, (rsp) =>
			tasks = rsp.racetasks
			for task in tasks
				if +task.racetask_id is +@options.extra
					theTask = task
			@options.out = _.template @options.out, theTask
			@task= theTask
			@initRender()

	rendered: ->
		$('select[name="type"]').select2('val', @task.type) 
		$('select[name="section"]').select2('val', @task.section) 

	update: (e) ->
		e.preventDefault()
		el = $(e.currentTarget)
		btn = _.btn($('.button', el), 'Saving...', 'Saved!')
		form = el.formToJson()
		ap.api 'put racetask', form, (rsp) ->
			btn.finish()
			ap.navigate('admin/racetasks')
