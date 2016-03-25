jQuery.fn.scan
	add:
		id: 'select2'
		fnc: ->
			$el = $(this)
			opts = {}
			opts.width = $(this).data('width')
			opts.minimumResultsForSearch = if $(this).data('search')? && +$(this).data('search') then null else -1
			$el.select2(opts)
