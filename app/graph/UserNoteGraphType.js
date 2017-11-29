const {
  GraphQLString,
  GraphQLObjectType,
  GraphQLNonNull,
  GraphQLBoolean,
  GraphQLInt,
  GraphQLList,
} = require('graphql');

module.exports = new GraphQLObjectType({
  name: 'UserNote',
  description: 'User Note Type',
  fields: () => {
    return {
      unote_id: { type: GraphQLString },
      user_id: { type: GraphQLString },
      about_id: { type: GraphQLString },
      admin: { type: GraphQLString },
      note: { type: GraphQLString },
      year: { type: GraphQLString },
      created_at: { type: GraphQLString },
      updated_at: { type: GraphQLString },
    };
  },
});
