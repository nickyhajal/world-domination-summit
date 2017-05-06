const {
  GraphQLString,
  GraphQLObjectType,
  GraphQLNonNull,
  GraphQLInt,
  GraphQLList,
} = require('graphql');

const Type = new GraphQLObjectType({
  name: 'User',
  description: 'User',
  fields: () => ({
    user_id: { type: GraphQLString },
    attending14: { type: GraphQLInt },
    attending15: { type: GraphQLInt },
    attending16: { type: GraphQLInt },
    attending17: { type: GraphQLInt },
    pre17: { type: GraphQLInt },
    ticket_type: { type: GraphQLString },
    type: { type: GraphQLString },
    first_name: { type: GraphQLString },
    last_name: { type: GraphQLString },
    user_name: {
      type: GraphQLString,
      resolve: row => {
        const u = row.user_name;
        if (u === undefined) return '';
        return u.length === 40 ? '' : u;
      },
    },
    email_hash: { type: GraphQLString },
    facebook: { type: GraphQLString },
    twitter: { type: GraphQLString },
    instagram: { type: GraphQLString },
    location: { type: GraphQLString },
    lat: { type: GraphQLString },
    lon: { type: GraphQLString },
    distance: { type: GraphQLString },
    academy: { type: GraphQLString },
    created_at: { type: GraphQLString },
    updated_at: { type: GraphQLString },
  }),
});
const Field = {
  type: Type,
  args: {
    id: { type: GraphQLString },
  },
  resolve: async (root, args) => {
    const row = await User.forge({
      user_id: args.id,
    }).fetch();
    return row.attributes;
  },
};
// const Create = {
//   type: Type,
//   args: {
//     value: {
//       description: 'The value name',
//       type: new GraphQLNonNull(GraphQLString),
//     },
//   },
//   resolve: async (obj, { value }) => {
//     const existing = await Value.forge({
//       value,
//     }).fetch();
//     if (existing) {
//       return Object.assign({}, { ...existing.attributes }, { existing: true });
//     }
//     const row = await Value.forge({
//       value,
//     }).save();
//     return row.attributes;
//   },
// };
const Fields = {
  type: new GraphQLList(Type),
  // args: {
  //   q: { type: GraphQLString },
  // },
  resolve: async (root, args) => {
    const rows = await Events.forge().query();
    return rows.models.map(row => row.attributes);
  },
};

module.exports = {
  Type,
  Field,
  // Create,
  Fields,
};
