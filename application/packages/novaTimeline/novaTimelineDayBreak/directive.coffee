*deps: $compile

elem = $ element

scope.block.elem = elem

if scope.block.static
    sepElem = $ '<div>',
        class: 'novaTimelineDayView'
    sepScope = scope.$new()
    sepScope.block = scope.block
    sepElem = $ $compile(sepElem)(sepScope)
    elem.append sepElem
else
    scope.scroller.requestSeparator
        elem: elem
        pos: elem.parent().position()
        block: scope.block
        page: scope.page
    , (sep) ->
        elem.append sep
    # console.log 'DAY BREAK', elem, elem.parent().position(), scope.block
