ap.Views.your_transfer = XView.extend

	initialize: ->
		@initRender()

	rendered: ->
		@checkTransferStatus()

	checkTransferStatus: ->
		ap.api 'get transfer/status', {transfer_id: @options.transfer_id}, (rsp) =>
			done = false

			if rsp.status is 'paid'
				done = true
				$('.transfer-status').hide()
				$('.transfer-success').show()
				$('.new-attendee').html(rsp.to)
			else if rsp.status is 'paypal_wait'
				$('.transfer-status').hide()
				$('.transfer-problem').show()
			else
				$('.transfer-status').hide()
				$('.transfer-waiting').show()

			unless done
				setTimeout =>
					@checkTransferStatus()
				, 3000




