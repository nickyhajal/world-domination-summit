ap.Views.admin_rate = XView.extend
	events: 
		'click .rate-button': 'rate'
	on: -1
	preload_on: 0
	initialize: ->
		theTask = false
		_.whenReady 'users', =>
			@initRender()

	rendered: ->	
		ap.api 'get racetask/submissions', {}, (rsp) =>
			@submissions = rsp.submissions
			@preload()
			@showNext()

	preload: ->
		end = @preload_on + 5
		for i in [@preload_on..end]
			if @submissions[i]?
				sub = @submissions[i]
				elm = $('<div>').html(@get_html(sub))
				$('#preload').append(elm)
				@preload_on = i

	showNext: ->
		@on += 1
		sub = @submissions[@on]
		task = {}
		for t in ap.tasks
			if t.slug is sub.slug
				task = t
		@active = sub
		user = ap.Users.get(sub.user_id)
		$('#rate-task').html(task.task+' <div id="rate-attendee"></div>')
		$('#rate-content').html(@get_html(sub, user))
		$('#rate-attendee').html 'Submitted by: 
			<a href="/~'+user.get('user_name')+'" target="_blank">'+user.get('first_name')+' '+user.get('last_name')+'</a>
		'


	get_html: (sub, user) ->
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


	rate: (e) ->
		e.preventDefault()
		el = $(e.currentTarget)
		rating = el.data('rating')
		if rating isnt 0
			post = 
				rating: el.data('rating')
				ach_id: @active.ach_id
				submission_id: @active.submission_id
			ap.api 'post admin/rate', post, (rsp) =>
				@showNext()
		else
			@showNext()


