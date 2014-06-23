jQuery.fn.scan 
	add: 
		id: 'pre-input'
		fnc: ->
			$el = $(this)
			inp = $('input', $el.parent())
			$el.click ->
				inp.focus()
