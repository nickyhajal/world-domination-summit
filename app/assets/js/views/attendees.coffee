ap.Views.attendees = XView.extend
	events:
		'keyup .search-input': 'keyChange'
		'click #attendee-search-x': 'clearSearch'
	initialize: ->
		_.whenReady 'assets', =>
			@initRender()
	rendered: ->
		if ap.lastAttendeeSearch and ap.lastAttendeeSearch.length
			$('.search-input', $(@el)).val(ap.lastAttendeeSearch).keyup()
		ap.me.getFriends =>
			_.whenReady 'users', =>
				@renderFriends()
	renderFriends: (friends) ->
		shell = $('.search-results')
		if ap.me.get('friends')?.length
			html = '<div id="friends-shell"><h3>Your Friends</h3>'
		for friend in ap.me.get('friends')
			html += @renderFriend(friend)

		if ap.me.get('friended_me')?.length
			html += '<h3>Friended You</h3>'
		for friend in ap.me.get('friended_me')
			html += @renderFriend(friend)

		if ap.me.get('similar')?.length
			html += '<h3>Similar To You</h3>'
		for attendee in ap.me.get('similar')
			html += @renderFriend(attendee)
		html += '</div>'
		shell.html(html)

	renderFriend: (friend) ->
		html = ''
		atn = ap.Users.get(friend)
		if atn? and atn.get('user_id') isnt ap.me.get('user_id')
			html += '
			<a href="~'+atn.get('user_name')+'" class="friend">
				<div class="friend-avatar" style="background:url('+atn.get('pic')+')"></div>
				<div class="friend-name">'+atn.get('first_name')+'<br>'+atn.get('last_name')+'</div>
			</a>'
		return html

	clearSearch: (e) ->
		e.preventDefault()
		$('.search-input', $(@el)).val('').keyup()

	keyChange: (e) ->
		el = $(e.currentTarget)
		val = el.val()
		if val.length
			ap.lastAttendeeSearch = el.val()
			$('#attendee-search-x').show()
		else
			@renderFriends()
			$('#attendee-search-x').hide()
