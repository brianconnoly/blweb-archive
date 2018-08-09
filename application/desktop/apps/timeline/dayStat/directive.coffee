buzzlike.directive 'dayStat', (statsCutService, desktopService) ->
    restrict: 'C'
    template: tC['/desktop/apps/timeline/dayStat']
    link: (scope, element, attrs) ->

        if scope.$parent.interval.from < Date.now()
            element.addClass 'completed'

        scope.hasStats  = false
        scope.canScroll = false

        scope.period = ""
        scope.value = 0
        scope.down = false

        statTypes = []
        stats = []
        currentType = 0
        currentStat = null
        updateStats = ->
            statTypes.length = 0
            stats.length = 0
            scope.hasStats  = false

            for k,v of scope.statsCut
                statTypes.push k
                stats.push v
                scope.hasStats = true

            if statTypes.length > 1
                scope.canScroll = true

            if scope.hasStats
                updateView()

        updateView = ->
            currentStat = scope.statsCut[statTypes[currentType]]
            scope.period = statTypes[currentType]

            newA = currentStat.stats?.activity or 0
            oldA = currentStat.delta.activity or 0

            if newA == oldA
                scope.value = 0
                scope.down = false
            else if oldA > newA
                scope.value = (oldA - newA) / oldA
                scope.down = true
            else
                scope.value = (newA - oldA) / newA
                scope.down = false

            scope.value *= 100
            scope.value = Math.abs scope.value | 0

        scope.left = (e) ->
            currentType--
            if currentType < 0
                currentType = statTypes.length-1
            updateView()
            e.stopPropagation()

        scope.right = (e) ->
            currentType++
            if currentType > statTypes.length-1
                currentType = 0
            updateView()
            e.stopPropagation()

        statsCutService.get 
            timestamp: scope.$parent.interval.from #- DAY
            communityId: scope.$parent.cId
        , (res) ->
            scope.statsCut = res
            if scope.statsCut?
                updateStats()

            scope.$watch 'statsCut', ->
                updateStats()
            , true


        scope.launchGraph = (e) ->
            desktopService.launchApp 'graph',
                item: currentStat

        true