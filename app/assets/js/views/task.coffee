ap.Views.task = XView.extend
	events: 
		'click #camera-button': 'submitPhoto'
		'submit #instagram-form': 'submitInstagram'
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
				@options.task.how_to = '
					Post a video on instagram and include the hashtags 
					<b>#wds2014</b> and <b>#'+task.slug.replace('-', '')+'</b>
					<br><br>
				'
				if ap.me.get('instagram')?.length
					@options.task.how_to += '
						Make sure to post from your instagram account: <b>'+ap.me.get('instagram')+'</b>
					'
				else
					@options.task.how_to += '
						<div id="ig-form-shell"><h5>WAIT: You haven\'t connected your Instagram account!</h5>
						Add it below <b>before</b> you submit your video.
						<form id="instagram-form" action="post">
							<input type="text" name="instagram" class="model-me" placeholder="Instagram Username">
							<input type="submit" value="Save">
						</form></div>
					'

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
		@getMedia()

	submitInstagram: (e)->
		e.preventDefault()
		btn = _.btn($('input[type="submit"]', '#instagram-form'), 'Saving...', 'Saved!')
		ap.me.save null,
			success: ->
				btn.finish()
				form = $('#ig-form-shell').html '
					<div><br>Make sure to post from your instagram account: <b>'+ap.me.get('instagram')+'</b></div>
				'

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
			$('.task-how-to-complete').html(msg).addClass('achieved')
			@getMedia()

	getMedia: ->
		ap.api 'get user/task', {task_slug: @options.task.slug}, (rsp) =>
			html = ''
			if rsp.mine
				html += '<h4>Submitted By You</h4>'
				for sub in rsp.mine
					html += @getSubHtml(sub)
			if rsp.examples
				html += '<h4>Top Submissions By Other WDSers</h4>'
				for sub in rsp.examples
					html += @getSubHtml(sub)
			$('#task-more').html(html)

	getSubHtml: (sub) ->
		if sub.type is 'ig'
			html = '
			<video width="600" height="400" controls>
			  <source src="'+sub.ext+'" type="video/mp4">
			Your browser does not support the video tag.
			</video>'
		else
			user = ap.Users.get(sub.user_id)
			url = user.get('user_name')+'/'+sub.slug+'/w600_'+sub.hash+'.'+sub.ext
			html = '<img src="/images/race_submissions/'+url+'">'


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
	achs = []
	for ach in rsp.achievements
		achs.push
			task_id: ach.t
			custom_points: ach.c
			add_points: ach.a
	ap.achievements = achs
	$('#loading').hide()
	ap.currentView.checkCompleted()
