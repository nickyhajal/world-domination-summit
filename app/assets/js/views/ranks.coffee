ap.Views.ranks = XView.extend
	initialize: ->
		@initRender()

	rendered: ->
		_.whenReady 'users', =>
			@renderRanks()
			@updateRanks()

	renderRanks: ->
		html = ''
		count = 1
		latest = '<span>Last updated:</span>'+moment().format('MMMM Do [at] h:mm a')
		for rank in ap.ranks
			user_id = rank.user_id
			user = ap.Users.get(user_id)
			html += '
				<a href="~'+user.get('user_name')+'" id="rank-'+count+'" class="rank-row">
					<span class="rank-therank">'+count+'</span>
					<div class="rank-attendee">'+user.get('first_name')+' '+user.get('last_name')+'
						<span class="rank-points">'+rank.points+' points</span>
					</div>
				</a>
			'
			count += 1
		$('#race-rank-list').html(html)
		$('#race-latest-update').html(latest)

	updateRanks: ->
		ap.api 'get assets', {assets:'ranks'}, (rsp) =>
			ap.ranks = rsp.ranks
			ap.me.setRank()
			@renderRanks()
		setTimeout =>
			@updateRanks()
		, 6000

