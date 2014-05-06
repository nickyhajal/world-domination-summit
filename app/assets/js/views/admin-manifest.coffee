ap.Views.admin_manifest = XView.extend
	timo: 0
	events: 
		'keyup .manifest-search': 'search'
		'click #manifest-results tr': 'row_click'
	initialize: ->
		@initRender()

	rendered: ->
	search: (e) ->
		clearTimeout(@timo)
		@timo = setTimeout ->
			val = $(e.currentTarget).val()
			if val.length > 2
				ap.api 'get users', {search: val}, (rsp) ->
						html = ''
						for atn in rsp.users
							atn = new ap.User(atn)
							html += '<tr data-user="'+atn.get('user_name')+'">
								<td>
									<div class="manifest-avatar" style="background:url('+atn.get('pic')+')"></div>
									<span>'+atn.get('first_name')+' '+atn.get('last_name')+'</span>
									<div class="user_name">'+atn.get('user_name')+'</div>
								</td>
								<td>'+atn.get('email')+'</td>'
						$('#manifest-results').html(html)
						$('#manifest-start').hide()
						$('#manifests-results-shell').show()
			else
				$('#manifest-start').show()
				$('#manifests-results-shell').hide()
		, 250
	row_click: (e) ->
		user = $(e.currentTarget).data('user')
		ap.navigate('admin/user/'+user)


