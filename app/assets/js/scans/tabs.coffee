jQuery.fn.scan 
	add: 
		id: 'tab-links'
		fnc: ->
			tablist = []
			tabs = []
			$el = $(this)
			context = $el.data('context')
			shell = $('#tab-shell-'+context)
			links = $('.tab-link', $el)
			prev = false
			count = 0
			for link in links
				tabname = $(link).data('tabname')
				tab = 
					tabname: tabname
					num: count

				if prev
					prev.next = tab.tabname
					tab.prev = prev.tabname	
				prev = tab

				count += 1
				tabs[tabname] = tab
				tablist.push tabname

			onTab = tabs[tablist[0]]
			prev.next = false

			goToTab = (tabname) ->
				doGoTo = ->
					$('.tab-panel-active', shell).removeClass('tab-panel-active')
					$('.tab-link-active', $el).removeClass('tab-link-active')
					$('#tab-panel-'+tabname, shell).addClass('tab-panel-active')
					$('.tab-link[data-tabname="'+tabname+'"]', $el).addClass('tab-link-active')
					onTab = tabs[tabname]
					XHook.trigger('tab-show-'+context, onTab)
					$.scrollTo(0)

				if XHook.hooks['tab-before-show-'+context]?
					XHook.trigger('tab-before-show-'+context, onTab, doGoTo)
				else	
					doGoTo()

			showTab_click = (e) ->
				e.preventDefault()	
				$t = $(this)
				unless $t.hasClass('tab-disabled')
					tabname = $t.data('tabname')
					goToTab(tabname)

			showTab_next = (e) ->
				e.preventDefault()	
				if onTab.next
					goToTab onTab.next

			showTab_prev = (e) ->
				e.preventDefault()	
				if onTab.prev
					goToTab onTab.prev


			$el
				.on('click', '.tab-link', showTab_click)
			shell
				.on('click', '.tab-next', showTab_next)
				.on('click', '.tab-prev', showTab_prev)


