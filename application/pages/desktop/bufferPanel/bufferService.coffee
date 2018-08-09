buzzlike.service 'buffer', (actionsService, stateManager, operationsService, account, localStorageService) ->

    class bufferService

        constructor: () ->
            @body = $ 'body'

            @showed = false
            @width = 220
            @size = 'mini'

            # @buffer = [
            #         title: 'content'
            #         color: 'rgba(139,179,83,0.5)'
            #         types: ['image','text','folder','audio','video','url']
            #         items: []
            #     ,
            #         title: 'lot'
            #         color: 'rgba(65,70,70,0.5)'
            #         types: ['lot']
            #         items: []
            #     ,
            #         title: 'post'
            #         color: 'rgba(95,158,195,0.5)'
            #         types: ['post']
            #         items: []
            #     ,
            #         title: 'comb'
            #         color: 'rgba(252,205,97,0.5)'
            #         types: ['comb']
            #         items: []
            #     ,
            #         title: 'team'
            #         color: 'rgb(0,85,133)'
            #         types: ['team']
            #         items: []
            # ]
            @buffer = [
                color: 'rgba(139,179,83,0.5)'
                items: []
                type: 'rightPanel'
            ]
            @byType = {}

            @currentPocket = null

            # for buffer in @buffer
            #     for type in buffer.types
            #         @byType[type] =
            #             items: buffer.items
            #             buffer: buffer

            @actions = []
            @lowerActions = []

            @activeTypes = []

            contentPanelable = 'content/comb/post/schedule/task/team/user'



            true

        recountTypes: ->
            return true

            was = @activeTypes.length
            @activeTypes.length = 0
            for buffer in @buffer
                if buffer.items.length > 0
                    @activeTypes.push buffer

            if @currentPocket?.items?.length == 0
                @currentPocket = null
                if @activeTypes.length > 0
                    @currentPocket = @activeTypes[0]

            if was != @activeTypes.length
                @recountHead()
            @prepareActions()
            true

        setPocket: (pocket) ->
            if @currentPocket == pocket
                return

            @currentPocket = pocket
            @recountHead()
            @recountSize()
            @prepareActions()
            true

        addPocket: ->
            @currentPocket =
                items: []
                type: 'rightPanel'

            @buffer.push @currentPocket
            @recountHead()
            @saveState()
            @currentPocket

        closePocket: (pocket) ->
            if @buffer.length == 1
                if @buffer[0].items.length == 0
                    @showed = false
                else
                    @buffer[0].items.length = 0
            else
                index = @buffer.indexOf pocket

                removeElementFromArray pocket, @buffer

                if index > @buffer.length - 1
                    index = @buffer.length - 1

                @currentPocket = @buffer[index]

            @recountHead()
            @recountSize()
            @prepareActions()
            @saveState()

        addItem: (item) -> @addItems [item]

        addItems: (items, buffer) ->
            if !buffer?
                if !@showed and @buffer.length < 5 and !(@buffer.length == 1 and @buffer[0]?.items?.length == 0)
                    @currentPocket =
                        color: 'rgba(139,179,83,0.5)'
                        items: []
                        type: 'rightPanel'

                    @buffer.push @currentPocket
                    @recountHead()

                if @buffer.length == 0
                    @currentPocket =
                        color: 'rgba(139,179,83,0.5)'
                        items: []
                        type: 'rightPanel'

                    @buffer.push @currentPocket
                    @recountHead()

                if !@currentPocket?
                    @currentPocket = @buffer[@buffer.length - 1]
            else
                @currentPocket = buffer

            @showed = true

            for item in items
                # if !@byType[item.type]?.items?
                #     continue
                # @byType[item.type].items.push item if item not in @byType[item.type].items
                # @currentPocket = @byType[item.type].buffer
                if item.type == 'schedule'
                    item = operationsService.get 'post', item.postId
                @currentPocket.items.push item if item not in @currentPocket.items

            # if @size == 'full'
            @recountSize()

            @saveState()
            @prepareActions @currentPocket.items if @currentPocket?.items?
            @recountTypes()
            true

        removeItem: (item, current = false) -> @removeItems [item], current

        removeItems: (items, current) ->
            for item in items
                # if !@byType[item.type]?.items?
                #     continue
                if current
                    removeElementFromArray item, @currentPocket.items
                else
                    for buffer in @buffer
                        removeElementFromArray item, buffer.items

            @recountSize()
            @saveState()
            @recountTypes()
            true

        clearCurrentPocket: () ->
            if !@currentPocket?.items?.length > 0
                if @activeTypes.length == 0
                    @showed = false

            @currentPocket?.items?.length = 0
            @saveState()
            @recountTypes()
            true

        prepareActions: () ->
            return true

            @actions.length = 0
            @lowerActions.length = 0

            if !@currentPocket?.items?
                return

            list = actionsService.getActions
                source: @currentPocket.items
                # context: status.context[mode]
                target: stateManager.getContext()
                actionsType: 'rightPanel'

            maxActions = ( $('body').height() * 0.2 ) / 34 | 0
            if maxActions < 5 then maxActions = 5

            list.sort (a,b) ->
                if a.priority > b.priority
                    return -1
                if a.priority < b.priority
                    return 1
                0

            for item in list
                if list.length > maxActions + 1 and @actions.length >= maxActions
                    @lowerActions.unshift item
                else
                    @actions.unshift item

            # if !status.context[mode]?
            @actions.push
                phrase: 'rightpanel_action_clearpanel'
                leaveItems: true
                action: (e) =>
                    @clearCurrentPocket()

            true

        saveState: () ->
            if !account?.user?.id?
                return

            toSave = []
            for buffer in @buffer
                # toSave[buffer.title] = []
                arr = []
                toSave.push arr
                for item in buffer.items
                    arr.push
                        id: item.id
                        type: item.type

            data =
                items: toSave
                current: @buffer.indexOf @currentPocket
                showed: @showed
                width: @width

            str = JSON.stringify data
            localStorageService.add 'buffer_' + account.user.id, str

        readState: () ->
            if !account?.user?.id?
                return

            str = localStorageService.get 'buffer_' + account.user.id

            if str?.length > 0
                data = JSON.parse str

                @showed = data.showed
                @width = data.width

                @buffer.length = 0

                for buf in data.items
                    items = []
                    for itemData in buf
                        item = operationsService.get itemData.type, itemData.id
                        items.push item if item not in items

                    @buffer.push
                        items: items
                        type: 'rightPanel'

                # for buffer in @buffer
                #     if data.items?[buffer.title]?
                #         for itemData in data.items[buffer.title]
                #             item = operationsService.get itemData.type, itemData.id
                #             buffer.items.push item if item not in buffer.items

                #     if buffer.title == data.current
                #         @currentPocket = buffer
                @currentPocket = @buffer[data.current]

                @recountSize()
                @recountHead()

            # if @currentPocket?.items?
            #     ids = []
            #     for item in @currentPocket.items
            #         ids.push item.id
            #     operationsService.getByIds @currentPocket.title, ids, () =>
            #         @prepareActions @currentPocket.items if @currentPocket?.items?
            #         @recountTypes()
            #         @recountSize()
            true

        recountHead: () ->
            maxWid = @width
            if @buffer.length < 5
                maxWid -= 40
            activeWidth = 65

            switch @width
                when 112
                    activeWidth = 30
                when 220
                    activeWidth = 80
                when 324
                    activeWidth = 124
                when 430
                    activeWidth = 150

            if activeWidth * @buffer.length > maxWid
                # Do collapce
                wid = (maxWid - activeWidth) / (@buffer.length - 1) | 0
                for activeType,i in @buffer
                    if activeType == @currentPocket
                        activeType.width = activeWidth
                        activeType.text = '#000'
                    else
                        activeType.width = wid
                        activeType.text = 'transparent'
            else
                # align
                wid = maxWid / @buffer.length | 0
                for activeType,i in @buffer
                    if i == @buffer.length - 1
                        # last
                        activeType.width = maxWid - (wid * i)
                        activeType.text = '#000'
                    else
                        activeType.width = wid
                        activeType.text = '#000'

        recountSize: () ->
            if @width in [112,324]
                @size = 'mini'
            else
                hei = @body.height()
                max = Math.ceil(hei / 140) * (if @width == 430 then 2 else 1)

                if @currentPocket?.items?.length > max
                    @size = 'mini'
                else
                    @size = 'full'

        setWidth: (width) ->
            @width = width
            @recountSize()
            @recountHead()
            @saveState()

        toggleShow: () ->
            @showed = !@showed
            @saveState()
    new bufferService()
