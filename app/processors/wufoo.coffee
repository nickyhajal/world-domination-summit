Wufoo = require 'wufoo'

[User, Users] = require '../models/users'

shell = (app, db) ->
  grab_amb = ->
    wf = new Wufoo app.settings.wufoo_account, app.settings.wufoo_key
    wf.getFormEntries app.settings.wufoo_amb_form, (err, entries) ->
      for entry in entries
        name = entry['field224'].split(" ")
        email = entry['field4']
        User.forge({first_name: name[0], last_name: name[name.length-1], email: email, type: 'potential-ambassador'}).save()
  grab_amb()

module.exports = shell
