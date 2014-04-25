ap.Routes.profile = ->
	user_name = location.pathname.substr(2)
	ap.api 'get user', {user_name: user_name}, (rsp) ->
		ap.goTo 'profile',
			attendee: new ap.User(rsp.user)
