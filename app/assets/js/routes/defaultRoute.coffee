ap.Routes.defaultRoute = (actions) ->

	# If no action, figure it out
	unless actions
		actions = 'home'
	tk actions
	if actions is 'meetup'
		tk 'hey'
		actions = false
		_.whenReady 'tpls', ->
			tk 'what'
			ap.navigate('meetups')
	else if actions.length is 40
		actions = false
		ap.goTo 'blank', {}, ->
			ap.loading()
			ap.api 'post user/login', {hash: actions}, (rsp) ->
				ap.loaded()
				if rsp.loggedin
					ap.navigate('hub')
				else
					ap.navigate('not-authorized')
	if actions
		ap.goTo(actions)
