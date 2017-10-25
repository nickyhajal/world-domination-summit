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
const UserGraph = require('./users');
const TransactionGraphType = require('./TransactionGraphType');

const Type = TransactionGraphType;
// const Field = {
//   type: Type,
//   args: {
//     id: { type: GraphQLString },
//   },
//   resolve: async (root, { id }) => {
//     console.log(id);
//     const row = await Users.forge().getUser(id);
//     console.log(row.attributes);
//     return row.attributes;
//   },
// };
// const Fields = {
//   type: new GraphQLList(Type),
//   resolve: async (root, args) => {
//     const rows = await Events.forge().query();
//     return rows.models.map(row => row.attributes);
//   },
// };

module.exports = {
  Type,
  // Field,
  // Search,
  // // Create,
  // Fields,
};
