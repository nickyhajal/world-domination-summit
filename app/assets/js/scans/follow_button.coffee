###

	Toggle following

###

jQuery.fn.scan 
	add: 
		id: 'follow-button'
		fnc: ->
			$t = $(this)
			_.whenReady 'users', ->
				format = $t.data('format') ? 'long'
				user_id = $t.data('user_id')
				user = ap.Users.get(user_id)

				syncButton = ->
					str = 'Friend '
					if ap.me.isConnected?(user_id)
						str = if format is 'short' then 'Friends with' else 'Friends with'
					$t.html (str + ' ' + user.get('first_name'))

				changeFnc = (e) ->
					ap.me.toggleConnection user_id, ->
						syncButton()
					e.preventDefault()

				syncButton()

				$t.click changeFnc


