*replace: true

elem = $ element

scope.pinTab = ->
    scope.flowBox.pin scope.flowFrame
    true

scope.closeTab = ->
    scope.flowBox.closeFlowFrame scope.flowFrame

scope.activateTab = ->
    scope.flow.activate scope.flowFrame, scope.flowBox