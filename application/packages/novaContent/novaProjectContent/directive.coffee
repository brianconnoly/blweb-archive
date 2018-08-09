
elem = $ element
scope.moduleName = 'novaProjectContent_title'

scope.activatePinned = (content) ->
    console.log 'NOT IMPLEMENTED'
    true

scope.activateAll = ->
    scope.flow.addFrame
        translateTitle: 'novaContentFrame'
        unitCode: 'content'
        directive: 'novaContentFrame'
        code: 'projectContent'
    true
