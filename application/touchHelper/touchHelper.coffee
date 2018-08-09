buzzlike
    .service 'touchHelper', (combService, contentService) ->

        doc = $(document)
        device = (/(ipad|arm|iphone|ipod)/.exec(navigator.platform.toLowerCase()) || [""])[0]

        if device != 'ipad'
            viewport = document.querySelector("meta[name=viewport]")
            viewport.setAttribute('content', 'width=device-width, initial-scale=0.5, maximum-scale=0.5, user-scalable=0')

        state =
            device: device
            touch: device != ""
            multiselect: false
            scrolledGroup: null
            bigBottom: device != 'ipad'

        exPageX = null

        touchMove = (e) ->
            e0 = e.originalEvent
            scope = angular.element(state.scrolledGroup).scope()
            scope.doScroll (exPageX - e0.pageX)
            exPageX = e0.pageX

        touchEnd = (e) ->
            state.scrolledGroup = null
            doc.off 'touchmove.drag'
            doc.off 'touchend.drag'

        if state.touch 
            if state.device == 'ipad'
                $('body').addClass 'ipad'

            $('body').on 'touchmove', (e) ->
                if !$(e.target).parents('.ios-scroll')[0]? or e.originalEvent.touches.length > 1 # or $(e.target).parents('.ios-nodelay')[0]?
                    e.preventDefault()

                true

            lastTime = Date.now()
            lastEl = null

            # doc.on 'tap', '.ios-nodelay', (e) ->
            #     e.preventDefault()

            #     true

            doc.on 'touchstart', '.ios-nodelay', (e) ->
                $(@).addClass 'pushed'
                $(@).trigger('mousedown')
                #console.log angular.element(@).scope().selectFunc(e)

                true

            doc.on 'touchend', '.ios-nodelay', (e) ->
                e.preventDefault()

                jObj = $(@)

                jObj.trigger('click')                
                jObj.removeClass 'pushed'

                #angular.element(@).scope().$apply()

                true

            doc.on 'touchend', '.ios-nodelay', (e) ->
                e.preventDefault()

                jObj = $(@)

                now = Date.now()
                if lastEl == @ and now - lastTime <= 500
                    
                    item_scope = angular.element(@).scope()
                    item = item_scope.item
                    scope = angular.element($('.viewport3d').children()[0]).scope()
                    # if $state.current.name == 'combs'
                    #     if item?.type == 'comb'
                    #         scope.itemClick item, e
                    #         scope.$apply()
                    #     else if contentService.isContent(item)
                    #         if item.type == 'text'
                    #             $(@).trigger 'dblclick'
                    #         else
                    #             scope.contentClick item, e
                    #             scope.$apply()
                    # else if $state.current.name == 'content'
                    #     if contentService.isContent(item)
                    #         if item.type == 'text'
                    #             $(@).trigger 'dblclick'
                    #         else
                    #             scope.itemClick item, e
                    #             scope.$apply()
                    # else if $state.current.name == 'timeline'
                    #     if item.type == 'schedule'
                    #         combService.loadComb item_scope.post.combId
                    #         $state.transitionTo 'combs'

                lastTime = now
                lastEl = @
                

                #angular.element(@).scope().$apply()

                true
                
            doc.on 'tap', '.feedGroup', (e) ->
                e.preventDefault()

                true

            doc.on 'tap', '.feedInterval', (e) ->
                angular.element(this).scope().touchbarMove e.pageX

                true

            doc.on 'touchstart', '.feedGroup', (e) ->
                e0 = e.originalEvent
                if e0.touches.length > 1
                    e.preventDefault()
                    $('.touchBar').hide()
                    exPageX = e0.pageX
                    state.scrolledGroup = $(e.originalEvent.target).parents('.feedGroup')[0]
                    doc.on 'touchmove.drag', touchMove
                    doc.on 'touchend.drag', touchEnd

                true


        {   
            state
        }



    .directive 'touchHelper', (touchHelper, stateManager, multiselect, localization) ->
        restrict: 'E'
        replace: true
        template: tC['/touchHelper']
        link: (scope, element, attrs) ->

            scope.localization = localization
            scope.state = state = touchHelper.state
            scope.multiselect = multiselect.state

            scope.triggerMultiselect = () ->
                touchHelper.state.multiselect = !touchHelper.state.multiselect

            scope.back = () ->
                stateManager.callEscape()

            scope.toRight = () ->
                angular.element($('.selectedPanel')[0]).scope().selectFocused()

            true