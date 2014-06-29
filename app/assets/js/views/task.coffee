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

	submitPhoto: (e) ->
		e.stopPropagation()
		task = @options.task
		slug = task.slug
		task_id = task.task_id
		frame = $('#race_upload_frame').contents()

		## Loading Screen
		#$('#loading').show()
		#$('#loading-heading').html('Capturing...')
		#$.scrollTo(0)
		$('#task_upload', frame).change ->
			if $(this).val().length
				$('#race').hide()
				$('#loading').show()
				$('#loading-heading').html('Uploading...')
				$.scrollTo(0)
				$('#task_user_id', frame).val(ap.me.get('user_id'))
				$('#task_cur_points', frame).val(ap.me.get('points'))
				$('#task_slug', frame).val(slug)
				$('#task_id', frame).val(task_id)
				$('#race_form', frame).submit()
		$('#file-upload-button', frame).click()

