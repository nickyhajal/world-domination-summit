# Pre-Route Code
ap.Routes.before = ->
	path = location.pathname.substr(1)
	if path.length and @protect.indexOf(path) > -1
		unless ap.protect()
			@stop()
			setTimeout ->
				ap.login_redirect = path
				ap.navigate('login')
			, 5
			return false
