Shelf = require('./shelf')
_ = require('underscore')
Q = require('q')

UserNote = Shelf.Model.extend
  tableName: 'user_notes'
  permittedAttributes: [
    'unote_id', 'user_id', 'about_id', 'note', 'admin', 'year'
  ]
  idAttribute: 'unote_id'
  hasTimestamps: true

UserNotes = Shelf.Collection.extend
  model: UserNote

module.exports = [UserNote, UserNotes]