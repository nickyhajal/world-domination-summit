ap.Views.admin_manifest = XView.extend
	events: 
		'keyup .manifest-search': 'search'
		'click #manifest-results tr': 'row_click'
	initialize: ->
		@initRender()

	rendered: ->
	search: (e) ->
		val = $(e.currentTarget).val()
		if val.length > 2
			results = ap.Users.search(val)
			html = ''
			for atn in results
				html += '<tr data-user="'+atn.get('user_name')+'">
					<td>
						<div class="manifest-avatar" style="background:url('+atn.get('pic')+')"></div>
						<span>'+atn.get('first_name')+' '+atn.get('last_name')+'</span>
					</td>
					<td>'+atn.get('email')+'</td>
					<td>'+atn.get('user_name')+'</td>
					<td>'+atn.get('twitter')+'</td>'
			$('#manifest-results').html(html)
			$('#manifest-start').hide()
			$('#manifests-results-shell').show()
		else
			$('#manifest-start').show()
			$('#manifests-results-shell').hide()
	row_click: (e) ->
		user = $(e.currentTarget).data('user')
		ap.navigate('admin/user/'+user)


