*deps: $compile

elem = $ element

scope.unit.unitScope = scope
scope.unit.elem = elem

newElem = $ '<div>',
    class: scope.unit.directive

newElem.html tC[scope.unit.directive + '/template.jade']

newElem = $ $compile(newElem)(scope)
elem.append newElem
scope.unit.unitHeight = elem.height()
