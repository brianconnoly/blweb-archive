*deps: itemService, account, rpc

class classEntity extends itemService
    itemType: 'streamItem'

    init: () ->
        @byStreamId = {}
        @streamFetched = {}
        @streamLastPage = {}
        @streamTotal = {}
        @lastMessages = {}
        super()

    getByStreamId: (streamId, cb) ->
        if @streamFetched[streamId] == true
            return @byStreamId[streamId]

        @streamFetched[streamId] = true
        @streamLastPage[streamId] = 0
        @streamTotal[streamId] = null

        if !@byStreamId[streamId]?
            @byStreamId[streamId] = []
        @query
            parentsId: streamId
            limit: 40
            page: @streamLastPage[streamId]
            sortBy: 'created'
            sortType: 'DESC'
        , (items, total) =>
            @streamTotal[streamId] = total
            cb? items, total
        @byStreamId[streamId]

    nextPageByStreamId: (streamId, cb) ->
        if @streamTotal[streamId]? and @byStreamId[streamId].length >= @streamTotal[streamId]
            cb? [], @streamTotal[streamId]
            return @byStreamId[streamId]

        @streamLastPage[streamId]++

        @query
            parentsId: streamId
            limit: 40
            page: @streamLastPage[streamId]
            sortBy: 'created'
            sortType: 'DESC'
        , (items, total) =>
            @streamTotal[streamId] = total
            cb? items, total

        @byStreamId[streamId]

    handleItem: (item) ->
        handled = super item

        for parent in handled.parents
            if @lastMessages[parent.id]? and handled.created > @lastMessages[parent.id].created
                @lastMessages[parent.id] = handled

        for parent in handled.parents
            if !@byStreamId[parent.id]?
                @byStreamId[parent.id] = []
            if handled not in @byStreamId[parent.id]
                @byStreamId[parent.id].push handled
                @byStreamId[parent.id].sort (a,b) ->
                    if a.created < b.created
                        return -1
                    if a.created > b.created
                        return 1
                    0
        handled

    getLastMessage: (streamId, cb) ->
        if @lastMessages[streamId]?
            cb? @lastMessages[streamId]
            return @lastMessages[streamId]

        @call 'getLastMessage',
            id: streamId
        , (item) =>
            if item?.id?
                @lastMessages[streamId] = item
            cb? item

new classEntity()
