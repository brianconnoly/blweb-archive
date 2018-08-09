*deps: actionsService, socketAuth, localStorageService, dynamicStyle, operationsService, novaDragHelper

typesAllowed = 'content/comb/post/schedule/task/team/user'

class novaBuffer

    initActions: ->
        actionsService.registerAction
            sourceType: typesAllowed
            targetType: 'buffer'
            phrase: 'take_to_right'
            category: 'E'
            leaveItems: true
            check2: (data) ->
                if data.sourceContext?.type == 'buffer'
                    return data.sourceContext != data.target
                else
                    true
            action: (data) =>
                if data.sourceContext?.type == 'buffer'
                    for item in data.items
                        removeElementFromArray item, data.sourceContext.items
                @addItems data.items
                true

        actionsService.registerAction
            sourceType: typesAllowed
            targetType: 'newBuffer'
            phrase: 'take_to_new_pocket'
            restrict: 'rightPanel'
            category: 'E'
            leaveItems: true
            check2: (data) =>
                @pockets.length < 5
            action: (data) =>
                if data.sourceContext?.type == 'buffer'
                    for item in data.items
                        removeElementFromArray item, data.sourceContext.items
                @addItems data.items, @addPocket()
                true

        actionsService.registerAction
            category: "E"
            sourceType: typesAllowed
            phrase: "take_to_right"
            priority: "24"
            restrict: "rightPanel"
            check2: (data) ->
                data.sourceContext?.type != 'buffer'
            action: (data) =>
                @addItems data.items

        actionsService.registerAction
            sourceType: typesAllowed
            phrase: 'take_to_new_pocket'
            restrict: 'rightPanel'
            category: 'E'
            leaveItems: true
            check2: (data) =>
                @pockets.length < 5
            action: (data) =>
                if data.sourceContext?.type == 'buffer'
                    for item in data.items
                        removeElementFromArray item, data.sourceContext.items
                @addItems data.items, @addPocket()
                true

        actionsService.registerAction
            sourceType: typesAllowed
            phrase: 'remove_from_right'
            only: 'contextMenu'
            sourceContext: 'buffer'
            category: 'E'
            action: (data) =>
                @removeItems data.items
                true

    initPockets: ->
        @pockets = []
        @currentPocket =
            items: []
            type: 'buffer'
        @pockets.push @currentPocket

        # Restore user buffer pockets
        socketAuth.onAuth =>
            @pockets.length = 0
            saved = localStorageService.get 'bufferState_' + socketAuth.session.user_id
            obj = JSON.parse saved

            if obj?.pockets?
                for pocket in obj.pockets
                    newPocket = @addPocket false
                    for item in pocket.items
                        newPocket.items.push operationsService.get item.type, item.id
                @currentPocket = @pockets[obj.active]
            else
                @currentPocket =
                    items: []
                    type: 'buffer'
                @pockets.push @currentPocket

            @setWidth obj.width, false if obj?.width?
            if obj?.showed
                @trigger false
            true

    saveState: ->
        toSave =
            active: 0
            width: @width
            showed: @showed
            pockets: []

        for pocket in @pockets
            items = []
            for item in pocket.items
                if !item.type?
                    console.log 'NO TYPE WARNING!', @
                    return
                items.push
                    type: item.type
                    id: item.id
            toSave.pockets.push
                items: items

        toSave.active = @pockets.indexOf @currentPocket
        localStorageService.add 'bufferState_' + socketAuth.session.user_id, JSON.stringify toSave

    constructor: ->
        @showed = false
        @width = 100

        @style = new dynamicStyle '.novaBuffer .tabContents .novaItem'
        @styleFrame = new dynamicStyle '.novaBuffer .tabContents'

        @initPockets()
        @initActions()
        true

    # Pockets stuff
    addPocket: (noSave = false) ->
        pocket =
            items: []
            type: 'buffer'
        @pockets.push pocket
        @activatePocket pocket
        @saveState() if !noSave
        @updateHeadSize()
        pocket

    closePocket: (pocket) ->
        removeElementFromArray pocket, @pockets
        if @pockets.length == 0
            @addPocket()
            @trigger()
        if @currentPocket == pocket
            @currentPocket = @pockets[0]
        @updateHeadSize()
        @saveState()

    activatePocket: (pocket) ->
        @currentPocket = pocket
        @updateHeadSize()
        @saveState()

    mousePocket: (pocket) ->
        if novaDragHelper.active
            @activatePocket pocket

    # items stuff
    addItems: (items, pocket = @currentPocket) ->
        for item in items
            pocket.items.push item if item not in pocket.items
        @saveState()

    removeItem: (item) ->
        removeElementFromArray item, @currentPocket.items
        @saveState()

    removeItems: (items) ->
        for item in items
            removeElementFromArray item, @currentPocket.items
        @saveState()

    # Element stuff
    setElement: (@element, @scope) ->
        @element.css 'width', @width
        if @showed
            @element.css 'right', 0
        else
            @element.css 'right', -@width
    setWidth: (@width, noSave = false) ->
        @element?.css 'width', @width
        @updateItemSize()
        @updateHeadSize()
        @saveState() if !noSave
    trigger: (noSave = false) ->
        @showed = !@showed
        if @showed
            @element?.css 'right', 0
        else
            @element?.css 'right', -@width
        @saveState() if !noSave
        true

    updateHeadSize: ->
        pockets = @pockets.length

        wid = @width
        if pockets < 5
            wid -= 30

        tabWid = wid / pockets
        activeWid = tabWid
        if tabWid < 50
            tabWid = (wid - 50) / (pockets - 1) | 0
            activeWid = wid - tabWid * (pockets - 1)

        for pocket in @pockets
            pocket.width = tabWid
        @currentPocket.width = activeWid

    minMargin = 20
    updateItemSize: ->
        wid = 80
        hei = 60

        perLine = @width / (wid+minMargin) | 0
        rest = @width - (perLine*wid)

        margin = rest / (perLine + 1) | 0
        if margin > 20
            addWid = margin - 20 # | 0
            wid += addWid * (perLine+1) / perLine#* 2
            hei = wid / 4 * 3 | 0
            margin -= addWid
        margin /= 2

        verticalMargin = margin * 0.8 | 0

        @style.update "
            width: #{wid}px;
            height: #{hei}px;
            margin: #{verticalMargin}px #{margin}px;
        "

        @styleFrame.update "
            padding: #{verticalMargin}px #{margin}px;
        "
        true

new novaBuffer()
