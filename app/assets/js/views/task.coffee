ap.Views.task = XView.extend
	events: 
		'click #camera-button': 'submitPhoto'
	initialize: ->
		@options.sidebar = 'tasks'
		_.whenReady 'tasks', =>
			for task in ap.tasks
				if task.slug is @options.task_slug
					@options.task = task
			task = @options.task
			if task.type is 'auto'
				@options.task.how_to = 'Our system will automatically issue your points when this task is completed.'
			else if task.type is 'video'
				@options.task.how_to = 'Post a video on instagram and include the hashtags #wds2014 and #'+task.slug.replace('-', '')
			else if task.type is 'photo'
				if window.orientation?
					@options.task.how_to = '<div class="task-photo-device">
						Take a photo of yourself completing the challenge below!
					'
				else 
					@options.task.how_to = '<div class="task-photo-device">
						Submit a photo of yourself completing the challenge below!
					'
				@options.task.how_to += '
					<a href="#" class="button" id="camera-button">Take Photo Now</a>
					<iframe id="race_upload_frame" src="/upload-race"></iframe>
				</div>
				'

			@options.out = _.template @options.out, @options.task
			@initRender()

	rendered: ->
		if not @options.task.note.length
			$('.task-explanation').remove()
		@checkCompleted()

	checkCompleted: ->
		task = @options.task
		task_id = @options.task.racetask_id
		achieved = ap.me.achieved(task_id)
		if achieved
			points = task.points
			if achieved.custom_points > 0
				points = +achieved.custom_points
			if achieved.add_points
				points += +achieved.add_points
			if points > 1
				points = points+' points'
			else
				points = points+' point'
			msg = 'You completed this challenge and earned '+points+'!'
			$('#challenge-title').html('Challenge Completed!').addClass('achieved')
			$('.task-detail-block').addClass('achieved')
			$('#task-completed-message').html(msg).addClass('achieved')

	submitPhoto: (e) ->
		e.stopPropagation()
		e.preventDefault()
		task = @options.task
		slug = task.slug
		task_id = task.racetask_id
		frame = $('#race_upload_frame').contents()

		$('#file-upload-button', frame).change ->
			if $(this).val().length
				$('#loading').show()
				$.scrollTo(0)
				$('#task_user_id', frame).val(ap.me.get('user_id'))
				$('#task_cur_points', frame).val(ap.me.get('points'))
				$('#task_slug', frame).val(slug)
				$('#task_id', frame).val(task_id)
				$('#race_form', frame).submit()

		$('#file-upload-button', frame).click()

ap.race_submission_success = (rsp) ->
	ap.achievements = rsp.achievements
	$('#loading').hide()
	ap.currentView.checkCompleted()
