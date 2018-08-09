buzzlike.service 'scheduleService', (itemService, rpc, actionsService) ->

    class classEntity extends itemService

        itemType: 'schedule'

        constructor: () ->
            super()
            @byPostId = {}

            @storageMap = {}
            @dayCommunity = {}
            @weekCommunity = {}
            @monthCommunity = {}

            @handler = null
            @fetchData = {}

        fetchDayOptimized: (ts, cId) ->
            if !@fetchData[ts]?
                @fetchData[ts] = []
            @fetchData[ts].push cId

            if !@handler?
                @handler = setTimeout =>
                    for k,v of @fetchData
                        @query
                            timestamp:
                                $gte: k*1
                                $lte: k*1 + DAY
                            communityId:
                                $in: v
                , 500

        getCommunityDay: (timestamp, communityId) ->
            if !@dayCommunity[timestamp]?
                @dayCommunity[timestamp] = {}
            if !@dayCommunity[timestamp][communityId]?
                @dayCommunity[timestamp][communityId] = []
                # @query
                #     timestamp:
                #         $gte: timestamp
                #         $lte: timestamp + DAY
                #     communityId: communityId
                @fetchDayOptimized timestamp, communityId

            @dayCommunity[timestamp][communityId]

        getCommunityWeek: (timestamp, communityId) ->
            if !@weekCommunity[timestamp]?
                @weekCommunity[timestamp] = {}
            if !@weekCommunity[timestamp][communityId]?
                @weekCommunity[timestamp][communityId] = []

            @weekCommunity[timestamp][communityId]

        getCommunityMonth: (timestamp, communityId) ->
            if !@monthCommunity[timestamp]?
                @monthCommunity[timestamp] = {}
            if !@monthCommunity[timestamp][communityId]?
                @monthCommunity[timestamp][communityId] = []

            @monthCommunity[timestamp][communityId]

        handleItem: (item) ->
            saved = super item

            if !@byPostId[saved.postId]?
                @byPostId[saved.postId] = []
            @byPostId[saved.postId].push saved if @byPostId[saved.postId].indexOf(saved) == -1

            dateObj = new Date saved.timestamp
            dayTs = new Date(dateObj.getFullYear(), dateObj.getMonth(), dateObj.getDate()).getTime()
            monthTs = new Date(dateObj.getFullYear(),dateObj.getMonth(),1).getTime()

            weekDay = dateObj.getDay()
            weekDay--
            weekDay = 6 if weekDay < 0
            weekTs = new Date(dateObj.getFullYear(), dateObj.getMonth(),dateObj.getDate()-weekDay).getTime()

            if @storageMap[saved.id+'day']?
                removeElementFromArray saved, @storageMap[saved.id+'day']
                delete @storageMap[saved.id+'day']
            if @storageMap[saved.id+'week']?
                removeElementFromArray saved, @storageMap[saved.id+'week']
                delete @storageMap[saved.id+'week']
            if @storageMap[saved.id+'month']?
                removeElementFromArray saved, @storageMap[saved.id+'month']
                delete @storageMap[saved.id+'month']

            if !@dayCommunity[dayTs]?
                @dayCommunity[dayTs] = {}
            if !@dayCommunity[dayTs][saved.communityId]?
                @dayCommunity[dayTs][saved.communityId] = []
            @dayCommunity[dayTs][saved.communityId].push saved if saved not in @dayCommunity[dayTs][saved.communityId]
            @storageMap[saved.id+'day'] = @dayCommunity[dayTs][saved.communityId]

            if !@weekCommunity[weekTs]?
                @weekCommunity[weekTs] = {}
            if !@weekCommunity[weekTs][saved.communityId]?
                @weekCommunity[weekTs][saved.communityId] = []
            @weekCommunity[weekTs][saved.communityId].push saved if saved not in @weekCommunity[weekTs][saved.communityId]
            @storageMap[saved.id+'week'] = @weekCommunity[weekTs][saved.communityId]

            if !@monthCommunity[monthTs]?
                @monthCommunity[monthTs] = {}
            if !@monthCommunity[monthTs][saved.communityId]?
                @monthCommunity[monthTs][saved.communityId] = []
            @monthCommunity[monthTs][saved.communityId].push saved if saved not in @monthCommunity[monthTs][saved.communityId]
            @storageMap[saved.id+'week'] = @monthCommunity[monthTs][saved.communityId]

            saved

        removeCache: (id) ->
            item = @storage[id]
            if item?
                removeElementFromArray item, @byPostId[item.postId]
            super id

        removeReposts: (postId, cb) ->
            rpc.call @itemType + '.removeReposts', postId, (result) ->
                cb? result

        fetchByPostId: (postId, cb) ->
            if !@byPostId[postId]?
                @byPostId[postId] = []

            @query
                postIds: [postId]
            , (items) ->
                cb? items

            @byPostId[postId]

        getByPostId: (postId) ->
            if !@byPostId[postId]?
                @byPostId[postId] = []

            @byPostId[postId].empty = true
            @byPostId[postId]

        getOriginalByPostId: (postId, cb, force = false) ->
            preloaded = @byPostId[postId]?.empty

            for sched in @getByPostId(postId)
                if sched.scheduleType == 'post'
                    cb? sched
                    return sched

            if preloaded != true and force == false
                return

            delete @byPostId[postId].empty

            # Fetch
            @query
                scheduleType: 'post'
                postId: postId
                limit: 1
            , (items) ->
                if items[0]?
                    cb? items[0]
                    return
                else
                    cb? null

            null

        repost: (data, cb) ->
            rpc.call 'schedule.repost', data, (repostItem) =>
                cb? @handleItem repostItem

        updateOriginal: (data, cb) ->
            rpc.call 'schedule.updateOriginal', data, (result) =>
                cb? @handleItem result

        clonePost: (data, cb) ->
            rpc.call 'schedule.clonePost', data, (result) =>
                cb? @handleItems result

        sendNow: (schedId, cb) ->
            @call 'sendNow', schedId, cb

        init: () ->
            super()

    new classEntity()
