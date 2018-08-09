buzzlike.directive 'contextMenu', (contextMenu, multiselect, smartDate, $parse, stateManager, operationsService) ->
    restrict: 'AC'
    link: (scope, element, attrs) ->

        elem = $ element

        elem.on 'contextmenu.contextMenu', (e) ->
            if $(e.target).prop("tagName") in ['INPUT','TEXTAREA']
                return 
                
            if e.which == 3

                if attrs.context?
                    scope.context = $parse(attrs.context)(scope)
                else
                    scope.context = stateManager.getContext()

                target = null
                if attrs.target?
                    target = $parse(attrs.target)(scope)

                e.preventDefault()
                e.stopPropagation()

                contextMenu.position 
                    x: e.clientX
                    y: e.clientY

                postEar = false
                sideCircle = $(e.target).parents('.addPostArea')[0]
                if sideCircle?
                    time = $(sideCircle).data('time')
                    itemScope = angular.element($(sideCircle).parents('.feedInterval')[0]).scope()

                    contextMenu.show [
                        type: 'timeline'
                        timestamp: time
                        communityId: itemScope.cId
                        groupId: itemScope.groupId
                    ], 
                        target: target or scope.context
                        context: context or scope.context
                        sourceContext: scope.context

                else if attrs.item?
                    item = $parse(attrs.item)(scope)
                    contextMenu.show [item],
                        target: target or scope.context
                        context: scope.context
                        sourceContext: scope.context
                else

                    if !elem.hasClass('selected')
                        multiselect.flush()
                    
                    if scope.id? or attrs.id?
                        multiselect.state.lastFocused = element

                        operationsService.get attrs.type, scope.id or $parse(attrs.id)(scope), (item) ->
                            multiselect.addToFocus
                                id: item.id
                                type: item.type

                    else if scope.item?
                        multiselect.state.lastFocused = element
                        multiselect.addToFocus scope.item

                    elem.addClass 'selected'

                    context = null
                    if elem.parents('#rightPanel').length > 0
                        context =
                            type: 'rightPanel'

                    contextMenu.show multiselect.getFocused(), 
                        target: target or stateManager.getContext() or scope.context
                        context: context or scope.context
                        sourceContext: scope.context

                scope.$apply()

            
                