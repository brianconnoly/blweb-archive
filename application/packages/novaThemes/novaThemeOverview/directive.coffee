*replace: true

scope.$watch 'comb.name', ->
    scope.heightChanged()

scope.heightChanged = ->
    scope.unit.unitHeight = scope.unit.elem.height()
    scope.recountHead()
