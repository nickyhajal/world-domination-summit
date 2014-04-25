jQuery.fn.scan 
	add: 
		id: 'dispatch'
		fnc: ->
			$el = $(this)
			channel = $el.data('channel')
			new ap.Views.Dispatch({el: $el, channel: channel})