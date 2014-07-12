ap.Views.admin_race_review = XView.extend
	events: 
		'click .rate-button': 'rate'
	on: -1
	preload_on: 0
	initialize: ->
		theTask = false
		_.whenReady 'users', =>
			@initRender()

	rendered: ->	
		html = ''
		ap.api 'get racetask/all_submissions', {}, (rsp) =>
			for sub in rsp.submissions
				tk sub
				html += @get_html(sub)
			$('#review-shell').html(html)

	get_html: (sub, user) ->
		if sub.type is 'ig'
			html = '
			<video width="600" height="400" controls>
			  <source src="'+sub.ext+'" type="video/mp4">
			Your browser does not support the video tag.
			</video>'
		else
			user = ap.Users.get(sub.user_id)
			if user?
				url = user.get('user_name')+'/'+sub.slug+'/w600_'+sub.hash+'.'+sub.ext
				html = '<img src="/images/race_submissions/'+url+'">'

		return html


