*deps: groupService, novaDesktop, combService

elem = $ element
scope.moduleName = 'novaProjectThemes_title'
scope.pinned = []

# scope.$watch 'appItem.type', (nVal) ->
#
# combService.query
#     projectId: scope.session.item.id
#     pinned: true
# , (items) ->
#     for item in items
#         scope.pinned.push item if item not in scope.pinned

scope.activatePinned = (comb) ->

    novaDesktop.launchApp
        app: 'novaThemesApp'
        item:
            id: comb
            type: 'comb'

    true

scope.activateAll = ->
    scope.flow.addFrame
        translateTitle: 'novaThemesFrame'
        unitCode: 'themes'
        directive: 'novaThemesFrame'
        code: 'projectThemes'
    true
