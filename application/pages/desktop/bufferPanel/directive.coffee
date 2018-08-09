buzzlike.directive 'bufferPanel', (buffer, dragMaster) ->
    restrict: 'C'
    template: tC['/pages/desktop/bufferPanel']
    link: (scope, element, attrs) ->
        elem = $ element

        scope.buffer = buffer
        scope.actions = buffer.actions
        scope.lowerActions = buffer.lowerActions

        scope.activeTypes = buffer.activeTypes

        pocket = elem.children '.pocket'
        actions = elem.children '.actions'
        pocketSwitcher = elem.children '.pocketSwitcher'

        body = $('body')

        scope.hoverPocket = (pocket) ->
            if dragMaster.dragInProgress()
                buffer.setPocket pocket

        scope.switchPocket = (pocket) ->
            buffer.setPocket pocket
            true

        # scope.$watch 'actions', (nVal) ->
        #     hei = nVal.length
        #     hei++ if scope.lowerActions.length > 0

        #     pocket.css 'bottom', hei * 34
        # , true

        # scope.$watch 'activeTypes', (nVal) ->
        #     # pocketSwitcher.removeClass('two').removeClass('three').removeClass('four').removeClass('five').removeClass('six')
        #     if nVal.length > 1
        #         pocket.css 'top', 30

        #         # switch nVal.length
        #         #     when 2
        #         #         pocketSwitcher.addClass 'two'
        #         #     when 3
        #         #         pocketSwitcher.addClass 'three'
        #         #     when 4
        #         #         pocketSwitcher.addClass 'four'
        #         #     when 5
        #         #         pocketSwitcher.addClass 'five'
        #         #     when 6
        #         #         pocketSwitcher.addClass 'six'
        #     else
        #         pocket.css 'top', 0

        # , true

        scope.callAction = (action, e) ->
            items = action.action e
            if action.leaveItems != true
                buffer.removeItems items

        scope.callSticky = (action, e) ->
            e.stopPropagation()
            e.preventDefault()
            action.action e

        scope.removeElement = (item, e) ->
            e.stopPropagation()
            buffer.removeItem item, true

        scope.addBuffer = ->
            buffer.addPocket()

        scope.closeBuffer = (pocket, e) ->
            if buffer.buffer.length > 1
                $(e.target).parents('.typeSwitcher').css
                    'display': 'none'
            buffer.closePocket pocket

        true