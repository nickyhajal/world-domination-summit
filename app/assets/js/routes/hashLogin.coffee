ap.Routes.hashLogin = () ->
	hash = location.pathname.substr(1)
	ap.goTo 'empty', {}, ->
		ap.api 'post user/login', {hash: hash}, (rsp) ->
			if rsp.loggedin
				ap.login(rsp.me)
				_.whenReady 'assets', =>
					ap.navigate('hub')
			else
				ap.navigate('not-authorized')