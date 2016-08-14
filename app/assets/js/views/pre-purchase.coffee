ap.Views.pre_purchase = XView.extend
	charging: false
	claiming: false
	giving: false
	newAccount: false
	names: []
	events:
		'click .show-panel': 'showEvent'
		'submit #purchase-form': 'purchase'
	initialize: ->
		@out = _.t 'parts_pre-purchase', {}
		tk @out
		@initRender()
		$('body').on 'click', '.pre-purchase-start', (e) ->
				e.preventDefault()
				ap.Modals.open('pre-purchase')
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
		Stripe.setPublishableKey(ap.stripe_pk);
		@show('buy')
	changeQuantity: (e) ->
		$t = $(e.currentTarget)
		q = $t.select2('val')
		$('.cnct-total').html('$'+(q*547));
		$('.cnct-fee').html('+ $'+(q*10)+'.00');
	processing: (isProc = true) ->
		if isProc
			$('.cnct-process-shell').addClass('active')
		else
			@charging = false
			$('.cnct-process-shell').removeClass('active')
	purchase: (e) ->
		e.preventDefault()
		e.stopPropagation()
		return if @charging
		@charging = true
		$t = $(e.currentTarget)
		post = $t.formToJson()
		@processing()
		charge = =>
			Stripe.card.createToken $t, (status, rsp) =>
				if rsp.error
					$('.cc-error').show().html rsp.error.message
					@processing(false)
					$.scrollTo(0)
					setTimeout ->
						$('.cc-error').hide()
					, 10000
				else
					ap.api 'post product/charge', {card_id: rsp.id, code: 'wds17test', purchase_data: post}, (rsp) =>
						@processing(false)
						@show('done')
		if ap.me
			charge()
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

