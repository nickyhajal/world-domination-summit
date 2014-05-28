###

	Scanner looks through a particular scope,
	finds classes it recognizes and does
	something there.



###

(($)->
	Scans = {}
	$.fn.scan = (opts = {})->
		el = $(this)
		if opts.add?
			Scans[opts.add.id] = opts.add.fnc
		else
			for scanType, fnc of Scans
				for piece in $('.'+scanType, el)
					unless $(piece).hasClass('scanner-scanned-'+scanType)
						fnc.call(piece)
						$(piece).addClass('scanner-scanned-'+scanType)
		return this
)(jQuery)