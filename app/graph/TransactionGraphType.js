const {
  GraphQLString,
  GraphQLObjectType,
  GraphQLNonNull,
  GraphQLBoolean,
  GraphQLInt,
  GraphQLList,
} = require('graphql');
const [User, Users] = require('../models/users');
const [Product, Products] = require('../models/products');
const ProductGraph = require('./products');

module.exports = new GraphQLObjectType({
  name: 'Transaction',
  description: 'Transaction Type',
  fields: () => {
    const UserGraphType = require('./UserGraphType');
    return {
      transaction_id: { type: GraphQLInt },
      product_id: { type: GraphQLInt },
      user_id: { type: GraphQLInt },
      via: { type: GraphQLString },
      stripe_id: { type: GraphQLString },
      status: { type: GraphQLString },
      quantity: { type: GraphQLInt },
      paid_amount: { type: GraphQLInt },
      meta: { type: GraphQLString },
      created_at: { type: GraphQLString },
      updated_at: { type: GraphQLString },
      product: {
        type: ProductGraph.Type,
        resolve: async row => {
          const p = await Product.forge({
            product_id: row.product_id,
          }).fetch();
          return p.attributes !== undefined ? p.attributes : {};
        },
      },
      user: {
        type: UserGraphType,
        resolve: async row => {
          const u = await User.forge({
            user_id: row.user_id,
          }).fetch();
          return u.attributes !== undefined ? u.attributes : {};
        },
      },
    };
  },
});
