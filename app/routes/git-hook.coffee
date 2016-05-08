###
# This pulls new content from GitHub when we push new content
###
jade = require('jade')
execFile = require('child_process').execFile;

routes = (app) ->
	app.all '/git-hook', (req, res) ->
		res.render "../views/git-hook",
			layout: false
		execFile 'world-domination-summit-sync', (err, stdout, stderr) ->
			tk stdout
			tk stderr
module.exports = routes
