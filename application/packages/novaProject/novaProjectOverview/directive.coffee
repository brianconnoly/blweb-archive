*replace: true

scope.$watch 'project', ->
    scope.heightChanged()
, true

scope.heightChanged = ->
    scope.unit.unitHeight = scope.unit.elem.height()
    scope.recountHead()
