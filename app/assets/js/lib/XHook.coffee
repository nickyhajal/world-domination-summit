class _XHook
	hooks: {}
	hook: (hook, fnc) ->
		if not @hooks[hook]?
			@hooks[hook] = =>
				fnc.apply(null, arguments)
		else
			@hooks[hook] = =>
				@hooks[hook].apply(null, @trimArgs(arguments))
				fnc.apply(null, arguments)
	trigger: (hook, args) ->
		if @hooks[hook]?
			@hooks[hook].apply(null, @trimArgs(arguments))

	trimArgs: (args) ->
		Array.prototype.slice.call(args).splice(1)

window.XHook = new _XHook()
		