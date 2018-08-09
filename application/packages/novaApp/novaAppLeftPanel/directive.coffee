*deps: novaWizard, novaMenu
*transclude: true

elem = $ element
addIcon = elem.children '.addIcon'
panelUnits = elem.find '.panelUnits'
fixedUnits = elem.find '.fixedUnits'

appElem = $ elem.parents('.novaApp')[0]
appElem.addClass 'withLeftPanel'

scope.triggerPanel = ->
    appElem.toggleClass 'noLeftPanel'
    true

scope.fireWizardPicker = (e) ->
    section =
        type: 'actions'
        items: []
    sections = [section]

    for wizard in novaWizard.wizards
        do (wizard) ->
            section.items.push
                phrase: 'wizardTitle_' + wizard
                descriptionPhrase: 'wizardDescription_' + wizard
                action: ->
                    data = {}
                    data[scope.session.item.type+'Id'] = scope.session.item.id
                    data.projectId = scope.appItem.projectId if scope.appItem?.projectId?
                    novaWizard.fire wizard, data

    offset = addIcon.offset()
    novaMenu.show
        sections: sections
        menuStyle: 'center'
        position:
            x: offset.left + addIcon.width() / 2
            y: offset.top + addIcon.height() + 5
        noApply: true

    e.stopPropagation()
    e.preventDefault()

scope.recountHead = ->
    headHei = 0
    if scope.headUnits? then for unit in scope.headUnits
        # console.log unit.unitHeight
        headHei += unit.elem?.height() or unit.unitHeight

    panelUnits.css 'top', headHei + 40

scope.onResize ->
    setTimeout ->
        scope.recountHead()
    , 0

# panelUnits.on 'mousewheel', (e, delta) ->
#     scope.recountHead()

# scope.$watch 'headUnits', () ->
#     scope.recountHead()
# , true
