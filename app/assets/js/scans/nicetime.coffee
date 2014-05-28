jQuery.fn.scan 
	add: 
		id: 'nicetime'
		fnc: ->
			$el = $(this)
			time = moment.utc($el.html())
			if time.isValid()
				$el.html(_.nicetime(time))
