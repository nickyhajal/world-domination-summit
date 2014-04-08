jQuery.fn.scan 
	add: 
		id: 'sidebar'
		fnc: ->
			$el = $(this)
			type = $el.data('sidebar')
			sidebar = new ap.Views.Sidebar({el: $el, type: type})