ap.Views.admin_transactions = XView.extend
	timo: 0
	events:
		'click #manifest-results tr': 'row_click'
	initialize: ->
		@initRender()

	rendered: ->
		@initSelect2()
		@getTransactions()

	initSelect2: ->

	getTransactions: ->
		ap.api 'get transactions', {}, (rsp) ->
			html = ''
			for t in rsp.transactions
				atn = new ap.User(t)
				quantity = if t.quantity? then t.quantity else 1
				user_name_link = if atn.get('user_name').length then atn.get('user_name') else atn.get('hash')
				html += '<tr data-user="'+user_name_link+'">
					<td>
						<div class="transaction-avatar" style="background:url('+atn.getPic(64)+')"></div>
						<span>'+t.first_name+' '+t.last_name+'</span>
						<div class="user_name">'+t.name+'</div>
					</td>
					<td>'+quantity+'</td>
					<td>'+_.money(t.paid_amount)+'</td>
					<td>'+moment(t.updated_at).format('M/DD/YY [at] h:mm a')+'</td>'
			$('#transaction-results').html(html)
	row_click: (e) ->
		ap.lastSearch = $('.manifest-search').val()
		user = $(e.currentTarget).data('user')
		ap.navigate('admin/user/'+user)

	whenFinished: ->

