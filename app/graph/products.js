const {
  GraphQLString,
  GraphQLObjectType,
  GraphQLNonNull,
  GraphQLBoolean,
  GraphQLInt,
  GraphQLList,
} = require('graphql');

const Type = new GraphQLObjectType({
  name: 'Product',
  description: 'Product Type',
  fields: () => ({
    product_id: { type: GraphQLString },
    code: { type: GraphQLString },
    name: { type: GraphQLString },
    descr: { type: GraphQLString },
    cta: { type: GraphQLString },
    cost: { type: GraphQLInt },
    fee: { type: GraphQLInt },
    sales: { type: GraphQLInt },
    max_sales: { type: GraphQLInt },
    created_at: { type: GraphQLString },
    updated_at: { type: GraphQLString },
  }),
});

module.exports = {
  Type,
};
