buzzlike.directive 'combobox', (comboboxService, complexMenu, localization) ->
    restrict: 'E'
    require: '^ngModel'
    scope:
        list: '='
        settings: '='
        default: '@'
    replace: true
    template: tC['/inputs/combobox/activator']
    link: (scope, element, attrs, ctrl) ->
        elem = $ element

        scope.translate = localization.translate

        settings = {}
        defaultSettings =
            minLines: 3 # минимальная высота от края экрана до активатора
            maxLines: 0 # и пока не работает
            hideSelected: false
            #antiscroll: false
            #search: false #

        updateObject settings, defaultSettings, scope.settings

        selectItem = (item) ->
            ctrl.$setViewValue item.value or item
            scope.selected = item

        if scope.default and scope.list?.length
            item = findObjectByFields scope.list, {value: scope.default}
            if item
                defaultValue = scope.default
                selectItem item
            else
                if scope.default == 'last' then scope.default = scope.list.length-1
                if +scope.default
                    item = scope.list[scope.default]
                    defaultValue = item.value
                    selectItem item

        scope.value = null
        scope.title = null
        scope.state = comboboxService.state

        listClass = [] #собирает все классы кроме класса директивы и ng- классов, чтобы повесить их на список.
        for c in elem[0].classList
            if c == 'combobox' or c.indexOf('ng-')+1 then continue
            listClass.push c
        listClass = listClass.join ' '

        #TODO пересчитать при ресайзе
        initContentPosition = ->
            lines = scope.list.length
            lineHeight = settings.lineHeight = elem.height()

            contentHeight = scope.list.length * lineHeight
            offset = elem.offset()
            offset.top += lineHeight

            pos =
                left: offset.left
                minWidth: elem.width()

            screen =
                width: $(window).width()        # отступы сверху от меню и снизу от края окна
                height: $(window).height() - 42 - 5 - 5 # nav height #TODO убрать тупой костыль

            if settings.maxLines
                if lines > settings.maxLines then lines = settings.maxLines

            contentHeight = lines * lineHeight
            pos.height = if contentHeight > screen.height then screen.height else contentHeight

            #TODO right distance
            bottomSpace = screen.height - (offset.top + contentHeight)
            if bottomSpace < 0
                #TODO overflow & min/max lines
                pos.bottom = 5 # просто какой-то магический отступ
            else
                pos.top = offset.top

            return pos

        scope.open = (list) ->
            # comboboxService.showList
            #     opened: true
            #     position: initContentPosition() #pos
            #     list: list
            #     value: scope.value
            #     selected: scope.selected
            #     settings: settings
            #     listClass: listClass
            #     cb: selectItem

            complexMenu.show [
                selectFunction: selectItem
                value: scope.selected?.value
                type: 'select'
                items: list
            ],
                top: elem.offset().top + 30
                left: elem.offset().left

            true

        ctrl.$render = () ->
            if scope.list?
                for item in scope.list
                    # if item.translateTitle
                    #     item.title = localization.translate item.translateTitle

                    value = item.value or item
                    if value == ctrl.$viewValue
                        scope.state.value = scope.value
                        #scope.value = item.value
                        #scope.title = item.title
                        scope.selected = item
            true

        true