jQuery.fn.scan
	add:
		id: 'purchase-button'
		fnc: ->
			$t = $(this)
			unless $('#stripe-js').length
				$('body').append('<script src="//checkout.stripe.com/checkout.js" id="stripe-js"></script>')
			cta = $t.text()
			purch_cta = $t.data("cta")
			code = $t.data('code')
			billing_addr = +$t.data('billing_addr')
			noun = $t.data('noun')
			nouns = $t.data('nouns')
			html = '<button class="button ticket-purchase purchase-btn">'+cta+'</button>'
			if $t.data('check-remaining')
				html += '<div class="tickets-remaining-shell"> Just <div class="'+code+'-remaining-num tickets-remaining-num"></div> Remaining</div>'
			view = new ap.Views.purchase_button
				el: $t
				render: 'replace'
				out: html
				noun: noun
				nouns: nouns
				code: code
				billing_addr: billing_addr
				purch_cta: purch_cta
				checkAvailability: $t.data('check-remaining')?

