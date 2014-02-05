helpers = (app) ->
	
	app.helpers
		stringify: (obj) -> JSON.stringify obj
	app.dynamicHelpers
		flash: (req, res) -> req.flash()

module.exports = helpers