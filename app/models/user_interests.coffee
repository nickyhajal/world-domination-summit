Shelf = require('./shelf')
_ = require('underscore')
Q = require('q')

UserInterest = Shelf.Model.extend
  tableName: 'user_interests'
  permittedAttributes: [
    'user_interest_id', 'interest_id'
  ]
  idAttribute: 'user_interest_id'

UserInterests = Shelf.Collection.extend
  model: UserInterest

module.exports = [UserInterest, UserInterests]