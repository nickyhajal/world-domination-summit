ap.Routes.hashLogin = () ->
	hash = location.pathname.substr(1)
	_.whenReady 'assets', =>
		ap.goTo 'empty', {}, ->
			ap.api 'post user/login', {hash: hash}, (rsp) ->
				if rsp.loggedin
					ap.login(rsp.me)
					ap.navigate('hub')
				else
					ap.navigate('not-authorized')