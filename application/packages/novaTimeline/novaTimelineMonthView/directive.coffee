*deps: statsCutService

scope.stats = []

updateStats = ->
    # console.log 'TODO: update stats', scope.stats
    true

for communityId in scope.communityIds
    statsCutService.get 
        timestamp: scope.block.timestamp
        communityId: communityId
    , (res) ->
        scope.stats.push res

scope.$watch 'statsCut', ->
    updateStats()
, true
