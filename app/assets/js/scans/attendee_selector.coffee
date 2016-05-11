jQuery.fn.scan
	add:
		id: 'attendee-selector'
		fnc: ->
			$el = $(this)
			user_id = $el.data('user_id')
			name = $el.data('name')
			filler =
				atn_type: $el.data('atn_type')
				atn_type_w_a: $el.data('atn_type_w_a')
				selected: $el.data('selected') ? ''
				bios: ap.bios ? ''
			options =
				el: $el
				name: name
				filler: filler
				render: 'replace'
			new ap.Views.AttendeeSelector(options)