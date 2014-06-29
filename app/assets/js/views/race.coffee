ap.Views.race = XView.extend
	initialize: ->
		_.whenReady 'ranks', =>
			@options.out = _.template @options.out, ap.me.attributes
			@initRender()

	rendered: ->
		_.whenReady 'tasks', =>
			@renderTasks()
	renderTasks: ->
		html = ''
		for task in ap.tasks
			html += '<a href="/task/'+task.slug+'" class="task-row">
				<span class="task-points">'+task.points+'</span>
				<span class="task-title">'+task.task+'</span>
			</a>'
		$('#race-task-list').html(html)
