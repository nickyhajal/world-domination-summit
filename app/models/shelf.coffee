Bookshelf = require('bookshelf')(process.db);
whn      = require('when')
moment    = require('moment')
_         = require('underscore')
uuid      = require('node-uuid')
Validator = require('validator').Validator
sanitize  = require('validator').sanitize
S = require 'underscore.string'

# Initializes a new Bookshelf instance, for reference elsewhere.
Shelf = Bookshelf.ap = Bookshelf;
Shelf.client = process.db.client
Shelf.validator = new Validator();
Shelf.Model = Shelf.Model.extend
  saveChanging: ->
    @before_save = @_previousAttributes
    @last_changed = @changed
  lastDidChange: (attrs, opts = {}) ->
    if typeof attrs isnt 'object'
      attrs = [attrs]
    for attr in attrs
      if opts.and? and opts.and
        if not @last_changed[attr]?
          return false
      else
        if @last_changed[attr]?
          return true
    return false
module.exports = Shelf
