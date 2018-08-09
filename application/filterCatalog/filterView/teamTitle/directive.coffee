buzzlike.directive 'teamTitle', (teamService) ->
    restrict: 'C'
    scope:
        teamId: '='
    template: tC['/filterCatalog/filterView/teamTitle']
    link: (scope, element, attrs) ->

        scope.teamData = {}

        scope.$watch 'teamId', (nVal, oVal) ->
            teamService.getById scope.teamId, (data) ->
                scope.teamData = data

        true