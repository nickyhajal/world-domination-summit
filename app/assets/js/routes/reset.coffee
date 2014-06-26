ap.Routes.reset = (hash) ->
	_.whenReady 'tpls', =>
		ap.goTo('reset-password', {hash: hash})

