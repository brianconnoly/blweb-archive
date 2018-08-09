*deps: dynamicStyle, postService

elem = $ element

scope.openScheduleFrame = (sched) ->
    scope.flowFrame.flowBox.addFlowFrame
        title: 'post'
        directive: 'novaScheduleFrame'
        item: sched
    , scope.flowFrame

scope.schedules = []
scope.$watch 'block.schedules', (nVal) ->
    scope.schedules.length = 0
    postIds = {}
    for sched in nVal
        if postIds[sched.postId] != true
            postIds[sched.postId] = true
            scope.schedules.push sched
, true
