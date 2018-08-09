*deps: scheduleService, ugcService

scope.schedule = ->
    true

scope.delete = ->
    ugcService.call 'rejectPost', scope.item.id
    true

scope.store = ->
    ugcService.call 'acceptPost', scope.item.id
    true
