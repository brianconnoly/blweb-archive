buzzlike.directive 'filterWidget', (resize, localization) ->
    restrict: 'C'
    template: tC['/filterCatalog/filterWidget']
    link: (scope, element, attrs) ->
        
        scope.localization = localization

        scope.contentList = {}

        scope.params = params = scope.$parent.params
        itemW = () -> if params.smallIcons then 116 else 174
        itemH = () -> if params.smallIcons then 116 else 174

        widgetLines = () -> if params.smallIcons then Math.ceil(scope.widget.lines*1.2) else scope.widget.lines

        elem = $ element

        elem.find('.content').height widgetLines()*itemH() + 50
        scope.widgetHeight = widgetLines()*itemH()

        screen =
            wid: 0
            hei: 0

        scope.pages = []
        scope.currentPage = 0
        currentPageId = 0
        scope.currentLots = []

        pageItems = null
        maxPageSize = 0
        maxTotal = 0
        maxItems = 0

        scope.noRight = true
        scope.noLeft = true

        scope.goPage = (page) ->
            scope.currentPage = page

            scope.noRight = false
            scope.noLeft = false

            index = scope.pages.indexOf scope.currentPage
            if index == scope.pages.length-1
                scope.noRight = true

            if index == 0
                scope.noLeft = true

            currentPageId = scope.pages.indexOf scope.currentPage
            true

        scope.goRight = ->
            currentPageId++
            if currentPageId < scope.pages.length
                scope.currentPage = scope.pages[currentPageId]

            if currentPageId == scope.pages.length-1
                scope.noRight = true

            scope.noLeft = false
            false

        scope.goLeft = ->
            currentPageId--
            if currentPageId >= 0
                scope.currentPage = scope.pages[currentPageId]

            if currentPageId == 0
                scope.noLeft = true

            scope.noRight = false
            false

        updateWidget = (items, total) ->
            page = 0
            cnt = 0

            maxItems = items
            maxTotal = total

            itemsLen = items.length

            if itemsLen < pageItems
                lines = Math.ceil(itemsLen/screen.wid)
            else
                lines = widgetLines()

            scope.pages.length = 0

            for k,item of items
                if cnt >= pageItems
                    if ++page >= scope.widget.screens then break
                    cnt = 0

                if !scope.pages[page]?
                    scope.pages[page] = []
                scope.pages[page].push item if item
                cnt++

            scope.widgetHeight = lines*itemH()

            contentHeight = scope.widgetHeight
            if scope.pages.length>1 then contentHeight += 50
            elem.find('.content').height contentHeight

            if !scope.pages[currentPageId]?
                currentPageId = 0

            scope.noLeft = false
            scope.noRight = false

            if currentPageId == 0
                scope.noLeft = true
            if currentPageId == scope.pages.length-1
                scope.noRight = true

            scope.currentPage = scope.pages[currentPageId]


        scope.refresh = refresh = (action) ->
            if !scope.widget?
                return 
            allowQuery = true
            if action == 'resize'
                allowQuery = false
                pageItems = screen.wid * widgetLines()
                
                if pageItems > maxPageSize
                    maxPageSize = pageItems
                    allowQuery = true

            if allowQuery
                scope.widget.query.limit = pageItems * scope.widget.screens
                scope.query scope.widget.query, updateWidget
            else
                updateWidget maxItems, maxTotal


        scope.$parent.$parent.$parent.$parent.onResize (wid, hei) ->
            scope.widgetWidth = wid - leftPanelWidth # rightPanelWidth         # Разгадываем магические числа:
            nu_wid = (scope.widgetWidth - 80) / itemW() | 0                       # 80  - стрелки с отступами
            nu_hei = ( hei - 150 ) / itemH() | 0                                  # 150 - верхнее меню, пагинатор и заголовок

            if screen.wid != nu_wid || screen.hei != nu_hei
                scope.contentWidth = nu_wid * itemW()
                screen.wid = nu_wid
                screen.hei = nu_hei

                refresh('resize')

        true