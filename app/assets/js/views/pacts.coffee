ap.Views.pacts = XView.extend
	events:
		'submit #signup-form': 'createUser'
	rendered: ->
	createUser: (e)->
		form = $(e.currentTarget).formToJson()
		user = new ap.User form
		user.save {},
			success: (mi, rsp) ->
				router.navigate(ap.R.pacts)
				ap.Notify.now
					msg: 'Welcome to ActionPact: Awesomness Fest'
			error: (me, rsp) ->
				rsp = JSON.parse(rsp.responseText)
				if rsp.err
					for err in rsp.errors
						ap.Notify.now
							msg: err
							clss: 'notice'

		return false