jQuery.fn.scan 
	add: 
		id: 'pre-input'
		fnc: ->
			$el = $(this)
			inp = $('input', $el.parent())
			$el.click ->
				inp.focus()
				len = inp.val().length
				if inp[0].setSelectionRange? and len > 0
					inp[0].setSelectionRange(len, len)
