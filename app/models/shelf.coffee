Bookshelf = require('bookshelf')
whn      = require('when')
moment    = require('moment')
_         = require('underscore')
uuid      = require('node-uuid')
Validator = require('validator').Validator
sanitize  = require('validator').sanitize
S = require 'underscore.string'

# Initializes a new Bookshelf instance, for reference elsewhere.
Shelf = Bookshelf.ap = Bookshelf.initialize(process.db);
Shelf.client = process.db.client
Shelf.validator = new Validator();
Shelf.Model = Shelf.Model.extend
    initialize: ->
        this.on 'creating', this.creating, this
    creating: ->
module.exports = Shelf