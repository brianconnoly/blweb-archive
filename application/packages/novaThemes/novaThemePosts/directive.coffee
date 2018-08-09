*deps: taskService

elem = $ element

scope.isActive = (item) ->
    scope.flow.currentCode == 'theme_posts'

scope.activateAll = ->
    scope.flow.addFrame
        title: 'themeSchedules'
        translateTitle: 'novaThemePosts_title'
        directive: 'novaThemePostsFrame'
        code: 'theme_posts'
        item:
            type: 'comb'
            id: scope.appItem.id
