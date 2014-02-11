(($)->
	$.randrun = (args...)->
		if (typeof args[0]) isnt 'function'
			distrs = args[0]
			fncs = args.slice(1)
		else
			fncs = args.slice(0)
		if distrs
			inxs = []
			c = 0
			for distr in distrs
				for i in [0..+distr]
					inxs.push c
				c += 1
			inx = Math.floor(Math.random() * inxs.length)
			fncs[inxs[inx]]()
		else
			inx = Math.floor(Math.random() * fncs.length)
			fncs[inx]()
)(jQuery)