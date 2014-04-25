Shelf = require('./shelf')
_ = require('underscore')
Q = require('q')

Interest = Shelf.Model.extend
  tableName: 'interests'
  permittedAttributes: [
    'interest_id', 'interest'
  ]

Interests = Shelf.Collection.extend
  model: Interest

module.exports = [Interest, Interests]