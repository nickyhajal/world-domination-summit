jQuery.fn.scan 
	add: 
		id: 'format-time'
		fnc: ->
			$t = $(this)
			format = $t.data('format')
			time = moment.utc(($t.html()))
			$t.html(time.format(format))


