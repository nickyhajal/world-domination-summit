Shelf = require('./shelf')
_ = require('underscore')
Q = require('q')

Answer = Shelf.Model.extend
  tableName: 'answers'
  permittedAttributes: [
    'questionid', 'answer', 'userid'
  ]
  hasTimestamps: true
  initialize: ->
    this.on 'creating', this.creating, this
    this.on 'created', this.created, this

Answers = Shelf.Collection.extend
  model: Answer

module.exports = [Answer, Answers]