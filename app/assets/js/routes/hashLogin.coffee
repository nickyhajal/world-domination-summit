ap.Routes.hashLogin = (hash) ->
	hash = location.pathname.substr(1).replace('transfer/', '').replace('academies/', '')
	ap.loading true
	ap.goTo 'empty', {}, ->
		ap.api 'post user/login', {hash: hash}, (rsp) ->
			if rsp.loggedin
				ap.login(rsp.me)
				if location.pathname.indexOf('transfer') > -1
					ap.loading false
					ap.navigate('transfer')
				else if location.pathname.indexOf('propose-a-meetup') > -1
					ap.loading false
					ap.navigate('propose-a-meetup')
				else if location.pathname.indexOf('academies') > -1
					ap.loading false
					ap.navigate('academies')
				else
					ap.navigate('hub')
			else
				ap.loading false
				ap.navigate('not-authorized')