*deps: projectService, account
*template: null

elem = $ element

scope.user = account.user
scope.project = projectService.getById scope.appData.item.id, (item) ->
    if item.profileUserId?
        elem.parent().attr 'title', scope.user.name
    else
        elem.parent().attr 'title', item.name
