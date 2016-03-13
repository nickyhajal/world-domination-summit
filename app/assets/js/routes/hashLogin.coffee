ap.Routes.hashLogin = (hash) ->
	hash = location.pathname.substr(1).replace('transfer/', '')
	ap.loading true
	ap.goTo 'empty', {}, ->
		ap.api 'post user/login', {hash: hash}, (rsp) ->
			if rsp.loggedin
				ap.login(rsp.me)
				if location.pathname.indexOf('transfer') > -1
					ap.loading false
					ap.navigate('transfer')
				else
					ap.navigate('hub')
			else
				ap.loading false
				ap.navigate('not-authorized')