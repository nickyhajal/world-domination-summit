jQuery.fn.scan
	add:
		id: 'connect-purchase-area'
		fnc: ->
			$t = $(this)
			html = '<button class="button connect-purchase-start">Get Your WDS Connect Ticket!</button>'
			$t.html(html)
			$('body').on 'click', '.connect-purchase-start', (e) ->
				e.preventDefault()
				ap.Modals.open('connect-purchase')

