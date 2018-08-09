buzzlike.service 'favouriteService', (itemService, rpc) ->

    class classEntity extends itemService

        itemType: 'favourite'

        constructor: () ->
            super()

            @byLotId = {}
            @byPostId = {}

        handleItem: (item) ->
            saved = super item

            @byPostId[saved.postId] = saved if saved.postId?
            @byLotId[saved.lotId]   = saved if saved.lotId?
            saved

        removeCache: (id) ->
            item = @storage[id]
            if item.postId? and @byPostId[item.postId]? then delete @byPostId[item.postId]
            if item.lotId?  and @byLotId[item.lotId]?   then delete @byLotId[item.lotId]
            super id

        deleteByPostId: (postId, cb) -> @call 'deleteByPostId', postId, cb
        deleteByLotId: (lotId, cb)   -> @call 'deleteByLotId',  lotId,  cb

        triggerLotId: (lotId, cb)    -> @call 'triggerLotId',   lotId,  (result) -> if result.id? then cb? @handleItem result else cb? result
        triggerPostId: (postId, cb)  -> @call 'triggerPostId',  postId, (result) -> if result.id? then cb? @handleItem result else cb? result

        fetchMy: (cb) ->
            @query {}, (items, total) =>
                cb? items, total

    new classEntity()
