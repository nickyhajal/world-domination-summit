Shelf = require('./shelf')
_ = require('underscore')
Q = require('q')

Transaction = Shelf.Model.extend
  tableName: 'transactions'
  idAttribute: 'transaction_id'
  hasTimestamps: true
  permittedAttributes: [
  	'transaction_id', 'product_id', 'user_id', 'status', 'paid_amount'
  ]

Transactions = Shelf.Collection.extend
  model: Transaction

module.exports = [Transaction, Transactions]