*deps: $parse, novaMenu
*require: '?ngModel'

if !ngModel then return

elem = $ element

ngModel.$render = () ->
    elem.addClass ngModel.$viewValue
    true

elem.on 'click', (e) ->
    e.stopPropagation()
    e.preventDefault()

    sections = []
    section =
        type: 'actions'
        items: []

    for item in $parse(attrs.novaSwitchOptions)(scope)
        do (item) ->
            section.items.push
                phrase: 'novaSwitch_option_title_' + item
                description: if attrs.novaSwitchView == 'full' then 'novaSwitch_option_description_' + item
                action: ->
                    ngModel.$setViewValue item

    sections.push section

    offset = elem.offset()

    novaMenu.show
        position:
            # x: e.pageX
            # y: e.pageY
            x: offset.left + Math.ceil(elem.width() / 2) #e.pageX
            y: offset.top + elem.height() + 5 # e.pageY
        sections: sections
        context: scope.itemContext
        menuStyle: 'center'
