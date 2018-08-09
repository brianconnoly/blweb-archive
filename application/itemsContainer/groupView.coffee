buzzlike.directive 'groupView', (operationsService, updateService) ->
    restrict: 'C'
    link: (scope, element, attrs) ->

        scope.group.lines = 3 if !scope.group.lines?
        scope.group.screens = 3 if !scope.group.screens?

        elem = $ element
        screens = elem.find '.screens'

        scope.screens = []
        scope.items = []

        scope.size = 1
        itemWid = 90
        itemPadding = 20

        scope.currentScreen = null
        scope.currentScreenId = null

        refreshView = ->
            switch scope.session.zoom
                when 'min'
                    itemWid = 90
                    itemPadding = 20
                when 'mid'
                    itemWid = 159
                    itemPadding = 20
                when 'max'
                    itemWid = 197
                    itemPadding = 30

            wid = scope.session.size.width
            wid -= scope.widthShrinker if scope.widthShrinker?

            scope.size = Math.floor((wid - itemPadding) / itemWid)

            scope.group.query.limit = scope.group.lines * scope.size * scope.group.screens

            if scope.progress?
                process = scope.progress.add()

            scope.queryFunction scope.group.query, (items) ->

            # operationsService.query scope.currentStep.itemType, scope.group.query, (items) ->
                if scope.screens.length > 0
                    scope.currentScreenId = scope.screens.indexOf scope.currentScreen

                scope.screens.length = 0

                scope.screenWid = scope.size * itemWid
                screens.css
                    'width': ( ( scope.size * itemWid ) + itemPadding ) * Math.ceil(items.length / scope.group.lines / scope.size)

                screenId = 0
                for item in items
                    if scope.screens[screenId]?.length >= scope.group.lines * scope.size
                        screenId++

                    if !scope.screens[screenId]?
                        scope.screens.push []

                    scope.screens[screenId].push item

                if scope.screens.length > 0
                    scope.currentScreen = scope.screens[scope.currentScreenId || 0]

                if process?
                    scope.progress.finish process


        scope.onResize =>
            refreshView()

        scope.$watch 'session.zoom', (nVal, oVal) ->
            if oVal != nVal
                refreshView()

        scope.selectScreen = (screen) ->
            scope.currentScreen = screen

            id = scope.screens.indexOf screen

            if id == scope.screens.length - 1
                # last screen
                wid = scope.session.size.width
                wid -= scope.widthShrinker if scope.widthShrinker?

                pos = wid - ( ( scope.size * itemWid ) + itemPadding ) * scope.screens.length
                screens.css 'transform', 'translateX(' + pos + 'px)'
            else
                screens.css 'transform', 'translateX(-' + id * scope.screenWid + 'px)'
            true

        scope.notLast  = -> scope.screens.indexOf(scope.currentScreen) < scope.screens.length - 1
        scope.notFirst = -> scope.screens.indexOf(scope.currentScreen) > 0

        scope.goRight = ->
            id = scope.screens.indexOf scope.currentScreen
            if scope.screens[id+1]?
                scope.selectScreen scope.screens[id+1]
        scope.goLeft = ->
            id = scope.screens.indexOf scope.currentScreen
            if scope.screens[id-1]?
                scope.selectScreen scope.screens[id-1]

        reactEveryUpdate = true
        if scope.group.query.sortBy in ['created','lastUpdated'] and ( scope.group.translateTitle != 'group_by_today' and scope.group.fetchOnUpdate != true )
            reactEveryUpdate = false

        updateId = updateService.registerUpdateHandler (data, action) ->
            if reactEveryUpdate == false and action != 'delete'
                return

            if data[scope.currentStep.itemType]?
                if scope.group.contentType?
                    if data[scope.group.contentType]?
                        refreshView()
                else
                    refreshView()

        scope.$on '$destroy', ->
            updateService.unRegisterUpdateHandler updateId
        true