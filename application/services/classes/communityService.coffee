buzzlike.service 'communityService', (itemService, $rootScope, account, actionsService) ->

    class classEntity extends itemService

        itemType: 'community'

        constructor: ->
            super()
            
            actionsService.registerParser 'community', (item) ->
                types = []
                for acc in account.user.accounts
                    if !acc.writableCommunities?
                        continue
                    if item.id in acc.writableCommunities
                        types.push 'myCommunity'
                        break

                if types.length == 0
                    types.push 'notMyCommunity'
                types

        getByPublicId: (data, cb) ->
            @call 'getByPublicId', data, (result) =>
                if result?
                    cb? @handleItem result

        handleItem: (item) ->
            if !item.photo or item.photo in ['http://vk.com/resources/images/community_200.gif']
                item.photo = $rootScope.defaultCommunityImage
            item.photo = $rootScope.proxyImage item.photo
            super item

        loadCommunities: (cb) ->
            rpc.call 'user.refreshCommunities', (user) =>
                if user.err?
                    cb? user
                    return

                account.update user, =>
                    toUpdate = []
                    for acc in user.accounts
                        # blog "!!!!", acc.writableCommunities.length, acc.writableCommunities
                        toUpdate = toUpdate.concat acc.writableCommunities
                    @getByIds toUpdate, cb

    new classEntity()