ap.Routes.hashLogin = (hash) ->
	#hash = location.pathname.substr(1)
	ap.goTo 'empty', {}, ->
		ap.api 'post user/login', {hash: hash}, (rsp) ->
			if rsp.loggedin
				ap.login(rsp.me)
				if location.pathname.indexOf('transfer') > -1
					ap.navigate('transfer')
				else
					ap.navigate('hub')
			else
				ap.navigate('not-authorized')