Shelf = require('./shelf')
_ = require('underscore')
Q = require('q')

Content = Shelf.Model.extend
  tableName: 'featured_content'
  idAttribute: 'content_id'
  initialize: ->
    this.on 'creating', this.creating, this
    this.on 'created', this.created, this

Contents = Shelf.Collection.extend
  model: Content

module.exports = [Content, Contents]