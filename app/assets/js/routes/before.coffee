# Pre-Route Code
ap.Routes.before = ->
	path = location.pathname.substr(1)
	pdetails = false
	if path.length
		for p in @protect
			if p is path or (p.path? and p.path is path)
				pdetails = p
		if pdetails
			unless ap.protect(pdetails)
				@stop()
				setTimeout ->
					redirect = pdetails.redirect ? 'login'
					ap.login_redirect = path
					ap.navigate(redirect)
					ap.loading(false)
					$('html').removeClass('hide-counter')
				, 5
				return false
