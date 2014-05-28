Shelf = require('./shelf')
_ = require('underscore')
Q = require('q')

Question = Shelf.Model.extend
  tableName: 'questions'
  permittedAttributes: [
    'questionid', 'question', 'question-slug'
  ]

Questions = Shelf.Collection.extend
  model: Question

module.exports = [Question, Questions]