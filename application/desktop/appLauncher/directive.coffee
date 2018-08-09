buzzlike.directive 'appLauncher', ($rootScope, $compile, dragWinow) ->
    restrict: 'C'
    template: tC['/desktop/appLauncher']
    link: (scope, element, attrs) ->
        elem = $ element
        scope.element = elem

        if !scope.session.expandedHeader?
            scope.session.expandedHeader = true

        noRes = 0
        if scope.session.size.maxWidth? and scope.session.size.maxWidth == scope.session.size.minWidth
            elem.children('.resize.left').remove()
            elem.children('.resize.right').remove()
            noRes++

        if scope.session.size.maxHeight? and scope.session.size.maxHeight == scope.session.size.minHeight
            elem.children('.resize.top').remove()
            elem.children('.resize.bottom').remove()
            noRes++

        if noRes == 2
            elem.children('.resize').remove()
            
        scope.$watch 'session.expandedHeader', (nVal) ->
            if nVal == true
                template.addClass 'expandedHeader'
            else
                template.removeClass 'expandedHeader'

        appArr = scope.session.app.split '/'
        appName = appArr.pop()

        head = '<div item="{\'type\':\'' + appName + 'App\'}" class="contextMenu flushMultiselect appContainer ' + appName + '" ng-controller="' + appName + 'Ctrl">'
        tail = '</div>'

        template = $compile(head + tC['/desktop/apps/' + scope.session.app ] + tail)(scope)
        scope.element = elem

        if scope.session.alwaysOnTop == true
            elem.addClass 'alwaysOnTop'

        elem.append template

        elem.on 'mousedown.dragWindow', (e) ->
            if isCmd e and e.altKey
                dragWinow.startDrag e, element, scope

        if scope.session.coords?.x?
            elem.css 'transform', 'translate3d(' + scope.session.coords.x + 'px,' + scope.session.coords.y + 'px, 0)'

        if scope.session.size?.width?
            elem.css 'width', scope.session.size.width

        if scope.session.size?.height?
            elem.css 'height', scope.session.size.height

        if scope.session.noResize == true
            elem.children('.resize').remove()

        true
