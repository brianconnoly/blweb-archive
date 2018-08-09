buzzlike.directive 'lazyLots', () ->
    restrict: 'C'
    link: (scope, element, attrs) ->

        elem = $ element
        body = elem.parents('.leftPanel')
        elem.on 'mousewheel', (e) ->
            scope.lotScrollValue = elem[0].scrollTop
            if scope.lotParams.isLoading == true 
                return

            if elem[0].scrollTop == 0 and scope.lotParams.reloadOnStart == true
                scope.lotParams.reloadOnStart = false
                scope.resetLotList()
                scope.fetchLotsPage()
                scope.$apply()

            else if scope.lotParams.pageSize * (scope.lotParams.page) < scope.lotParams.total
                if elem[0].scrollTop + elem.height() > elem[0].scrollHeight - 200
                    scope.fetchLotsPage()
                    scope.$apply()