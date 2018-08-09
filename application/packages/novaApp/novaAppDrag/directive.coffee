*deps: novaAppDrag

elem = $ element
elem.off '.novaAppDrap'

elem.on 'mousedown.novaAppDrap', (e) ->
    targ = $(e.target)
    if targ.hasClass('noDrag') or targ.prop("tagName") == 'INPUT' or targ.parents('.noDrag').length > 0 or scope.session.maximize == true
        return true

    novaAppDrag.startDrag e, elem, scope

    e.stopPropagation()
    e.preventDefault()
