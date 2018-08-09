buzzlike.directive "filterView", (resize, $rootScope, updateService, stateManager) ->
    restrict: 'C'
    scope: 
        section: '='
        query: '='
        params: '='
        currentChild: '=?'
    template: tC['/filterCatalog/filterView']
    link: (scope, element, attrs) ->

        elem = $ element
        widgetList = elem.find('.widgetList')

        scope.showContentList = false
        scope.viewSection = null
        scope.widgets = null
        scope.contentList = []

        scope.pages = 0
        scope.items = []
        scope.currentPage = 0

        pageItems = null
        maxPageSize = 0
        maxTotal = 0
        maxItems = 0
        savedTotal = 0

        currentQuery = null

        scope.noLeft = true
        scope.noRight = true

        itemW = () -> if scope.params.smallIcons then 116 else 174
        itemH = () -> if scope.params.smallIcons then 116 else 174

        deepViewState = 
            child: true
            'escape': () ->
                scope.back()
                stateManager.goBack()


        updateService.registerUpdateHandler (data) ->
            if currentQuery?
                if data[currentQuery.entityType]?
                    if currentQuery.contentType?
                        if data[currentQuery.contentType]?
                            refresh()
                    else
                        refresh()

            else
                widgetList.children('.filterWidget').each () ->
                    widScope = angular.element(@).scope()

                    if widScope?
                        if data[widScope.widget.query.entityType]?
                            if widScope.widget.query.contentType?
                                if data[widScope.widget.query.contentType]?
                                    widScope.refresh()
                            else
                                widScope.refresh()

        screen =
            wid:0
            hei:0

        scope.$watch 'params', (nVal, oVal) ->
            if nVal? and nVal != oVal and scope.section?
                if scope.section.custom == true
                    updateWidgets()
                else
                    refresh()
        , true

        scope.$watch 'section', (nVal, oVal) ->
            if nVal?
                updateWidgets(nVal)

        scope.$watch 'currentChild', (nVal) ->
            if nVal?
                scope.select nVal
            else
                currentQuery = null
                scope.showContentList = false
            refresh()

        updateWidgets = (nVal) ->
            currentQuery = null
            scope.widgets = null      
            scope.viewSection = nVal if nVal?

            if !scope.viewSection?
                return
                
            if scope.viewSection.widgets?
                # Отображаем виджеты

                if typeof scope.viewSection.widgets == 'function'
                    if scope.viewSection.async
                        scope.viewSection.widgets (result) ->
                            scope.widgets = result
                    else
                        scope.widgets = scope.viewSection.widgets()
                else
                    scope.widgets = scope.viewSection.widgets

                scope.showContentList = false

            else
                currentQuery = scope.viewSection.query
                scope.showContentList = true
                refresh()


        updateWidget = (items, total) ->
            cnt = 0          # сломал мозг. Закоментил.
            maxTotal = total # = items
            maxItems = items # = total

            # закрываем косяк бэкенда, возвращающего 0 в тотале
            total = total or savedTotal
            if !total
                currentQuery.limit = 100500
                currentQuery.page = 0
                scope.query currentQuery, (items, total) ->
                    savedTotal = items.length
                    updateWidget items, total
                return true
            # -------

            scope.pages = Math.ceil total/pageItems

            scope.items.length = 0

            for k,item of items
                scope.items.push item if item
                cnt++

            updateArrows()

        scope.refresh = refresh = (action) ->

            nu_wid = (scope.widgetWidth - 80) / itemW() | 0  
            nu_hei = ( lastHei - 100 ) / itemH() | 0  

            if screen.wid != nu_wid || screen.hei != nu_hei
                scope.contentWidth = nu_wid * itemW()
                scope.widgetHeight = nu_hei * itemH()
                screen.wid = nu_wid
                screen.hei = nu_hei

            lines = screen.hei
            pageSize = screen.wid * screen.hei
            
            if pageSize > maxPageSize
                action == 'resize'

            if currentQuery?
                allowQuery = true

                pageItems = screen.wid * screen.hei
                currentQuery.limit = pageItems
                currentQuery.page = scope.currentPage

                
                if action == 'resize'
                    elem.find('.items .content').height lines*itemH()
                    scope.widgetHeight = lines*itemH()

                    allowQuery = false

                if pageSize > maxPageSize
                    maxPageSize = pageSize
                    allowQuery = true

                if allowQuery
                    scope.query currentQuery, updateWidget
                else
                    updateWidget maxItems, maxTotal

            else
                if action == 'resize' then return false
                widgetList.children('.filterWidget').each () ->
                    angular.element(@).scope()?.refresh(action)

        lastWid = 0
        lastHei = 0
        scope.$parent.$parent.onResize (wid, hei) ->
            lastWid = wid
            lastHei = hei
            scope.widgetWidth = wid - leftPanelWidth # rightPanelWidth           # Разгадываем магические числа:
            nu_wid = (scope.widgetWidth - 80) / itemW() | 0                       # 80  - стрелки с отступами
            nu_hei = ( hei - 100 ) / itemH() | 0                                  # 100 - верхнее меню и пагинатор

            if screen.wid != nu_wid || screen.hei != nu_hei
                scope.contentWidth = nu_wid * itemW()
                scope.widgetHeight = nu_hei * itemH()
                screen.wid = nu_wid
                screen.hei = nu_hei

                refresh('resize')

        scope.paginator = (pages, currentPage) ->
            w = elem.find(".pagination.arrows").width()
            cellWidth = 40
            if currentPage > 99 then cellWidth = 60
            $rootScope.makePaginatorFromPages pages, currentPage, Math.ceil (w/cellWidth-3)/2

        scope.select = (widget) ->
            if scope.viewSection != widget
                scope.contentList.length = 0
            scope.viewSection = widget
            scope.showContentList = true
            scope.currentPage = 0
            scope.currentChild = widget
            currentQuery = widget.query
            refresh()

            stateManager.applyState deepViewState
            true

        scope.back = () ->
            scope.showContentList = false
            scope.items.length = 0
            scope.pages = 0
            currentQuery = null
            scope.currentChild = null
            refresh()
            true

        scope.freshOnTop = (item) ->
            -item.createdWhen

        scope.goPage = (page) ->
            scope.currentPage = page
            updateArrows()
            refresh()
            true

        updateArrows = () ->
            scope.noLeft = true
            scope.noRight = true

            if scope.currentPage > 0
                scope.noLeft = false

            if scope.currentPage < scope.pages-1
                scope.noRight = false

        scope.goRight = ->
            if scope.currentPage < scope.pages
                scope.currentPage++
                updateArrows()
                refresh()
            false

        scope.goLeft = ->
            if scope.currentPage > 0
                scope.currentPage--
                updateArrows()
                refresh()
            false
        true