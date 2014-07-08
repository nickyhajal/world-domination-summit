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
					name = user.get('first_name')
					if ap.me.isConnected?(user_id)
						$t.addClass('following')
						if format is 'short'
							str = 'Friends'
						else
							str = 'Friends with '+name
					else
						$t.removeClass('following')
						if format is 'short'
							str = 'Friend'
						else
							str = 'Friend '+name

					$t.html (str)

				changeFnc = (e) ->
					ap.me.toggleConnection user_id, ->
						syncButton()
					e.preventDefault()
					e.stopPropagation()

				syncButton()

				$t.click changeFnc


