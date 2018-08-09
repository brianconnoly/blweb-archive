buzzlike.directive 'menuWindow', (contextMenu, multiselect, smartDate) ->
    restrict: 'C'
    replace: true
    template: tC['/contextMenu/menuWindow']
    link: (scope, element, attrs) ->
        elem = $ element

        scope.contextStatus = contextMenu.status

        scope.$watch 'contextStatus.position', (nVal) ->
            x = scope.contextStatus.position.x
            y = scope.contextStatus.position.y

            if y > window.innerHeight - elem.height()
                y = window.innerHeight - elem.height()

            if x > window.innerWidth - elem.width()
                x = window.innerWidth - elem.width()

            elem.css 'top', y + 'px'
            elem.css 'left', x + 'px'
        , true

        scope.clearBuffer = (e) ->
            multiselect.clearBuffer()

            e.stopPropagation()
            e.preventDefault()

        scope.fireAction = (action, e) ->

            e.stopPropagation()
            e.preventDefault()

            contextMenu.hide()

            action e

            multiselect.flush()

            true

        true
