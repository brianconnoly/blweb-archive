elem = $ element
scope.page.element = elem
elem.css 'transform', "translate3d(0,#{scope.page.top}px,0)"

if scope.page.anchor == 'bottom'
    elem.css 'bottom', '100%'
    