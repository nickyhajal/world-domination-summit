jQuery.fn.scan 
	add: 
		id: 'dispatch'
		fnc: ->
			$el = $(this)
			channel = $el.data('channel')
			channel_type = $el.data('channel_type')
			user_id = $el.data('user_id')
			new ap.Views.Dispatch({el: $el, channel: channel, channel_type: channel_type, user_id: user_id})