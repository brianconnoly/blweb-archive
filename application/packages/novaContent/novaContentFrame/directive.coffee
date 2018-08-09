*deps: novaRowScroller, dynamicStyle, contentService, novaMenu, novaWizard, combService, localStorageService, updateService
*replace: true

elem = $ element
addItems = $ elem.find('.addItems')[0]
actionsMenu = $ elem.find('.actionsMenu')[0]

novaMultiselect = $ elem.find('.novaMultiselect')[0]

# Zoom =============
style = new dynamicStyle '.novaContentFrame.$ div.novaItem'
elem.addClass style.className

styleName = new dynamicStyle '.novaContentFrame.$ div.novaItem div.name'
elem.addClass styleName.className

styleFrame = new dynamicStyle '.novaContentFrame.$ div.novaRowScrollerItems'
elem.addClass styleFrame.className

frameStorageCode = scope.appItem.id + '_' + scope.flowFrame?.item?.id
scope.zoom = localStorageService.get('novaContent_zoom_'+frameStorageCode) or 2.5
minMargin = 30
lastPerLine = null
lineHei = 0
blockMargin = 0

showNames = true
scope.updateZoom = ->
    localStorageService.add 'novaContent_zoom_'+frameStorageCode, scope.zoom

    wid = scope.zoom * 30 | 0
    hei = wid * 3 / 4 | 0

    frameWid = elem.width()
    perLine = frameWid / (wid+minMargin) | 0
    rest = frameWid - (perLine*wid)

    margin = rest / (perLine + 1)
    margin /= 2

    verticalMargin = margin * 0.8 | 0

    style.update "
        width: #{wid}px;
        height: #{hei}px;
        margin: #{verticalMargin}px #{margin}px;
    "

    styleFrame.update "
        padding: #{verticalMargin}px #{margin}px;
    "

    fz = hei * 0.2 / 2
    fz = 10 if fz < 10

    styleName.update "
        font-size: #{fz}px;
    "

    if hei < 45 and showNames
        elem.addClass 'noItemNames'
        showNames = false

    else if hei > 45 and !showNames
        elem.removeClass 'noItemNames'
        showNames = true

    if lastPerLine != null and lastPerLine != perLine
        scope.scroller?.setPerLine perLine
    lastPerLine = perLine
    lineHei = hei + verticalMargin*2
    blockMargin = verticalMargin*2
    true

scope.updateZoom()

# Scroller ==============
unreg = scope.$watch 'appItem.type', (nVal) ->
    if nVal?
        unreg()

        query =
            projectId: scope.appItem.projectId or scope.session.item.id#data.userId
            combIds: if scope.appItem.type == 'comb' then scope.appItem.id
            parent: if scope.appItem.type == 'comb' then undefined else 'null'
            # type: 'image'

        if scope.flowFrame.item?.type == 'folder'
            query.parent = scope.flowFrame.item.id
            delete query.projectId

        if scope.appItem?.type == 'comb'
            delete query.projectId

        scrollerElem = elem.find '.novaFrameContents'
        scope.scroller = new novaRowScroller
            query: query
            sortBy: 'created'
            pageHeight: scrollerElem.height()
            elem: scrollerElem
            perLine: lastPerLine
            lineHei: lineHei
            blockMargin: blockMargin
            queryFunc: contentService.query
            apply: ->
                scope.$applyAsync()

scope.handleResize = ->
    scope.updateZoom()

scope.handleResizeEnd = ->
    scope.scroller?.rebuild()

scope.addItems = (e) ->

    sections = [
        type: 'actions'
        items: [
            phrase: 'wizardTitle_text'
            action: ->
                novaWizard.fire 'text',
                    projectId: if scope.appItem.type == 'project' then scope.appItem.id else undefined
                    combId: if scope.appItem.type == 'comb' then scope.appItem.id else undefined
                    parent: scope.flowFrame.item?.id or undefined
        ,
            phrase: 'wizardTitle_folder'
            action: ->
                novaWizard.fire 'folder',
                    projectId: if scope.appItem.type == 'project' then scope.appItem.id else undefined
                    combId: if scope.appItem.type == 'comb' then scope.appItem.id else undefined
                    parent: scope.flowFrame.item?.id or undefined
        ,
            phrase: 'streamFrame_upload_content'
            description: 'streamFrame_upload_content_description'
            action: ->
                where = []
                where.push scope.appItem if scope.appItem.type != 'project'

                if scope.flowFrame.item?.type == 'folder'
                    where.push
                        type: 'folder'
                        id: scope.flowFrame.item.id

                novaWizard.fire 'upload',
                    projectId: if scope.appItem.type == 'project' then scope.appItem.id else undefined
                    where: where
        ,
            phrase: 'streamFrame_from_storage'
            description: 'streamFrame_from_storage_description'
            action: ->
                novaWizard.fire 'contentBrowser',
                    projectId: if scope.appItem.type == 'project' then scope.appItem.id else undefined
                    cb: (items, ids) ->
                        if scope.flowFrame.item?.type == 'folder'
                            contentService.addContentIds scope.flowFrame.item, ids
                        else
                            if scope.appItem.type == 'project'
                                for item in items
                                    contentService.call 'moveToProject',
                                        projectId: scope.appItem.id
                                        itemId: item.id
                            else if scope.appItem.type == 'comb'
                                combService.addContentIds scope.appItem, ids
        ,
            phrase: 'streamFrame_import'
            description: 'streamFrame_import_description'
            action: ->
                novaWizard.fire 'importContent',
                    projectId: if scope.appItem.type == 'project' then scope.appItem.id else undefined
                    cb: (items, ids) ->
                        if scope.flowFrame.item?.type == 'folder'
                            contentService.addContentIds scope.flowFrame.item, ids
                        else
                            if scope.appItem.type == 'project'
                                for item in items
                                    contentService.call 'moveToProject',
                                        projectId: scope.appItem.id
                                        itemId: item.id
                            else if scope.appItem.type == 'comb'
                                combService.addContentIds scope.appItem, ids
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

scope.showMenu = (e) ->
    items = angular.element(novaMultiselect[0]).scope().multiselect.selected
    context = scope.flowFrame.item
    if items.length == 0 and scope.flowFrame.item?.id?
        items = [scope.flowFrame.item]
        context = null

    offset = actionsMenu.offset()
    novaMenu.show
        position:
            x: offset.left + Math.ceil(actionsMenu.width() / 2) #e.pageX
            y: offset.top
            hei: actionsMenu.height() # e.pageY
        items: items
        context: context
        menuStyle: 'center'
        noApply: true
    true

updateId = updateService.registerUpdateHandler (data, action, items) ->
    if action in ['update','create','delete']
        if data['content']?
            affected = []
            for item in items
                if contentService.isContent item
                    affected.push contentService.getById item.id

            if affected.length > 0
                scope.scroller.updated affected, action

scope.$on '$destroy', ->
    updateService.unRegisterUpdateHandler updateId
