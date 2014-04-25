jQuery.fn.scan 
	add: 
		id: 'interest-select-list'
		fnc: ->
			$el = $(this)
			new ap.Views.InterestList({el: $el})