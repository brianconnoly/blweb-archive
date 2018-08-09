*deps: projectService
*replace: true

scope.$watch 'isInvited', (nVal) ->
    if nVal == true
        scope.unit.unitHeight = 115
    else
        scope.unit.unitHeight = 0
    scope.recountHead()

scope.rejectInvitation = ->
    scope.isInvited = false
    projectService.call 'declineInvite',
        id: scope.project.id
    , ->
        scope.closeApp()
        true

scope.acceptInvitation = ->
    scope.isInvited = false
    projectService.call 'acceptInvite',
        id: scope.project.id
    , ->
        true
