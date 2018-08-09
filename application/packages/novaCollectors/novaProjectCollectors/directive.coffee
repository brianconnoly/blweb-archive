*deps: novaDesktop, ugcService

elem = $ element
if scope.appItem.type == 'project'
    scope.items = ugcService.getByProjectId(scope.appItem.id)
else
    scope.items = ugcService.getByCombId(scope.appItem.id)

scope.ugcFilter = (item) ->
    if scope.appItem.type == 'comb'
        return scope.appItem.id in item.combIds
    scope.appItem.id == item.projectId

scope.activate = (ugc) ->

    scope.flow.addFrame
        title: 'ugc'
        directive: 'novaCollectorPostsFrame'
        item:
            id: ugc.id
            type: 'ugc'

    true

scope.ugcSettings = (ugc, e) ->
    e.stopPropagation()
    e.preventDefault()

    scope.flow.addFrame
        title: 'ugc'
        directive: 'novaCollectorSettingsFrame'
        item:
            id: ugc.id
            type: 'ugc'
