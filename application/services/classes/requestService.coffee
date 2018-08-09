buzzlike.service 'requestService', (itemService, rpc, account) ->

    class classEntity extends itemService

        itemType: 'request'

        constructor: () ->
            super()

            @requestsFrom = {}
            @requestsTo = {}
            @status = 
                currentLot: null

        handleItem: (item) ->
            saved = super item

            @requestsFrom[saved.id] = saved if saved.fromUserId == account.user.id
            @requestsTo[saved.id]   = saved if saved.toUserId   == account.user.id
            saved

        removeCache: (id) ->
            item = @storage[id]
            if item.fromUserId == account.user.id and @requestsFrom[item.id]? then delete @requestsFrom[item.id]
            if item.toUserId   == account.user.id and @requestsTo[item.id]?   then delete @requestsTo[item.id]
            super id

        cancel: (requestId, cb) ->
            @call 'cancel', requestId, (request) =>
                cb? @handleItem request

        accept: (requestId, cb) ->
            @call 'accept', requestId, (request) =>
                cb? @handleItem request

        reject: (requestId, cb) ->
            @call 'reject', requestId, (request) =>
                cb? @handleItem request

        rejectByUserId: (data, cb) -> @call 'rejectByUserId', data, cb

        makeBet: (data, cb) ->
            @call 'makeBet', data, (request) ->
                cb? @handleItem request

        fetchMy: (data, cb) ->
            result = []
            @query
                fromUserId: account.user.id
            , (itemsFrom) =>
                result.push item for item in itemsFrom

                @query 
                    toUserId: account.user.id
                , (itemsTo) ->
                    result.push item for item in itemsTo

                    cb? result

        fetchNew: (cb) -> 
            @query
                requestStatuses: ['returned', 'created']
                fromUserId: account.user.id
            , cb

        fetchByCommunityId: (communityId, cb) ->
            @query
                communityId: communityId
            , cb

        getCommunities: (cb) -> @call 'getCommunities', cb

        markRead: (communityId, cb) -> @call 'markRead', communityId, cb

    new classEntity()