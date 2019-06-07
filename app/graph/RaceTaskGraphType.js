const {
  GraphQLString,
  GraphQLObjectType,
  GraphQLNonNull,
  GraphQLInt,
  GraphQLBoolean,
  GraphQLList,
} = require('graphql');
const [RaceTask, RaceTasks] = require('../models/racetasks');
const Type = new GraphQLObjectType({
  name: 'RaceTask',
  description: 'RaceTask',
  fields: () => ({
    racetask_id: { type: GraphQLString },
    section: { type: GraphQLString },
    type: { type: GraphQLString },
    task: { type: GraphQLString },
    slug: { type: GraphQLString },
    descr: { type: GraphQLString },
    points: { type: GraphQLString },
    note: { type: GraphQLString },
    active: { type: GraphQLString },
    address: { type: GraphQLString },
    geopoint: { type: GraphQLString },
    attendee_max: { type: GraphQLString },
    global_max: { type: GraphQLString },
    submissions: { type: GraphQLString },
    year: { type: GraphQLString },
  }),
});
module.exports = Type;
