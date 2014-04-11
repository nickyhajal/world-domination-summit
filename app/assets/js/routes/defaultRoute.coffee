ap.Routes.defaultRoute = (actions) ->

	# If no action, figure it out
	if (actions is '')
		if (ap.authd)
			actions = 'home';
		else
			actions = 'login';
	ap.goTo(actions)
