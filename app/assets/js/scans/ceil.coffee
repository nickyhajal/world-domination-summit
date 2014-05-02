jQuery.fn.scan 
	add: 
		id: 'ceil'
		fnc: ->
			$el = $(this)
			val = Math.ceil(+$el.html())
			$el.html(val)


