buzzlike.directive 'collectorItem', (communityService) ->
    restrict: 'C'
    link: (scope, element, attrs) ->

        load = ->
            scope.community = communityService.getById scope.item.communityId

        if scope.item.communityId?
            load()
        else
            unbind = scope.$watch 'item.communityId', (nVal) ->
                if nVal?
                    load()
                    unbind()