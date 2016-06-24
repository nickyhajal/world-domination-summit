ap.Views.admin_transfers = XView.extend
	timo: 0
	events:
		'click #transaction-results tr': 'row_click'
	initialize: ->
		@initRender()

	rendered: ->
		@initSelect2()
		@getTransactions()

	initSelect2: ->

	getTransactions: ->
		ap.api 'get admin/transfers', {}, (rsp) ->
			html = ''
			count = 0
			for t in rsp.transfers
				count += 1
				n = JSON.parse(t.new_attendee)
				html += '<tr>
					<td>'+count+'</td>
					<td><a href="/admin/user/'+t.user_id+'">'+t.first_name+' '+t.last_name+'</a></td>
					<td><a href="/admin/user/'+t.to_id+'">'+n.first_name+' '+n.last_name+'</a></td>
					<td>'+moment(t.stamp).format('MMMM Do [at] h:mma')+'</td>
				</tr>
				'
			$('#transfer-results').html(html)
	# row_click: (e) ->
		# user = $(e.currentTarget).data('user')
		# ap.navigate('admin/user/'+user)

	whenFinished: ->


