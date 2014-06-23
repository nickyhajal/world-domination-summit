jQuery.fn.scan 
	add: 
		id: 'dispatch'
		fnc: ->
			$el = $(this)
			channel_id = $el.data('channel_id')
			channel_type = $el.data('channel_type')
			user_id = $el.data('user_id')
			placeholder = $el.data('placeholder')
			new ap.Views.Dispatch
				el: $el
				channel_id: channel_id
				channel_type: channel_type
				placeholder: placeholder
				user_id: user_id