*deps: communityService

if !scope.wizard.data.name?
    communityService.getById scope.wizard.data.communityIds[scope.wizard.data.communityIds.length-1], (commItem) ->
        scope.wizard.data.name = commItem.name
