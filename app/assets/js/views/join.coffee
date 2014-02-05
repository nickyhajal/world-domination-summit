ap.Views.join = XView.extend
	events:
		'submit #join-signup-form': 'createUser'
	initialize: ->
		ap.joining_duo = @options.hash
		if ap.me
			ap.navigate '/login'
		else
			XView.prototype.initialize.call(this)
	rendered: ->
		duo = @options.duo
		$('.inviter-name').html(duo.get('with_user').first_name)
		$('.invitee-name').html(duo.get('invitee'))
		if ap.env is 'development'
			@gen()
	gen: ->
		ranStr = (len) ->
			text = "";
			possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
			for i in [0..len]
				text += possible.charAt(Math.floor(Math.random() * possible.length));
			return text;
		$('input[name="first_name"]').val(ranStr(6))
		$('input[name="last_name"]').val(ranStr(6))
		$('input[name="email"]').val('nhajal+'+ranStr(6)+'@gmail.com')
		$('input[name="password"]').val(ranStr(10))

	createUser: (e)->
		form = $(e.currentTarget).formToJson()
		user = new ap.User form
		user.save {joining_duo: @options.hash},
			success: (mi, rsp) ->
				ap.me = new ap.User(rsp.user)
				ap.navigate 'home'
				ap.Notify.now
					msg: 'Welcome to Let\'s Duo!'
			error: (me, rsp) ->
				rsp = JSON.parse(rsp.responseText)
				if rsp.err
					for err in rsp.errors
						ap.Notify.now
							msg: err
							clss: 'notice'

		return false