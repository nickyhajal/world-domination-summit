Shelf = require('./shelf')

RaceSubmission = Shelf.Model.extend
	tableName: 'race_submissions'
	hasTimestamps: true
	idAttribute: 'submission_id'
	permittedAttributes: [
		'submission_id', 'user_id', 'ach_id', 'hash', 'ext', 'rating'
	]
	getUrl: (user_name = '') ->
		if @get('type') is 'ig'
			return @get('ext')
		else
			return 'http://worlddominationsummit.com/images/race_submissions/'+user_name+'/'+@get('slug')+'/w600_'+@get('hash')+'.'+@get('ext')
	sendRatingEmail: (rating) ->
		[User, Users] = require('./users')
		[RaceTask, RaceTasks] = require('./racetasks')
		User.forge
			user_id: @get('user_id')
		.fetch()
		.then (user) =>
			RaceTasks::getById('slug')
			.then (taskBySlug) =>
				task = taskBySlug[@get('slug')]
				url = @getUrl(user.get('user_name'))
				task_name = '<i>'+task.task+ '</i> <a href="'+url+'">(here\'s the submission)</a>'
				name = user.get('first_name')
				if rating is -1
					subject = 'Your Unconventional Race Submission'
					content = '
						Hey '+name+',<br><br>
						Sorry to say your submission was rejected for the task: '+task_name+'.<br><br>
						This is probably because the person reviewing didn\'t understand how it related
						to or accomplished the task.<br><br>
						Here\'s the good news: You can try again!<br><br>
						If you have any questions or concerns, email concierge@wds.fm and someone will be able to help (please include the link to the submission).<br><br>
						Thanks so much for participating in the race - have fun!<br><br>

						Sincerely,<br>
						The Unconventional Race Team
					'
				else if rating is 1
					subject = 'Your Unconventional Race Submission was Accepted!'
					content = '
						Hey '+name+',<br><br>
						We\'re happy to say your submission was accepted for the task: '+task_name+'.<br><br>
						Remember, if you submit especially creative photos, you can be awarded up to 3 bonus points!
						Those really add up.
						Thanks for participating in the Unconventional Race!<br><br>

						To Adventure!<br>
						The Unconventional Race Team
					'
				else if rating is 2
					subject = 'Your Unconventional Race Submission was Great!'
					content = '
						'+name+'!<br><br>
						Thanks so much for your great submission to the task: '+task_name+'.<br><br>

						We liked it so much we awarded you <b>an extra bonus point</b>, aw yeah!

						Thanks for participating in the Unconventional Race, you\'re doing great!<br><br>

						To Greatness!<br>
						The Unconventional Race Team
				'
				else if rating is 3
					subject = 'Your Unconventional Race Submission was Awesome!!!'
					content = '
						Woah, '+name+'...<br><br>

						You blew us away with your submission for the task: '+task_name+'<br><br>

						It was so awesome, we awarded you <b>3 bonus points</b>!<br><br>

						Thanks for participating in the Unconventional Race, you\'re awesome!!<br><br>

						With Awesomeness,<br>
						The Unconventional Race Team
					'
				user.sendEmail 'base-email', subject, 
					content: content

RaceSubmissions = Shelf.Collection.extend
  model: RaceSubmission

module.exports = [RaceSubmission, RaceSubmissions]