ap.Views.connect_purchase = XView.extend
	events:
		'click .cnct-cnct-account': 'showCreateAccount'
		'click .show-panel': 'showEvent'
		'click .done-button': 'done'
		'submit #login-form': 'login'
		'submit #purchase-form': 'purchase'
		'submit .give-ticket-form': 'giveTickets'
	initialize: ->
		@out = _.t 'parts_connect-purchase', {}
		@initRender()
	rendered: ->
		$('select[name="quantity"]').select().on('change', @changeQuantity)
	showEvent: (e) ->
		$t = $(e.currentTarget)
		panel = $t.data('panel')
		@show(panel)
	show: (panel) ->
		$('.cc-error').hide()
		$('.modal-panel').hide()
		$('.modal-panel-'+panel).show()
		if ap.me
			$('.if-no-user').hide()
		else
			$('.if-no-user').show()
	appeared: ->
		Stripe.setPublishableKey(ap.stripe_pk_test);
		if ap.me? and ap.me
			@show('buy')
	changeQuantity: (e) ->
		$t = $(e.currentTarget)
		q = $t.select2('val')
		$('.cnct-total').html('$'+(q*147));
	processing: (isProc = true) ->
		if isProc
			$('.cnct-process-shell').addClass('active')
		else
			$('.cnct-process-shell').removeClass('active')
	purchase: (e) ->
		e.preventDefault()
		$t = $(e.currentTarget)
		post = $t.formToJson()
		@processing()
		charge = =>
			Stripe.card.createToken $t, (status, rsp) =>
				if rsp.error
					$('.cc-error').show().html rsp.error.message
					setTimeout ->
						$('.cc-error').hide()
					, 10000
				else
					ap.api 'post product/charge', {card_id: rsp.id, code: 'connect', purchase_data: post}, (rsp) =>
						needsAction = []
						completed = []
						tk rsp.tickets
						for t in rsp.tickets
							if t.status == 'purchased'
								needsAction.push t
							else
								completed.push t
						if needsAction.length
							@processing(false)
							@completeTickets(needsAction, completed)
						else
							@processing(false)
							@show('done')
		if ap.me
			charge()
		else
			post.login = true
			ap.api 'post user', _.omit(post, 'quantity'), (rsp) =>
				if rsp.existing?
					$('.cc-error').show().html 'That email is in our system. <a href="#" class="show-panel" data-panel="login">Click here to login.</a>'
				else
					ap.api 'get me', {}, (rsp) =>
						ap.login(rsp.me)
						charge()
	completeTickets: (tickets, completed = []) ->
		@show('completetickets')
		t_str = if tickets.length == 1 then 'ticket' else 'tickets'
		it_str = if tickets.length == 1 then 'it\'s' else 'they\'re'
		descr = 'Great! We registered one ticket in your name,
		now just complete your other '+t_str+' by telling us who '+it_str+' for.'
		if !completed.length
			descr = 'Great! Now just complete your '+t_str+' by telling us who '+it_str+' for.'
		$('.ticket-descr-status').html(descr)
		html = '<form class="give-ticket-form" action="#" method="post">'
		count = 1
		for t in tickets
			html += '
			<div class="give-ticket-row">
				<h4>Ticket #'+count+'</h4>
				<div class="form-section">
					<div class="form-box">
						<label>First Name</label>
						<input type="text" name="'+count+'-first_name"/>
					</div>
					<div class="form-box">
						<label>Last Name</label>
						<input type="text" name="'+count+'-last_name"/>
					</div>
				</div>
				<div class="form-section">
					<div class="form-box">
						<label>E-Mail Address</label>
						<input type="text" class="long-inp" name="'+count+'-email" />
						<input type="hidden" name="'+count+'-ticket_id" value="'+t.ticket_id+'" />
					</div>
				</div>
			</div>
			'
			count += 1
		html += '
			<input type="submit" value="Complete Tickets" />
			<div class="small-text">Please double check all contact info. We\'ll send a welcome e-mail
				to each attendee.</div>
		</form>'
		$('.ticket-assign-shell').html(html)
	giveTickets: (e) ->
		e.preventDefault()
		$t = $(e.currentTarget)
		btn = _.btn $('input[type="submit"]', $t), 'Processing...', 'Done!'
		raw = $t.formToJson()
		post =
			attendees: []
		for i,val of raw
			[inx, key] = i.split('-')
			inx = (+inx) - 1
			unless post.attendees[inx]?
				post.attendees[inx] = {}
			post.attendees[inx][key] = val
		ap.api 'post user/tickets', post, (rsp) =>
			@show('done')



	done: (e) ->
		e.preventDefault()
		e.stopPropagation()
		ap.Modals.close()
		ap.navigate 'welcome'

	login: (e) ->
		e.preventDefault()
		$t = $(e.currentTarget)
		post = $t.formToJson()
		ap.api 'post user/login', post, (rsp) =>
			if rsp.loggedin and rsp.me?
				ap.login rsp.me
				@show('buy')
			else
				$('.login-error').show()
				setTimeout ->
					$('.login-error').hide()
				, 10000

