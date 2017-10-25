const { GraphQLObjectType, GraphQLSchema } = require('graphql');
const graphqlHTTP = require('express-graphql');
const EventGraph = require('../../graph/events');
const UserGraph = require('../../graph/users');

const query = new GraphQLObjectType({
  name: 'Query',
  description: 'What a Gem',
  fields: () => ({
    event: EventGraph.Field,
    events: EventGraph.Fields,
    user: UserGraph.Field,
    users: UserGraph.Search,
  }),
});

// const mutation = new GraphQLObjectType({
//   name: 'Mutation',
//   fields: {
//     createValue: Value.GraphCreate,
//   },
// });

const schema = new GraphQLSchema({
  query,
  // mutation,
});

module.exports = graphqlHTTP({
  schema,
  graphiql: true,
});
