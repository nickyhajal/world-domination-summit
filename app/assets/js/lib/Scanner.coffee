(($)->
	Scans = {}
	$.fn.scan = (opts = {})->
		el = $(this)
		if opts.add?
			Scans[opts.add.id] = opts.add.fnc
		else
			for scanType, fnc of Scans
				for piece in $('.'+scanType, el)
					fnc.call(piece)
		return this
)(jQuery)