buzzlike.directive 'combTeamView', (teamService) ->
    restrict: 'C'
    link: (scope, element, attrs) ->

        process = scope.progress.add()
        scope.team = teamService.getById scope.comb.teamId, ->
            scope.progress.finish process