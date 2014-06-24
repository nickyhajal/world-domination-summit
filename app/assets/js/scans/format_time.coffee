jQuery.fn.scan 
	add: 
		id: 'format-time'
		fnc: ->
			$t = $(this)
			format = $t.data('format')
			time = moment.utc(($t.html())).subtract('hours', '7')
			$t.html(time.format(format))


