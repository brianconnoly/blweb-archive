*deps: projectService, account
*replace: true

elem = $ element

scope.session.noItem = true
scope.session.size =
    width: 800
    height: 600

scope.isInvited = false

# Build project units
scope.units = []
scope.headUnits = []
buildProjectUnits = ->
    scope.units.length = 0

    # * Add project overview bar
    if scope.project.profileUserId == account.user.id
        scope.headUnits.push
            title: 'overview'
            directive: 'novaProfileOverview'
    else
        scope.headUnits.push
            title: 'overview'
            directive: 'novaProjectOverview'

        if scope.isInvited
            scope.headUnits.push
                title: 'invitation'
                directive: 'novaProjectInvitation'

    scope.units.push
        title: 'channels'
        directive: 'novaProjectGroups'
        data:
            groupId: 'account'

    scope.units.push
        title: 'users'
        directive: 'novaProjectUsers'

    scope.units.push
        title: 'tasks'
        directive: 'novaProjectTasks'

    scope.units.push
        title: 'content'
        directive: 'novaProjectContent'

    if account.user.roles.labUser
        scope.units.push
            title: 'channelMonitor'
            directive: 'novaProjectChannelMonitors'

    scope.units.push
        title: 'themes'
        directive: 'novaProjectThemes'

    scope.units.push
        title: 'content'
        directive: 'novaProjectCollectors'

    setTimeout ->
        scope.recountHead()
    , 0

projectService.getById scope.session.item.id, (proj) ->
    scope.project = proj

    if proj.appearance.controls == 'white'
        elem.parents('.novaApp').removeClass('styleBlack').addClass('styleWhite')

    for member in proj.members
        if member.userId == account.user.id
            scope.isInvited = member.invited
            break

    buildProjectUnits()

scope.modules = [
    title: 'people'
    directive: 'novaUsersGroups'
    data:
        projectId: scope.session.item.id
,
    title: 'content'
    directive: 'novaContentFrame'
    data:
        userId: scope.session.item.id
,
    title: 'comb'
    directive: 'novaThemesFrame'
    data:
        userId: scope.session.item.id
,
    title: 'task'
    directive: 'novaTasksFrame'
    data:
        projectId: scope.session.item.id
]

scope.activeModule = null

scope.init = ->
    scope.runModule = (module) ->
        scope.activeModule = module
        scope.flow.addFrame module

    if scope.flow.flowBoxes.length < 1
        scope.runModule scope.modules[3]
