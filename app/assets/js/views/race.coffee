ap.Views.race = XView.extend
	saveScrollPosition: true
	initialize: ->
		_.whenReady 'ranks', =>
			me = ap.me.attributes
			if not me.rank? and not me.rank
				me.rank = '1921'
			if not me.points? and not me.points
				me.points = '0'
			@options.out = _.template @options.out, ap.me.attributes
			@initRender()
		ap.bindResize('race', => @resize())
	rendered: ->
		_.whenReady 'tasks', =>
			@renderTasks()
			@updateStatus()
	renderTasks: ->
		html = ''
		_.whenReady 'achievements', =>
			sections = ['before-arriving', 'community', 'adventure', 'service']
			sectionNames =
				"before-arriving": "Before Arriving"
				"community": "Community"
				"adventure": "Adventure"
				"service": "Service"
			for section in sections
				html += '<h3>'+sectionNames[section]+'</h3>
					<div class="tasks-label">
						<span class="points-label">Points</span>
						<span class="tasks-label">Task</span>
					</div>
				'

				for task in ap.tasks
					task_class= ''
					if task.section is section
						if ap.me.achieved(task.racetask_id)
							task_class = ' achieved'
						html += '<a href="/task/'+task.slug+'" class="task-row">
							<div class="task-points'+task_class+'">'+task.points+'</div>
							<span class="task-title">'+task.task+'</span>
						</a>'
			$('#race-task-list').html(html)
			@setRowHeights()
	setRowHeights: ->
		$('.task-row').each ->
			$t = $(this)
			$t.css('height', '')
			$t.css('height', $t.outerHeight()+'px')
	resize: ->
		@setRowHeights()
	updateStatus: ->
		ap.api 'get assets', {assets: 'ranks'}, (rsp) ->
			ap.ranks = rsp.ranks
			ap.me.setRank()
			$('span', '#your-points').html(ap.me.get('points'))
			$('span', '#your-rank').html(ap.me.get('rank'))
		setTimeout =>
			@updateStatus()
		, 60000
	whenFinished: ->
		ap.unbindResize('race')

