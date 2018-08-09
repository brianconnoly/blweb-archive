buzzlike.directive 'bigSlider', (desktopService) ->
    restrict: 'C'
    link: (scope, element, attrs) ->

        elem = $ element
        interval = 15 * SEC

        #
        # Init
        # 

        scope.currentSlide = 0
        scope.slides = slides = [
                background: '#b3b3b3'
                src: '/resources/images/desktop/market/honeyflows-offer.svg'
                lotPreview: '54946f6cb4cf006436dde9ba'
            ,
                background: '#8cd019'
                src: '/resources/images/desktop/market/rawcafe-category.svg'
                step:
                    background: '#8cd019'
                    src: '/resources/images/desktop/market/rawcafe-category.svg'
                    translateTitle: 'marketApp_category_3'
                    itemType: 'lot'
                    fetchOnUpdate: true
                    query:
                        categoryIds: 2
                        sortBy: 'lastUpdated'
                        sortOrder: 'desc'
            ,
                background: '#f2f2f2'
                src: '/resources/images/desktop/market/prolong-category.svg'
                step:
                    background: '#f2f2f2'
                    src: '/resources/images/desktop/market/prolong-category.svg'
                    translateTitle: 'marketApp_category_2'
                    itemType: 'lot'
                    fetchOnUpdate: true
                    query:
                        categoryIds: 3
                        sortBy: 'lastUpdated'
                        sortOrder: 'desc'
            # ,
            #     background: '#B3B3B3'
            #     step:
            #         translateTitle: 'marketApp_category_4'
            #         query:
            #             categoryIds: 4
            #             sortBy: 'created'
            #             sortOrder: 'desc'
            # ,
            #     background: '#ff6633'
        ]

        for slide,i in slides
            do (slide, i) ->
                slideElem = $ "<div class='slide' style='background:#{slide.background} url(\"#{slide.src}\") center center no-repeat'></div>"
                slide.elem = slideElem
                elem.append slideElem

                if slide.step?
                    slideElem.addClass 'clickable'
                    slideElem.on 'click', ->
                        scope.goSection slide.step
                        scope.$apply() 

                if slide.lotPreview?
                    slideElem.addClass 'clickable'
                    slideElem.on 'click', ->
                        desktopService.launchApp 'lotPreview',
                            lotId: slide.lotPreview
                        scope.$apply() 

                if i != scope.currentSlide
                    slideElem.addClass 'hideRight'
                else
                    slideElem.addClass 'active'

        #
        # Lock
        #

        _lockTime = Date.now()
        lock = ->
            now = Date.now()
            if now - _lockTime < 500
                return false
            _lockTime = Date.now()
            true

        #
        # Slide change mechanics
        #

        goSlide = (id) ->
            scope.currentSlide = id
            if scope.currentSlide > slides.length - 1
                scope.currentSlide = 0

            next = scope.currentSlide + 1
            prev = scope.currentSlide - 1

            if next > slides.length - 1
                next = 0

            if prev < 0
                prev = slides.length - 1

            for slide,i in slides
                if i == prev
                    slide.elem.removeClass 'hideRight'
                    slide.elem.addClass 'hideLeft'
                    slide.elem.removeClass 'active'
                else if i == scope.currentSlide
                    slide.elem.removeClass 'hideRight'
                    slide.elem.removeClass 'hideLeft'
                    slide.elem.addClass 'active'
                else if i == next
                    slide.elem.addClass 'hideRight'
                    slide.elem.removeClass 'hideLeft'
                    slide.elem.removeClass 'active'

        scope.slideRight = =>
            if !lock()
                return

            goSlide scope.currentSlide + 1

        scope.slideLeft = ->
            if !lock()
                return

            # console.log 'clear'
            # clearInterval handler
            # console.log handler
            # handler = setInterval scope.slideRight, 5000
            # console.log 'set interval'

            scope.currentSlide--
            if scope.currentSlide < 0
                scope.currentSlide = slides.length - 1

            next = scope.currentSlide - 1
            prev = scope.currentSlide + 1

            if prev > slides.length - 1
                prev = 0

            if next < 0
                next = slides.length - 1

            for slide,i in slides
                if i == prev
                    slide.elem.removeClass 'hideLeft'
                    slide.elem.addClass 'hideRight'
                    slide.elem.removeClass 'active'
                else if i == scope.currentSlide
                    slide.elem.removeClass 'hideLeft'
                    slide.elem.removeClass 'hideRight'
                    slide.elem.addClass 'active'
                else if i == next
                    slide.elem.addClass 'hideLeft'
                    slide.elem.removeClass 'hideRight'
                    slide.elem.removeClass 'active'

        scope.selectSlide = (id) ->
            if !lock()
                return

            scope.currentSlide = id
            if scope.currentSlide > slides.length - 1
                scope.currentSlide = 0

            for slide,i in slides
                if i < scope.currentSlide
                    slide.elem.removeClass 'hideRight'
                    slide.elem.addClass 'hideLeft'
                    slide.elem.removeClass 'active'
                else if i == scope.currentSlide
                    slide.elem.removeClass 'hideRight'
                    slide.elem.removeClass 'hideLeft'
                    slide.elem.addClass 'active'
                else if i > scope.currentSlide
                    slide.elem.addClass 'hideRight'
                    slide.elem.removeClass 'hideLeft'
                    slide.elem.removeClass 'active'

        handler = setInterval ->
            if Date.now() - _lockTime < interval
                return
                
            scope.slideRight()
            scope.$apply()
        , interval

        scope.$on '$destroy', ->
            clearInterval handler


