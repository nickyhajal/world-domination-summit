ap.Views.login = XView.extend
	events: 
		'submit #login-form': 'login'
	
	initialize: ->
		@initRender()

	login: (e) ->
		e.preventDefault()
		$t = $(e.currentTarget)
		post = $t.formToJson()
		ap.api 'post user/login', post, (rsp) ->
			if rsp.loggedin and rsp.me?
				ap.login rsp.me
				if ap.login_redirect? and ap.login_redirect.length
					ap.navigate(ap.login_redirect)
				else
					ap.navigate('hub')
			else
				$('.login-error').show()
				setTimeout ->
					$('.login-error').hide()
				, 10000
