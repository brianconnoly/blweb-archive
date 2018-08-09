buzzlike.directive 'flowView', (updateService, contentService) ->
    restrict: 'C'
    link: (scope, element, attrs) ->

        scope.items = []

        scope.periods = []
        lastPeriod = null

        itemWid = 0
        itemHei = 0

        pageSizeX = 0
        pageSizeY = 0

        page = 0
        isLoading = false
        hasToLoad = true
        lastValue = null

        elem = $ element
        body = elem.parents('.stepView')

        helper = body.parent().find '.flowViewHelper'
        if helper.length < 1
            helper = $ '<div>',
                class: 'flowViewHelper'
            body.parent().append helper
        helper.css
            top: -30

        reloadOnScroll = false

        currentElem = null
        currentHead = null
        checkElem = (scroll) ->
            if !currentElem?
                return false

            pos = currentElem.position()
            if scroll > pos.top + currentElem.height()
                return false

            if scroll < pos.top
                return false

            true

        smartPosition = (scroll) ->
            pos = currentElem.position()

            if scroll > pos.top + currentElem.height() - 30
                helper.css
                    'top': pos.top + currentElem.height() - 30 - scroll
                return

            if scroll <= pos.top - 30
                helper.css
                    'top': pos.top - 30 - scroll
                return

            helper.css
                'top': 0
            true

        findNew = (scroll = 0) ->
            candidates = body.find('.periodBlock')
            candidates.each () ->
                elem = $ this
                pos = elem.position()

                if pos.top <= scroll < pos.top + elem.height()
                    currentElem = elem
                    currentHead = currentElem.children '.periodHead'

                    helper.html currentHead.html()

                    body.find('.periodHead.active').removeClass('active')
                    currentHead.addClass 'active'

                    smartPosition scroll

        findNew()

        scope.checkToLoad = ->
            if currentElem?
                if !checkElem body[0].scrollTop
                    findNew body[0].scrollTop

                smartPosition body[0].scrollTop
            else
                findNew body[0].scrollTop

            # console.log body[0].scrollTop + body.height(), body[0].scrollHeight - 400
            if hasToLoad == true and body[0].scrollTop + body.height() > body[0].scrollHeight - 400
                if page > 0 and isLoading != true 
                    getPage()
                    return true
            false

        elem.on 'mousewheel', ->
            if scope.checkToLoad()
                scope.$apply()

        getPage = ->
            query = angular.copy scope.currentStep.query or {}

            types = []
            for key,val of scope.currentStep.filterTypes
                if val == true
                    types.push key

            if types.length > 0
                query.contentType =
                    '$in': types

            # query.page = page

            # Flow thing
            if lastValue?
                query[scope.currentStep.sortBy] =
                    $lt: lastValue

            query.limit = pageSizeX * pageSizeY * 2

            query.parent = scope.currentStep.parent or 'null'

            query.sortBy = scope.currentStep.sortBy
            query.sortType = scope.currentStep.sortType or 'desc'

            scope.prepareQuery? query

            if scope.progress?
                process = scope.progress.add()

            isLoading = true

            scope.queryFunction query, (items, total) ->

                processItems items, (item) ->
                    if item[scope.currentStep.sortBy] < lastValue or !lastValue?
                        lastValue = item[scope.currentStep.sortBy]

                if process?
                    scope.progress.finish process

                if items.length < query.limit
                    hasToLoad = false

                isLoading = false
                page++
                true

        reloadView = ->
            helper.css
                top: -30

            dateObj = new Date()
            startDay = new Date dateObj.getFullYear(), dateObj.getMonth(), dateObj.getDate()
            startYear = new Date dateObj.getFullYear(), 0, 1

            day = dateObj.getDay()
            day -= 1
            if day < 0 then day = 7

            startDayTS = startDay.getTime()

            scope.periods = [
                title: 'group_by_today'
                filter:
                    gt: startDayTS - 1
                items: []
            ,
                title: 'group_by_yesterday'
                filter:
                    lt: startDayTS
                    gt: startDayTS - DAY - 1
                items: []
            ,
                title: 'group_by_currentWeek'
                filter:
                    lt: startDayTS - DAY
                    gt: startDayTS - DAY * day - 1
                items: []
            ,
                title: 'group_by_lastWeek'
                filter:
                    lt: startDayTS - DAY * day
                    gt: startDayTS - DAY * (day + 7) - 1
                items: []
            ,
                title: 'group_by_currentMonth'
                filter:
                    lt: startDayTS - DAY * (day + 7) 
                    gt: new Date(dateObj.getFullYear(), dateObj.getMonth(), 1) - 1
                items: []
            ,
                title: 'group_by_lastMonth'
                filter:
                    lt: new Date dateObj.getFullYear(), dateObj.getMonth(), 1
                    gt: new Date(dateObj.getFullYear(), dateObj.getMonth() - 1, 1) - 1
                items: []
            ,
                title: 'group_by_thisYear'
                filter:
                    lt: new Date(dateObj.getFullYear(), dateObj.getMonth() - 1, 1)
                    gt: new Date(dateObj.getFullYear(), 0, 1) - 1
                items: []
            ,
                title: 'group_by_lastYear'
                filter:
                    lt: new Date(dateObj.getFullYear(), 0, 1)
                    gt: new Date(dateObj.getFullYear() - 1, 0, 1) - 1
                items: []
            ,
                title: 'group_by_laterThenEver'
                filter:
                    lt: new Date(dateObj.getFullYear() - 1, 0, 1)
                items: []
            ]

            types = []
            for key,val of scope.currentStep.filterTypes
                if val == true
                    types.push key

            switch scope.session.zoom
                when 'min'
                    itemWid = 90
                    itemHei = 74
                when 'mid'
                    itemWid = 159
                    itemHei = 126
                when 'max'
                    itemWid = 197
                    itemHei = 151

            pageSizeX = Math.floor(scope.session.size.width / itemWid)
            pageSizeY = Math.floor(scope.session.size.height / itemHei)

            lastValue = null
            page = 0

            query = angular.copy scope.currentStep.query or {}

            if types.length > 0
                query.contentType =
                    '$in': types

            if lastValue?
                query[scope.currentStep.sortBy] =
                    $lt: lastValue

            query.limit = pageSizeX * pageSizeY * 2

            query.parent = scope.currentStep.parent or 'null'

            query.sortBy = scope.currentStep.sortBy
            query.sortType = scope.currentStep.sortType or 'desc'

            if scope.progress?
                process = scope.progress.add()

            isLoading = true

            scope.queryFunction query, (items, total = 0) ->

                processItems items, (item) ->
                    if item[scope.currentStep.sortBy] < lastValue or !lastValue?
                        lastValue = item[scope.currentStep.sortBy]

                if process?
                    scope.progress.finish process

                if items.length < query.limit
                    hasToLoad = false
                else
                    hasToLoad = true

                isLoading = false
                page = 1
                true

        processItems = (items, fn) ->
            types = []
            for key,val of scope.currentStep.filterTypes
                if val == true
                    types.push key

            # if !lastPeriod?
            #     lastPeriod = 
            for item in items
                fn? item

                type = item.type
                if type in ['text', 'image', 'audio', 'video', 'url', 'folder', 'poll', 'file']
                    type = 'content'

                if type != scope.currentStep.itemType
                    continue

                if types.length > 0
                    if item.type not in types
                        continue

                if (item.parent or null) != (scope.currentStep.parent or null)
                    continue

                for period in scope.periods
                    if  (!period.filter.gt? or item[scope.currentStep.sortBy] > period.filter.gt) and
                        (!period.filter.lt? or item[scope.currentStep.sortBy] < period.filter.lt)
                            period.items.push item if item not in period.items
                    true
                true

            true


        filtersDiffer = (a,b) ->
            for k,v of a
                if b[k] != v
                    return true
            false

        scope.itemsFilter = (item) -> 
            if item.deleted then return false

            if !scope.currentStep.parent?
                return !item.parent?
            else
                return scope.currentStep.parent == item.parent

        scope.getContext = ->
            if !scope.currentStep.parent?
                return null
            contentService.getById scope.currentStep.parent

        scope.$watch 'currentStep', (nVal, oVal) ->
            if nVal?
                # if filtersDiffer(nVal.filterTypes, oVal.filterTypes) or
                #     nVal.sortBy != oVal.sortBy or
                #     page == 0
                reloadView()
        , true

        updateId = updateService.registerUpdateHandler (data, action, items) ->
            if action in ['update','create']
                if data[scope.currentStep.itemType]?
                    if scope.currentStep.contentType?
                        if data[scope.currentStep.contentType]?
                            processItems items
                            scope.$apply()
                    else
                        processItems items
                        scope.$apply()

            scope.checkToLoad()

        scope.$on '$destroy', ->
            updateService.unRegisterUpdateHandler updateId
            helper.remove()

        true

buzzlike.directive 'afterRender', ($parse) ->
    priority: 1
    restrict: 'A'
    link: (scope, element, attrs) ->
        fn = $parse(attrs.afterRender)

        handler = null

        # lastCall = 0
        scope.$watch 'period', ->
            # now = Date.now()
            # if lastCall > 0 then console.log 'diff', now - lastCall
            # lastCall = now

            if !handler?
                handler = setTimeout ->
                    fn?()
                    handler = null
                , 500

