ap.Views.race_guide = XView.extend
	initialize: ->
		@initRender()

		# Mark as achieved when they've reached the end 
		# of the 
		XHook.hook 'tab-show-raceguide_tabs', (tab) ->
			if not tab.next
				ap.api 'post user/achieved', {slug: 'race-guide'}

