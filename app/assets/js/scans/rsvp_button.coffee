jQuery.fn.scan 
	add: 
		id: 'rsvp-button'
		fnc: ->
			$t = $(this)
			event_id = $t.data('event_id')
			start = $t.data('start') ? 'RSVP to this Meetup'
			cancel = $t.data('cancel') ? 'Cancel Your RSVP'

			$t.click ->
				ap.api 'post event/rsvp', {event_id: event_id}, (rsp) ->
					rsvps =	ap.me.get('rsvps')
					if rsp.action is 'rsvp'
						rsvps.push(event_id)
						ap.me.set('rsvps', rsvps)
					else
						tmp = []	
						for rsvp in rsvps
							if rsvp isnt event_id
								tmp.push rsvp
						ap.me.set('rsvps', tmp)
					buttonText()
					if ap.currentView.renderAttendees?
						ap.currentView.renderAttendees()
				return false

			buttonText = ->
				if ap.me? and ap.me
					rsvps = ap.me.get('rsvps')
					if rsvps.indexOf(event_id) > -1
						$t.html(cancel)
					else
						$t.html(start)
				else
					$t.html('Login to RSVP')

			buttonText()


