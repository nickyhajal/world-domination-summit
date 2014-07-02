ap.Views.ranks = XView.extend
	initialize: ->
		@initRender()
	rendered: ->
		_.whenReady 'users', =>
			@renderRanks()
	renderRanks: ->
		html = ''
		count = 1
		for rank in ap.ranks
			user_id = rank.user_id
			user = ap.Users.get(user_id)
			html += '
				<a href="~'+user.get('user_name')+'" id="rank-'+count+'" class="rank-row">
					<span class="rank-therank">'+count+'</span>
					<div class="rank-attendee">'+user.get('first_name')+' '+user.get('last_name')+'</div>
				</a>
			'
			count += 1
		$('#race-rank-list').html(html)

