*deps: taskService

elem = $ element

scope.isActive = (item) ->
    scope.flow.currentCode == 'theme_timeline'

scope.activateAll = ->
    scope.flow.addFrame
        title: 'themeSchedules'
        translateTitle: 'novaThemeTimeline'
        directive: 'novaThemeTimelineFrame'
        code: 'theme_timeline'

scope.mediaplanSettings = (e) ->
    scope.flow.addFrame
        title: 'themeSchedules_settings'
        translateTitle: 'novaThemeTimeline_settings'
        directive: 'novaThemeTimelineSettingsFrame'
        code: 'theme_timeline_settings'

    e.stopPropagation()
