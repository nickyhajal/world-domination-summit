jQuery.fn.scan
	add:
		id: 'academy-purchase-area'
		fnc: ->
			$t = $(this)
			event_id = $t.data('event_id')
			html = '
				<a href="#"
					class="academy-purchase-start button rsvp-button"
					data-dorsvp="0"
					data-fullMessage="Academy Full"
					data-event_id="'+event_id+'"
					data-start="Attend this Academy"
					data-logged_out="Attend this Academy"
					data-cancel="You\'re Attending!"
					data-type="academy">Attend this Academy</a>'
			$t.html(html)
			$('body').on 'click', '.academy-purchase-start', (e) ->
				$t = $(e.currentTarget)
				e.preventDefault()
				unless $t.hasClass('attending')
					ap.Modals.open('academy-purchase')

