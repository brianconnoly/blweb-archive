buzzlike.directive 'feedGroupList', ($compile, communityService, groupService) ->
    restrict: 'C'
    template: tC['/pages/timeline/directives/feedGroupList']
    link: (scope, element, attrs) ->
        elem = $ element
        scope.list = groupService.storage
        scope.groupFilter = (item) ->
            true
        scope.groupOrder = (item) -> item.orderNumber
