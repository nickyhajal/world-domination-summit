knex = require('knex')
Shelf = require('./shelf')
_ = require('underscore')
Q = require('q')

Interest = Shelf.Model.extend
  tableName: 'interests'
  idAttribute: 'interest_id'
  permittedAttributes: [
    'interest_id', 'interest'
  ]

Interests = Shelf.Collection.extend
  model: Interest

module.exports = [Interest, Interests]