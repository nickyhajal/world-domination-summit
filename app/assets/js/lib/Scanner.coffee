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
			Scans[opts.add.id] =
				main: opts.add.fnc
				rescan: opts.add.rescan
		else
			for scanType, fnc of Scans
				for piece in $('.'+scanType, el)

					## Run the rescan function if it exists and we're rescanning
					if (opts.rescan? && opts.rescan) && $(piece).hasClass('scanner-scanned-'+scanType) && fnc.rescan?
						fnc.rescan.call(piece)

					## Run the main scan function
					if (opts.rescan? && opts.rescan) ||  !$(piece).hasClass('scanner-scanned-'+scanType)
						status = fnc.main.call(piece)

						## Mark as scanned if it succeeds
						if status isnt 'fail'
							$(piece).addClass('scanner-scanned-'+scanType)
		return this
	return $
)(jQuery)