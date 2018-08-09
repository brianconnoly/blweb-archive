*deps: communityService

scope.communities = communityService.getByIds scope.communityIds

scope.pick = (id) ->
    # if !scope.value.length?
    #     scope.value = []
    #
    if id not in scope.postParams.pickedCommunities
        scope.postParams.pickedCommunities.push id
    else
        removeElementFromArray id, scope.postParams.pickedCommunities
    # scope.setNewValue

scope.picked = (id) ->
    id in scope.postParams.pickedCommunities
