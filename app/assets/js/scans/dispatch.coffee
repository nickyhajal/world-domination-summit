jQuery.fn.scan 
	add: 
		id: 'dispatch'
		fnc: ->
			$el = $(this)
			channel = $el.data('channel')
			channel_type = $el.data('channel_type')
			new ap.Views.Dispatch({el: $el, channel: channel, channel_type: channel_type})