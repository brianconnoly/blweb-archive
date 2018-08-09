buzzlike.directive 'communityTitle', (communityService) ->
    restrict: 'C'
    scope:
        communityId: '='
    template: tC['/filterCatalog/filterView/communityTitle']
    link: (scope, element, attrs) ->

        scope.communityData = {}

        scope.$watch 'communityId', (nVal, oVal) ->
            communityService.getById scope.communityId, (data) ->
                scope.communityData = data

        true