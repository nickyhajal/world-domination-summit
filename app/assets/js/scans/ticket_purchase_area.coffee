jQuery.fn.scan
	add:
		id: 'ticket-purchase-area'
		fnc: ->
			$t = $(this)
			html = '<button class="button ticket-purchase">Get Your WDS Ticket!</button><div class="tickets-remaining-shell"> Just <div class="tickets-remaining-num"></div> Tickets Remaining</div>'
			$t.html(html)

