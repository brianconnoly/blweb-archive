*deps: communityService, account, groupService

scope.items = []

if scope.wizard.data.accountPublicId?
    for acc in account.user.accounts
        if acc.publicId == scope.wizard.data.accountPublicId
            communityService.getByIdsOptimized acc.writableCommunities, (items) ->
                for item in items
                    scope.items.push item

else if scope.wizard.data.channelId?
    scope.channelCommunities = true
    groupService.getById scope.wizard.data.channelId, (group) ->
        ids = []
        for feed in group.feeds
            ids.push feed.communityId

        communityService.getByIdsOptimized ids, (items) ->
            for item in items
                scope.items.push item

scope.pickAll = ->
    picked = false
    for item in scope.items
        if scope.wizard.data[scope.step.variable]?.length?
            if item.id in scope.wizard.data[scope.step.variable]
                continue
        picked = true
        scope.pick item

    if picked == false
        scope.flush()
