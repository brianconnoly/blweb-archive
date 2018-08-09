*deps: projectService, userService, account

scope.items = []
updateItems = ->
    scope.items.length = 0
    # scope.items.push account.user

    # Pick project with ability to create channels
    for id,project of projectService.storage
        if project.blank == true
            continue

        if project.id == scope.wizard.data.projectId
            scope.wizard.pick project

        for member in project.members
            if member.userId == account.user.id
                scope.items.push project
                break

scope.$watch ->
    projectService.storage
, (nVal) ->
    updateItems()
, true
