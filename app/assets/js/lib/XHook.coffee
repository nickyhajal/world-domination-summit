class _XHook
	hooks: {}
	hook: (hook, fnc) ->
		if not @hooks[hook]?
			@hooks[hook] = ->
				fnc()
		else
			@hooks[hook] = ->
				@hooks[hook]()
				fnc()
	trigger: (hook) ->
		if @hooks[hook]?
			@hooks[hook]()

window.XHook = new _XHook()
		