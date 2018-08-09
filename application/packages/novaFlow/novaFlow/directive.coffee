*deps: novaFlow, stateManager

elem = $ element
scope.flow = new novaFlow elem, scope

scope.onResizeProgress ->
    scope.flow.recountFrames()
, false

scope.onResize ->
    scope.flow.recountFramesFinal()
, false

scope.onFocus ->
    stateManager.setTree scope.flow.currentStateTree if scope.flow.currentStateTree?
