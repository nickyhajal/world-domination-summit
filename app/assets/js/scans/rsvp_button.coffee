jQuery.fn.scan 
	add: 
		id: 'rsvp-button'
		fnc: ->
			$t = $(this)
			event_id = $t.data('event_id')
			cancel = $t.data('cancel') ? 'Cancel Your RSVP'
			maxed = $t.data('maxed')?
			start = $t.data('start') ? 'RSVP to this Meetup'
			if maxed
				start = 'Event Full'

			$t.click ->
				if ap.me? and ap.me and not maxed
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
				else if not ap.me
					ap.navigate('login')
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


