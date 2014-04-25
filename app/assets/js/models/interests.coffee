ap.Interest = window.XModel.extend
	defaults:
		model: 'Interest'
		classes: 'interest-button'
	idAttribute: 'interest_id'
	url: '/api/interest'
	saved: (rsp)->

Interests = XCollection.extend
	model: ap.Interest
	url: '/api/interests/'

ap.Interests = new Interests()

for interest in ap.interests
	interest = new ap.Interest(interest)
	ap.Interests.add interest
