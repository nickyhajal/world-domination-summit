ap.Routes.notes = (user_id) ->
	_.whenReady 'tpls', =>
		ap.goTo('notes', {user_id: user_id})

