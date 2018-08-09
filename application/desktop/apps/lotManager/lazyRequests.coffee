buzzlike.directive 'lazyRequests', () ->
    restrict: 'C'
    link: (scope, element, attrs) ->

        elem = $ element
        body = elem.parents('.leftPanel')
        elem.on 'mousewheel', (e) ->
            scope.requestScrollValue = elem[0].scrollTop
            # console.log elem[0].scrollTop, scope.requestParams.pageSize * (scope.requestParams.page), scope.requestParams
            if scope.requestParams.isLoading == true 
                return

            if elem[0].scrollTop == 0 and scope.requestParams.reloadOnStart == true
                scope.requestParams.reloadOnStart = false
                scope.resetRequestList()
                scope.fetchRequestsPage()
                scope.$apply()

            else if scope.requestParams.pageSize * (scope.requestParams.page) < scope.requestParams.total
                if elem[0].scrollTop + elem.height() > elem[0].scrollHeight - 200
                    scope.fetchRequestsPage()
                    scope.$apply()