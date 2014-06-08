jQuery.fn.scan 
	add: 
		id: 'interest-select-list'
		fnc: ->
			$el = $(this)
			context = $(this).data('context') ? 'user'
			new ap.Views.InterestList({el: $el, context: context})