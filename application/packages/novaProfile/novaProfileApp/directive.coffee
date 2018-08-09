*deps: account

elem = $ element

scope.session.noItem = true
scope.session.size =
    width: 600
    height: 500

scope.modules = [
    title: 'channel'
    directive: 'novaTimelineFrame'
    data:
        groupId: 'account'
,
    title: 'content'
    directive: 'novaContentFrame'
    data:
        userId: account.user.id
,
    title: 'comb'
    directive: 'novaThemesFrame'
    data:
        userId: account.user.id
,
    title: 'task'
    directive: 'novaTasksFrame'
    data:
        userId: account.user.id
]

scope.activeModule = null

scope.init = ->
    scope.runModule = (module) ->
        scope.activeModule = module
        scope.flow.addFrame module

    if scope.flow.flowBoxes.length < 1
        scope.runModule scope.modules[3]
    # scope.flow.addFrame
    #     type: 'testFrame'
    #     directive: 'novaTimelineFrame'
    #     data:
    #         groupId: 'account'
