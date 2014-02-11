Shelf = require('./shelf')
_ = require('underscore')
Q = require('q')

Content = Shelf.Model.extend
  tableName: 'content'
  permittedAttributes: [
    'contentid', 'type', 'uniqid', 'data', 'stamp'
  ]
  hasTimestamps: true
  initialize: ->
    this.on 'creating', this.creating, this
    this.on 'created', this.created, this

Contents = Shelf.Collection.extend
  model: Content

module.exports = [Content, Contents]