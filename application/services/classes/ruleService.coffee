buzzlike.service 'ruleService', (itemService, rpc, communityService) ->

    class classEntity extends itemService

        itemType: 'rule'

        constructor: () ->
            super()
            @byGroupId = {}
            @byCombId = {}

        handleItem: (item) ->
            saved = super item

            if @byGroupId[saved.groupId]?
                @byGroupId[saved.groupId].push saved if @byGroupId[saved.groupId].indexOf(saved) == -1

            if @byCombId[saved.combId]?
                @byCombId[saved.combId].push saved if @byCombId[saved.combId].indexOf(saved) == -1

            saved

        save: (save, cb) ->
            for gId,arr of @byGroupId
                removeElementFromArray save, arr
            super save, cb

        removeCache: (id) ->
            item = @storage[id]
            removeElementFromArray item, @byGroupId[item.groupId] if item?.groupId?
            removeElementFromArray item, @byCombId[item.combId] if item?.combId?
            super id

        fetchByGroupId: (groupId, cb) ->
            if !@byGroupId[groupId]?
                @byGroupId[groupId] = []
                @query
                    groupId: groupId
                , (result) ->
                    cb? @byGroupId[groupId]
            else
                cb? @byGroupId[groupId]
            @byGroupId[groupId]

        getByCombId: (combId, cb) ->
            if !@byCombId[combId]?
                @byCombId[combId] = []
                @query
                    combId: combId
                , (result) ->
                    cb? @byCombId[combId]
            else
                cb? @byCombId[combId]
            @byCombId[combId]

        removeByGroupId: (groupId, cb) ->
            rpc.call @itemType + '.removeByGroupId', groupId, (result) ->
                cb? result

        removePlaceholders: (list, cut = false, cb) ->
            rpc.call @itemType + '.removePlaceholders',
                items: list
                cut: cut
            , (result) ->
                cb? result

        fill: (data, cb) ->
            rpc.call @itemType + '.fill', data, (result) ->
                cb? result

        getPlaceholder: (phId, ruleId, communityId) ->
            rule = @storage[ruleId]

            if !rule?
                return null

            communityItem = communityService.getById communityId if communityId?

            placeholder =
                type: 'placeholder'
                rule: rule
                ruleType: rule.ruleType
                groupId: rule.groupId
                id: phId
                communityId: communityId
                socialNetwork: communityItem?.socialNetwork

            switch rule.ruleType
                when 'single'
                    placeholder.timestamp = rule.timestampStart
                when 'chain'
                    newLength = rule.interval * phId * MIN
                    placeholder.timestamp = rule.timestampStart + newLength
                when 'daily'
                    day = 24 * 60 * MIN
                    placeholder.timestamp = (day * phId) + rule.timestampStart

            placeholder

        getNextPlaceholders: (communityId, timeStart, cb) ->
            true

    new classEntity()
