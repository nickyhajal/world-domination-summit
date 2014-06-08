ap.Views.AttendeeDispatch = XView.extend
	controlsTimo: 0
	initialize: ->
		@render()
	render: ->
		ap.api 'get feed', {user_id: @options.user_id}, (rsp) =>
			html = ''
			for feed in rsp.feed_contents
				html += _.t 'parts_attendee-dispatch-content', feed
			$(@el).html html
