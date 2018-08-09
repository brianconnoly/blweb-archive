buzzlike.directive 'singleView', (operationsService, updateService) ->
    restrict: 'C'
    link: (scope, element, attrs) ->

        scope.items = []

        itemWid = 0
        itemHei = 0

        pageSizeX = 0
        pageSizeY = 0

        page = 0
        isLoading = false
        hasToLoad = true

        elem = $ element
        body = elem.parents('.body')
        elem.on 'mousewheel', (e) ->
            if hasToLoad == true and body[0].scrollTop + body.height() > body[0].scrollHeight - 400
                if page > 0 and isLoading != true 
                    getPage()
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

            query.page = page
            query.limit = pageSizeX * pageSizeY * 2

            query.sortBy = scope.currentStep.sortBy
            query.sortType = scope.currentStep.sortType or 'desc'

            scope.prepareQuery? query

            if scope.progress?
                process = scope.progress.add()

            isLoading = true

            scope.queryFunction query, (items, total) ->

            # operationsService.query scope.currentStep.itemType, scope.currentStep.query, (items, total) ->
                # scope.items.length = 0

                for item in items
                    scope.items.push item if item not in scope.items

                if process?
                    scope.progress.finish process

                if total < (page+1) * pageSizeX * pageSizeY * 2
                    hasToLoad = false

                isLoading = false
                page++
                true

        reloadView = ->
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

            page = 0

            query = angular.copy scope.currentStep.query or {}

            if types.length > 0
                query.contentType =
                    '$in': types

            query.limit = pageSizeX * pageSizeY * 2

            query.sortBy = scope.currentStep.sortBy
            query.sortType = scope.currentStep.sortType or 'desc'

            if scope.progress?
                process = scope.progress.add()

            isLoading = true

            scope.queryFunction query, (items, total = 0) ->
            # operationsService.query scope.currentStep.itemType, scope.currentStep.query, (items, total) ->
                scope.items.length = 0

                for item in items
                    scope.items.push item

                if process?
                    scope.progress.finish process

                if total < (page+1) * pageSizeX * pageSizeY * 2
                    hasToLoad = false
                else
                    hasToLoad = true

                isLoading = false
                page = 1
                true

        filtersDiffer = (a,b) ->
            for k,v of a
                if b[k] != v
                    return true
            false

        scope.$watch 'currentStep', (nVal, oVal) ->
            if nVal?
                # if filtersDiffer(nVal.filterTypes, oVal.filterTypes) or
                #     nVal.sortBy != oVal.sortBy or
                #     page == 0
                reloadView()
        , true

        updateId = updateService.registerUpdateHandler (data) ->
            if data[scope.currentStep.itemType]?
                if scope.currentStep.contentType?
                    if data[scope.currentStep.contentType]?
                        reloadView()
                else
                    reloadView()

        scope.$on '$destroy', ->
            updateService.unRegisterUpdateHandler updateId

        true
