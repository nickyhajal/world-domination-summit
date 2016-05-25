jQuery.fn.scan
	add:
		id: 'rsvp-button'
		fnc: ->
			$t = $(this)
			event_id = $t.data('event_id')
			cancel = $t.data('cancel') ? 'Cancel Your RSVP'
			maxed = $t.data('maxed')?
			start = $t.data('start') ? 'RSVP to this Meetup'
			fullMessage = $t.data('full_message') ? 'Event Full'
			loggedOut = $t.data('logged_out') ? 'Login to RSVP'
			status = $t.data('status') ? false
			freeMessage = $t.data('free_message') ? false
			freeMaxedMessage = $t.data('freemaxed_message') ? false
			performRsvp = $t.data('dorsvp') ? 1
			allowCancel = true
			if freeMessage
				if status is 'claim'
					start += '<span class="sidebar-btn-sub btn-free-ac">'+freeMessage+'</span>'
				else if status is 'free-maxed'
					start += '<span class="sidebar-btn-sub btn-freemaxed">'+freeMaxedMessage+'</span>'

				else if status is 'maxed'
					maxed = true
					allowCancel = false
					start = fullMessage
					$t.addClass('maxed')
			else if maxed
				start = fullMessage

			if +performRsvp
				$t.click ->
					if ap.me? and ap.me
						if (allowCancel and maxed and ($t.html() is cancel)) or not maxed
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
						$t.addClass('attending')
						$t.html(cancel)
					else
						$t.removeClass('attending')
						$t.html(start)
				else
					$t.html(loggedOut)

			buttonText()


