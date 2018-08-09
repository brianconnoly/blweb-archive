*deps: novaWizard, novaAddMenu
*replace: true

elem = $ element
winElem = elem.children '.novaAddMenuWindow'

scope.wizards = novaWizard.wizards
scope.fire = (wizard) ->
    novaWizard.fire wizard

scope.$watch ->
    novaAddMenu.showed
, (nVal) ->
    if nVal == true
        wid = winElem.width()
        winElem.css
            left: novaAddMenu.position.left - (wid / 2)
            bottom: novaAddMenu.position.bottom

        setTimeout ->
            elem.addClass 'showed'
        , 0

    else
        elem.removeClass 'showed'

scope.hideAddMenu = (e) ->
    novaAddMenu.hide()