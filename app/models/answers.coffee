Shelf = require('./shelf')
_ = require('underscore')
Q = require('q')
[Question, Questions] = require './questions'

Answer = Shelf.Model.extend
  tableName: 'answers'
  permittedAttributes: [
    'question_id', 'answer', 'user_id'
  ]
  idAttribute: 'answer_id'
  initialize: ->
    this.on 'creating', this.creating, this
    this.on 'created', this.created, this

Answers = Shelf.Collection.extend
  model: Answer
  addOrUpdate: (user_id, question_id, answer) ->
    dfr = Q.defer()
    Answer.forge
      question_id: question_id
      user_id: user_id
    .fetch()
    .then (row) ->
      if not row
        row = Answer.forge
          question_id: question_id
          user_id: user_id
      row.set('answer', answer)
      row
      .save()
      .then ->
        dfr.resolve answer
      , (err) ->
        console.error(err)
    dfr.promise

  updateAnswers: (user_id, answers) ->
    dfr = Q.defer()
    
    doUpdate = (answers, inx = 0) ->
      if answers[inx]?
        answer = answers[inx]
        Answers.forge().addOrUpdate(user_id, answer.question_id, answer.answer)
        .then (row) ->
          doUpdate(answers, (inx+1))
      else
        dfr.resolve()
    doUpdate(answers)
    return dfr.promise

module.exports = [Answer, Answers]