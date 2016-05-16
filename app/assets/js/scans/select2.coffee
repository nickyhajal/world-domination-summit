jQuery.fn.scan
	add:
		id: 'select2'
		fnc: ->
			$el = $(this)
			unless $el.hasClass('select2-container')
				opts = {}
				opts.width = $(this).data('width')
				opts.minimumResultsForSearch = if $(this).data('search')? && +$(this).data('search') then null else -1
				if opts.minimumResultsForSearch < -1
					$el.addClass('select2-nosearch')
				$el.select2(opts)
				$el.on 'change', ->
					inx = $el.index()
					$('input', $el.parent()).eq(Math.floor(inx/2)).focus()
