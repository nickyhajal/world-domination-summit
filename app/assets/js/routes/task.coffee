ap.Routes.task = (task) ->
	_.whenReady 'tpls', =>
		ap.goTo('task', {task_slug: task})

