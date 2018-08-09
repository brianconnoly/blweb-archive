*deps: streamItemService, account, operationsService, novaWizard, novaMenu

elem = $ element
addItems = $ elem.find('.addItems')[0]
historyView = $ elem.find('.historyView')[0]

# Frame params
scope.flowFrame.maxWidth = 500

scope.parentId = scope.flowFrame.item.id

scope.streamItems = streamItemService.getByStreamId scope.flowFrame.item.id
scope.streamParentItem = operationsService.get (scope.flowFrame.item.type or 'stream'), scope.flowFrame.item.id
scope.message = ""

scope.loadingInProgress = false
historyView.on 'mousewheel', (e, delta) ->
    if !scope.loadingInProgress and historyView[0].scrollTop < 200
        scope.loadingInProgress = true
        # oldHei = historyView[0].scrollHeight
        streamItemService.nextPageByStreamId scope.flowFrame.item.id, ->
            scope.loadingInProgress = false
            # setTimeout ->
            #     console.log oldHei, historyView[0].scrollHeight
            # , 0

        scope.$applyAsync()

scope.$watch 'streamItems', (nVal) ->
    oldHei = historyView[0].scrollHeight
    setTimeout ->
        # console.log historyView[0].scrollTop, historyView[0].scrollTop + historyView[0].scrollHeight - oldHei
        historyView[0].scrollTop = historyView[0].scrollTop + historyView[0].scrollHeight - oldHei
    , 0
, true

scope.doSend = ->
    if scope.message.length > 0 or scope.streamMessage.items.length > 0
        entities = []
        for item in scope.streamMessage.items
            entities.push
                id: item.id
                type: item.type

        streamItemService.create
            parent:
                id: scope.flowFrame.item.id
                type: scope.flowFrame.item.type or 'stream'
            value: scope.message
            entities: entities
        , ->
            true
        scope.message = ""
        scope.streamMessage.items.length = 0

scope.onFocus = (e) ->
    flushUnread()

scope.onActivate = ->
    flushUnread()

scope.keyDown = (e) ->
    flushUnread()
    if e.which == 13 and !e.shiftKey
        scope.doSend()

scope.orderFunc = (item) ->
    item.created

# Formated output
scope.smartItems = []
scope.$watch 'streamItems', (nVal) ->
    scope.smartItems.length = 0

    lastItem = null
    for item, i in nVal

        append = false
        if lastItem?.streamItemType == item.streamItemType and lastItem.userId == item.userId and ( lastItem.parent.id == item.parent.id or lastItem.parent.type != 'project' )
            if item.streamItemType == 'user' and item.created - lastItem.created < MIN
                append = true
            else
                if item.value == lastItem.value and item.created - lastItem.created < MIN * 10 # item.streamItemType == 'system' and
                    append = true

        if append
            lastItem.items.push item
            lastItem.idmap += item.id
        else
            if lastItem?.created == item.created
                continue
            smartItem =
                userId: item.userId
                value: item.value # if item.streamItemType == 'system' then item.value else null
                streamItemType: item.streamItemType
                created: item.created
                items: [item]
                idmap: item.id
                parent:
                    id: item.parent.id
                    type: item.parent.type
                smartDate: i==0 or item.created - lastItem.created > 15 * MIN
            scope.smartItems.push smartItem
            lastItem = smartItem

    # console.log scope.smartItems
, true

# items
scope.streamMessage =
    items: []
    type: 'streamMessageBox'

# Flush unread
flushUnread = ->
    if scope.streamParentItem?.totalUpdates - scope.streamParentItem.userUpdated?['uid' + account.user.id]?.updates > 0
        operationsService.call (scope.flowFrame.item.type or 'stream'), 'setUserUpdate',
            id: scope.flowFrame.item.id
            userId: account.user.id
unreg = scope.$watch 'streamParentItem.type', (nVal) ->
    if !nVal?
        return
    unreg()
    flushUnread()

# Message items
scope.removeItem = (item) ->
    removeElementFromArray item, scope.streamMessage.items

scope.pickItems = (e) ->

    sections = [
        type: 'actions'
        items: [
            phrase: 'streamFrame_upload_content'
            description: 'streamFrame_upload_content_description'
            action: ->
                novaWizard.fire 'upload',
                    projectId: if scope.appItem.type == 'project' then scope.appItem.id else undefined
                    cb: (items) ->
                        for item in items
                            scope.streamMessage.items.push item
        ,
            phrase: 'streamFrame_from_storage'
            description: 'streamFrame_from_storage_description'
            action: ->
                novaWizard.fire 'contentBrowser',
                    projectId: if scope.appItem.type == 'project' then scope.appItem.id else undefined
                    cb: (items) ->
                        for item in items
                            scope.streamMessage.items.push item
        ,
            phrase: 'streamFrame_import'
            description: 'streamFrame_import_description'
            action: ->
                novaWizard.fire 'importContent',
                    projectId: if scope.appItem.type == 'project' then scope.appItem.id else undefined
                    cb: (items) ->
                        for item in items
                            scope.streamMessage.items.push item
        ]
    ]

    offset = addItems.offset()
    novaMenu.show
        position:
            x: offset.left + Math.ceil(addItems.width() / 2) #e.pageX
            y: offset.top
            hei: addItems.height() # e.pageY
        sections: sections
        menuStyle: 'center'
        noApply: true
    true
