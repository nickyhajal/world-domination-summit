Wufoo = require 'wufoo'

[User, Users] = require '../models/users'

shell = (app, db) ->
  grab_amb = ->
    tk 'Grabbing Ambassadors...'
    wf = new Wufoo app.settings.wufoo_account, app.settings.wufoo_key
    wf.getFormEntries app.settings.wufoo_amb_form, (err, entries) ->
      tk entries.length
      for entry in entries
        name = entry['field224'].split(" ")
        email = entry['field4']
        create_ambassador name, email

  create_ambassador = (name, email) ->
    #Update or Create a User account
    User.forge({email: email})
    .fetch()
    .then (existing) ->
      unless existing
        User.forge
          first_name: name[0],
          last_name: name[name.length-1],
          email: email
          type: 'potential-ambassador'
        .save()
      else
        #Only update their type if they aren't an ambassador
        if existing.get('type').indexOf("ambassador") == -1
          existing.set('type', 'potential-ambassador')
          existing.save()
  grab_amb()

module.exports = shell
