ap.Routes.community = (community) ->
  tk 'HEY'
  tk community
  ap.goTo('community_hub', {interest: community})


