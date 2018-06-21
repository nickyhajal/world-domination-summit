const {
  GraphQLString,
  GraphQLObjectType,
  GraphQLNonNull,
  GraphQLBoolean,
  GraphQLInt,
  GraphQLList,
} = require('graphql');
const [UserNote, UserNotes] = require('../models/user_notes');
const UserNoteGraphType = require('./UserNoteGraphType');

const Type = UserNoteGraphType;
const Add = {
  type: Type,
  args: {
    user_id: { type: GraphQLString },
    about_id: { type: GraphQLString },
    note: { type: GraphQLString },
    admin: { type: GraphQLString },
  },
  resolve: async (obj, { user_id, about_id, note, admin }) => {
    const row = await UserNote.forge({
      user_id,
      about_id,
      note,
      admin,
      year: process.year,
    }).save();
    return row.attributes;
  },
};

module.exports = {
  Type,
  Add,
};
