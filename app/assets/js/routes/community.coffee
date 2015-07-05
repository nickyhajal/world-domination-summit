ap.Routes.community = (community) ->
  if community == 'community'
    ap.Routes.defaultRoute('community')
  else
    ap.goTo('community', {interest: community})


