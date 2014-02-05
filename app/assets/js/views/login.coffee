ap.Views.login = XView.extend
	events:
		'submit #login-form': 'loginUser'
	initialize: ->
		if ap.me
			ap.navigate '/'
		else
			@initRender()
	loginUser: (e)->
		form = $(e.currentTarget).formToJson()
		ap.api 'post user/login', form, (rsp) ->
			if rsp.me
				ap.me = new ap.User rsp.me
				ap.navigate '/'
				ap.Notify.now
					msg: 'Welcome back - now Let\'s Duo!'
					expire: 5
			else
				ap.Notify.now
					msg: 'Sorry - your e-mail and password didn\'t match.'
					expire: 5
					clss: 'alert'
		, (err) ->
				rsp = JSON.parse(rsp.responseText)
				if rsp.err
					for err in rsp.errors
						ap.Notify.now
							msg: err
							clss: 'notice'
		return false