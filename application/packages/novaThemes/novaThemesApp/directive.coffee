*deps: combService, account, projectService
*replace: true

elem = $ element

scope.session.noItem = true
scope.session.size =
    width: 800
    height: 600

scope.isInvited = false

# Build project units
scope.headUnits = []
scope.units = []
buildProjectUnits = ->
    scope.units.length = 0

    # * Add project overview bar
    scope.headUnits.push
        title: 'overview'
        directive: 'novaThemeOverview'

    scope.units.push
        title: 'timeline'
        directive: 'novaThemeTimeline'

    scope.units.push
        title: 'timeline'
        directive: 'novaThemePosts'

    scope.units.push
        title: 'tasks'
        directive: 'novaProjectTasks'

    scope.units.push
        title: 'content'
        directive: 'novaProjectContent'

    scope.units.push
        title: 'content'
        directive: 'novaProjectCollectors'

combService.getById scope.session.item.id, (comb) ->
    scope.comb = comb
    if comb.projectId?
        scope.project = projectService.getById comb.projectId
    buildProjectUnits()

scope.activeModule = null

scope.init = ->
    # scope.runModule = (module) ->
    #     scope.activeModule = module
    #     scope.flow.addFrame module
    #
    # if scope.flow.flowBoxes.length < 1
    #     scope.runModule scope.units[0] #scope.modules[3]
    true
