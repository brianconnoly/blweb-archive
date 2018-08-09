buzzlike.directive 'helpBrowser', () ->
    restrict: 'E'
    replace: true
    template: tC['/desktop/appLauncher/helpBrowser']
    link: (scope, element, attrs) ->

        scope.compact = false

        scope.showed = false
        scope.loaded = false

        scope.showHelp = ->
            scope.showed = !scope.showed
            if scope.showed == true
                loadHelp scope.helpFile

                scope.stateTree.applyState
                    'escape': ->
                        scope.showed = false
                        scope.stateTree.goBack()
            else
                scope.stateTree.goBack()

        loadHelp = (name) ->
            bigName = name
            # bigName[0] = bigName[0].toUpperCase()

            # process = scope.progress.add()
            # img = new Image
            # img.onload = ->
            #     scope.progress.finish process
            #     scope.loaded = true
            #     scope.$apply()
            
            # img.src = '/resources/images/desktop/about/' + name + '/about' + bigName + '.svg'
            scope.helpSrc = '/resources/images/desktop/about/' + name + '/help.svg'

        scope.onResize (wid, hei) ->
            if wid > 940
                scope.compact = false
            else
                scope.compact = true