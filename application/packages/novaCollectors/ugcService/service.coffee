*deps: itemService, rpc, actionsService, account, novaWizard, contentService

class classEntity extends itemService

    itemType: 'ugc'

    constructor: ->
        super()
        @byCombId = {}

    getByCombId: (combId, cb) ->
        if !@byCombId[combId]?
            @byCombId[combId] = []
            @query
                combIds: combId
            , (result) ->
                cb? @byCombId[combId]
        else
            cb? @byCombId[combId]
        @byCombId[combId]

    handleItem: (item) ->
        saved = super item

        if saved.combIds?.length > 0 then for combId in saved.combIds
            if @byCombId[combId]?
                @byCombId[combId].push saved if @byCombId[combId].indexOf(saved) == -1
        saved

    removeCache: (id) ->
        item = @storage[id]
        if saved.combIds?.length > 0 then for combId in saved.combIds
            removeElementFromArray item, @byCombId[combId]
        super id

    fetchMy: (cb) ->
        @call 'getMy', (items) =>
            cb @handleItems items

    init: () ->
        # Operations
        super()

        actionsService.registerAction
            sourceType: 'content'
            phrase: 'propose'
            targetType: 'ugc'
            action: (data) =>
                @call 'proposePost',
                    items: data.ids
                    ugcId: data.target.id

        actionsService.registerAction
            sourceType: 'ugc'
            phrase: 'delete'
            action: (data) =>
                @deleteByIds data.ids

        actionsService.registerAction
            sourceType: 'community'
            phrase: 'create_ugc_collector'
            action: (data) =>
                for comm in data.items
                    link = ""
                    switch comm.communityType
                        when 'profile'
                            link += 'id'
                        when 'group', 'page'
                            link += 'club'
                        when 'event'
                            link += 'event'

                    link += Math.abs comm.socialNetworkId*1

                    @create
                        communityId: comm.id
                        link: link
                        userId: account.user.id

        novaWizard.register 'collector',
            type: 'simple'
            action: (data) =>
                @create
                    type: 'ugc'
                    name: 'Новая коллекция'
                    projectId: data.projectId
                    combIds: if data.combId then [data.combId]
                , (ugcItem) ->
                    true

new classEntity()
