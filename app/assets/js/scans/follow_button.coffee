###

	Toggle following

###

jQuery.fn.scan 
	add: 
		id: 'follow-button'
		fnc: ->
			$t = $(this)
			format = $t.data('format') ? 'long'
			user_id = $t.data('user_id')
			user = ap.Users.get(user_id)

			syncButton = ->
				str = 'Follow'
				if ap.me.isConnected?(user_id)
					str = if format is 'short' then 'Following' else 'You Follow'
				$t.html (str + ' ' + user.get('first_name'))

			changeFnc = ->
				ap.me.toggleConnection user_id, ->
					syncButton()

			syncButton()

			$t.click changeFnc


