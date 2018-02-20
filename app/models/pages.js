const Shelf = require('./shelf');
const Bookshelf = require('bookshelf');
const Q = require('q');

const Page = Shelf.Model.extend({
  tableName: 'pages',
  idAttribute: 'page_id',
  hasTimestamps: true,
});

const Pages = Shelf.Collection.extend({
  model: Page,
});

module.exports = [Page, Pages];
