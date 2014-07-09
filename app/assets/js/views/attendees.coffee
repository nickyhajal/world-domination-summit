ap.Views.attendees = XView.extend
	events: 
		'keyup .search-input': 'saveSearch'
	initialize: ->
		_.whenReady 'assets', =>
			@initRender()
	rendered: ->
		if ap.lastAttendeeSearch and ap.lastAttendeeSearch.length
			$('.search-input', $(@el)).val(ap.lastAttendeeSearch).keyup()
		ap.me.getFriends (friends) =>
			renderFriends()
	saveSearch: (e) ->
		el = $(e.currentTarget)
		ap.lastAttendeeSearch = el.val()

