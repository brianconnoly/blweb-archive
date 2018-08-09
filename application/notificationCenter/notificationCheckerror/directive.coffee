buzzlike.directive 'notificationCheckerror', (requestService) ->
    template: tC['/notificationCenter/notificationCheckerror']
    link: (scope, element, attrs) ->
        requestService.getById scope.notification.itemList[0].id, (request) ->
            scope.lotId = request.lotId

        true