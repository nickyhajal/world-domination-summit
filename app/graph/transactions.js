const {
  GraphQLString,
  GraphQLObjectType,
  GraphQLNonNull,
  GraphQLBoolean,
  GraphQLInt,
  GraphQLList,
} = require('graphql');
const bookshelf = require('bookshelf');
const [User, Users] = require('../models/users');
const [Transaction, Transactions] = require('../models/transactions');
const ProductGraph = require('./products');
const UserGraph = require('./users');
const TransactionGraphType = require('./TransactionGraphType');

const Type = TransactionGraphType;
const PluralType = new GraphQLObjectType({
  name: 'Transactions',
  description: 'Transactions Type',
  fields: () => {
    return {
      transactions: { type: new GraphQLList(Type) },
      pages: { type: GraphQLInt },
      count: { type: GraphQLInt },
    };
  },
});

const Field = {
  type: Type,
  args: {
    id: { type: GraphQLString },
  },
  resolve: async (root, { id }) => {
    const row = await Transaction.forge({ transaction_id: id }).fetch();
    return row.attributes;
  },
};
const Fields = {
  type: PluralType,
  args: {
    order_by: { type: GraphQLString, defaultValue: 'transaction_id' },
    order: { type: GraphQLString, defaultValue: 'DESC' },
    per_page: { type: GraphQLInt, defaultValue: 20 },
    page: { type: GraphQLInt, defaultValue: 0 },
  },
  resolve: async (root, { page, per_page, order_by, order }) => {
    console.log(page, per_page);
    const rows = await Transactions.forge()
      .query(qb => {
        qb
          .limit(per_page)
          .offset(page * per_page)
          .orderBy(order_by, order);
      })
      .fetch();
    let countRes = await process
      .knex('transactions')
      .count('transaction_id as cnt');
    countRes = countRes[0].cnt;
    return {
      transactions: rows.models.map(row => row.attributes),
      count: countRes,
      pages: countRes / per_page,
    };
  },
};

module.exports = {
  Type,
  Field,
  // Search,
  // // Create,
  Fields,
};
