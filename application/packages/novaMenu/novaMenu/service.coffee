*deps: $compile, $rootScope, localization, actionsService, dynamicStyle

class novaMenu

    buildElement: ->
        @scope = $rootScope.$new()
        @scope.actions = []
        @scope.novaMenu = @

        @active = false

        @elem = $ '<div>',
            class: 'novaMenu'
        @body.append @elem

        setTimeout =>
            @elem = $ $compile(@elem)(@scope)

            @menuElem = @elem #.children '.novaMenuWindow'
        , 0

        @body.on 'mousedown.novaMenu', (e) =>
            @hide()

    constructor: ->
        @body = $ 'body'
        @buildElement()

        @style = new dynamicStyle '.novaMenu:after'

    show: (data) ->
        # position, items, context, actions
        if data.sections?.length > 0
            @scope.sections = data.sections
        else #if data.items?.length > 0
            actions = actionsService.getActions
                source: data.items or []
                sourceContext: data.context
                target: data.context
                actionsType: 'contextMenu'
                scope: data.scope

                # source: items
                # context: data.context
                # sourceContext: data.sourceContext
                # target: data.target or data.context
                # actionsType: 'contextMenu'

            if actions.length > 0
                groups = {}
                list = []

                for action in actions
                    if !groups[action.category]?
                        groups[action.category] =
                            type: 'actions'
                            items: []

                    groups[action.category].items.push
                        phrase: action.phrase
                        action: action.action
                        priority: action.priority

                for k,actions of groups
                    actions.items.sort (a,b) ->
                        if a.priority > b.priority
                            return -1
                        if a.priority < b.priority
                            return 1
                        0

                for k,actions of groups
                    list.push actions

                @scope.sections = list

        # Count length
        len = 0
        keys = @scope.sections?.length or []
        workareaHei = @body.height()
        workareaWid = @body.width()
        for section in @scope.sections
            # keys++
            len += 10 + section.items.length * (18 + 6)

        if keys > 1
            len += (keys-1)*1

        pos =
            x: data.position.x
            y: data.position.y

        if len > workareaHei
            pos.y = 0
            pos.height = workareaHei - 10
            len = workareaHei

        if data.menuStyle == 'center'
            pos.x -= 105
            pos.y += 5

            if pos.x < 10
                pos.x = 10

            if pos.y > workareaHei - 300
                pos.y -= len + 10
                @menuElem.addClass 'cornerDown'
            else
                if data.position.hei?
                    pos.y += data.position.hei
                @menuElem.removeClass 'cornerDown'

            @style.update "
                left: #{data.position.x - pos.x - 10}px;
                right: auto;
            "

            @menuElem.removeClass 'noLeftCorner'
            if data.position.x - pos.x - 10 == 0
                @menuElem.addClass 'noLeftCorner'

            @menuElem
            .addClass 'corner'
        else
            if pos.y + len > workareaHei
                pos.y = workareaHei - len

            @menuElem.removeClass 'corner'

        right = 'auto'
        if pos.x + 200 > workareaWid
            right = '100%'
            pos.x = workareaWid - 20

            @style.update "
                right: #{pos.x - data.position.x - 10}px;
                left: auto;
            "

        @menuElem.css
            'transform': "translate3d(#{pos.x}px, #{pos.y}px, 0)"
            'right': right
        @active = true
        # @elem.addClass 'visible'
        @scope.$apply() if data.noApply != true

    hide: (noApply = false) ->
        if !@active
            return
        @active = false
        @elem
        .removeClass 'active'
        @scope.actions.length = 0
        @scope.$apply() if !noApply
        true

new novaMenu
