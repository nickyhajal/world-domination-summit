Wufoo = require 'wufoo'

shell = (app, db) ->
  grab_amb = ->
    wf = new Wufoo app.settings.wufoo_account, app.settings.wufoo_key
    wf.getForm app.settings.wufoo_amb_form, (err, form) ->
      form.getEntries (err, entries) ->
        for entry in entries
          tk entry['field224'] + ' ' + entry['field4']
  grab_amb()

module.exports = shell
