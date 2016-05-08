jQuery.fn.scan
	add:
		id: 'attendee-selector'
		fnc: ->
			$el = $(this)
			user_id = $el.data('user_id')
			new ap.Views.AttendeeDispatch({el: $el, user_id: user_id})