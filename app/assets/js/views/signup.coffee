ap.Views.signup = XView.extend
	events:
		'submit #signup-form': 'createUser'
	initialize: ->
		if ap.me
			ap.navigate '/create'
		else
			XView.prototype.initialize.call(this)
	rendered: ->
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
		user.save {},
			success: (mi, rsp) ->
				ap.me = new ap.User(rsp.user)
				ap.navigate 'home'
				ap.Notify.closeAll()
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