*deps: novaRowScroller, dynamicStyle, combService, novaWizard, projectService, localStorageService, updateService
*replace: true

elem = $ element
addItems = $ elem.find('.addItems')[0]
actionsMenu = $ elem.find('.actionsMenu')[0]

novaMultiselect = $ elem.find('.novaMultiselect')[0]

# New theme ========
scope.newTheme = ->
    novaWizard.fire 'theme',
        projectId: scope.session.item.id

# Zoom =============
style = new dynamicStyle '.novaThemesFrame.$ div.novaItem'
elem.addClass style.className

styleName = new dynamicStyle '.novaThemesFrame.$ div.novaItem div.name'
elem.addClass styleName.className

styleFrame = new dynamicStyle '.novaThemesFrame.$ div.novaRowScrollerItems'
elem.addClass styleFrame.className

frameStorageCode = scope.appItem.id + '_' + scope.flowFrame?.item?.id
scope.zoom = localStorageService.get('novaThemes_zoom_'+frameStorageCode) or 4.2
minMargin = 30
lastPerLine = null
lineHei = 0
blockMargin = 0
showNames = true
scope.updateZoom = ->
    wid = scope.zoom * 30 | 0
    hei = wid * 3 / 4

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

unreg = scope.$watch 'appItem.type', (nVal) ->
    if nVal?
        unreg()

        # Scroller ==============
        scrollerElem = elem.find '.novaFrameContents'
        scope.scroller = new novaRowScroller
            query:
                # userId: scope.flowFrame.data.userId
                projectId: scope.session.item.id
                # type: 'image'
                parent: 'null'
            sortBy: 'created'
            pageHeight: scrollerElem.height()
            elem: scrollerElem
            perLine: lastPerLine
            lineHei: lineHei
            blockMargin: blockMargin
            queryFunc: combService.query
            apply: ->
                scope.$applyAsync()

scope.handleResize = ->
    scope.updateZoom()

scope.handleResizeEnd = ->
    scope.scroller?.rebuild()

scope.parentItem = projectService.getById scope.session.item.id

updateId = updateService.registerUpdateHandler (data, action, items) ->
    if action in ['update','create','delete']
        if data['comb']?
            affected = []
            for item in items
                if item.type == 'comb'
                    affected.push combService.getById item.id

            if affected.length > 0
                scope.scroller.updated affected, action

scope.$on '$destroy', ->
    updateService.unRegisterUpdateHandler updateId
