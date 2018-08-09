 buzzlike.directive 'pageScroller', ($parse, $compile) ->
    restrict: 'C'
    template: tC['/itemsContainer/pageScroller']
    link: (scope, element, attrs) ->

        elem = $ element
        pagesContainer = elem.children '.pagesContainer'
        handler = elem.find '.handler'
        scrollBar = elem.children '.scrollBar'
        helper = scrollBar.children '.helper'

        defaults =
            minHeight: 100
            itemVar: 'item'
            topOffset: 10
            bottomOffset: 10

        options = $parse(attrs.options)(scope)
        
        for k,v of defaults
            if !options[k]?
                options[k] = v

        handlerHei = 10
        keyPage = null
        pages = []

        lastPage = 0
        lastTop = 0

        scrollHeight = scope.session.size.height - options.heightOffset
        options.perPage = Math.ceil(scrollHeight / options.minHeight)
        options.maxPages = Math.ceil(options.total / options.perPage)

        if options.watchObject?
            scope.$watch options.watchObject, (nVal) ->
                rebuildPages()
            , true

        rebuildScroller = =>
            scrollHeight = scope.session.size.height - options.heightOffset
            options.perPage = Math.ceil(scrollHeight / options.minHeight)
            options.maxPages = Math.ceil(options.total / options.perPage)

            if options.maxPages > 1
                elem.removeClass 'hide'
            else
                elem.addClass 'hide'

            handlerHei = scrollHeight / options.maxPages
            handler.css
                'height':  handlerHei

        # scope.$watch ->
        #     options.total
        # , (nVal) ->
        #     rebuildPages()

        rebuildPages = =>
            clearPages()

            rebuildScroller()

            if lastPage > options.maxPages - 1
                lastPage = options.maxPages - 1
            if lastPage < 0
                lastPage = 0

            scroll(0)

        options.rebuildPages = rebuildPages

        clearPages = ->
            keyPage = null
            for page in pages
                page.scope.$destroy()
                page.element.remove()

            pages.length = 0

        scroll = (delta = 0) ->

            minY = scrollHeight + 100
            maxY = 0

            if !keyPage?
                keyPage = addPage false, lastPage
                keyPage.top = lastTop

            index = pages.indexOf keyPage

            keyPage.height = keyPage.element.height()
            if keyPage.page != options.maxPages - 1 and keyPage.height < scrollHeight
                keyPage.height = scrollHeight

            if keyPage.bottom != 'auto'
                keyPage.top = scrollHeight - keyPage.bottom - keyPage.height
                keyPage.bottom = 'auto'

            keyPage.top = keyPage.top | 0
            keyPage.top += delta
            keyPage.bottom = 'auto'

            if keyPage.page == options.maxPages - 1 and keyPage.top + keyPage.height < scrollHeight - options.bottomOffset
                keyPage.top = scrollHeight - keyPage.height - options.bottomOffset

            if keyPage.page == 0 and keyPage.top > options.topOffset
                keyPage.top = options.topOffset
            
            keyPage.element.css 
                'top': keyPage.top
                'bottom': keyPage.bottom

            toRemove = []

            keyCandidate = null
            keyCoord = null

            if keyPage.top < scrollHeight
                keyCandidate = keyPage
                keyCoord = scrollHeight - keyPage.top

            # Pages top
            minY = scrollHeight - keyPage.top
            for i in [index-1..0] by -1
                page = pages[i]

                if index - i > 2
                    toRemove.push page
                    continue

                page.height = page.element.height()
                if page.height < scrollHeight
                    page.height = scrollHeight

                page.bottom = minY
                page.top = 'auto'

                if page.bottom + page.height > minY
                    minY = page.bottom + page.height

                topCoord = page.bottom + page.height
                if topCoord > 0 and ( keyCoord == null or topCoord < keyCoord )
                    keyCoord = topCoord
                    keyCandidate = page

                page.element.css 
                    'top': page.top
                    'bottom': page.bottom

            # Pages under
            maxY = keyPage.height + keyPage.top
            for i in [index+1...pages.length] by 1
                page = pages[i]

                if i - index > 2
                    toRemove.push page
                    continue

                page.height = page.element.height()
                if page.height < scrollHeight
                    page.height = scrollHeight

                page.top = maxY
                page.bottom = 'auto'

                if page.top + page.height > maxY
                    maxY = page.top + page.height

                topCoord = scrollHeight - page.top
                if topCoord > 0 and ( keyCoord == null or topCoord < keyCoord )
                    keyCoord = topCoord
                    keyCandidate = page

                page.element.css 
                    'top': page.top
                    'bottom': page.bottom

            lastPage = keyPage.page
            lastTop = keyPage.top

            for page in toRemove
                page.scope.$destroy()
                page.element.remove()

                removeElementFromArray page, pages

            if keyCandidate? and keyCandidate != keyPage
                keyPage.element.removeClass 'keyPage'
                keyCandidate.element.addClass 'keyPage'
                keyPage = keyCandidate

            if maxY < scrollHeight and pages[pages.length - 1].page < options.maxPages - 1
                newPage = addPage()
                newPage.top = maxY
                newPage.bottom = 'auto'

                newPage.element.css 
                    'top': newPage.top
                    'bottom': newPage.bottom

                topCoord = scrollHeight - newPage.top
                if topCoord > 0 and ( keyCoord == null or topCoord < keyCoord )
                    keyPage.element.removeClass 'keyPage'
                    newPage.element.addClass 'keyPage'
                    keyPage = newPage

                scroll 0

            if minY < scrollHeight and pages[0].page > 0
                newPage = addPage true
                newPage.bottom = minY
                newPage.top = 'auto'

                newPage.element.css 
                    'top': newPage.top
                    'bottom': newPage.bottom

                topCoord = newPage.bottom + newPage.height
                if topCoord > 0 and ( keyCoord == null or topCoord < keyCoord )
                    keyPage.element.removeClass 'keyPage'
                    newPage.element.addClass 'keyPage'
                    keyPage = newPage

                scroll 0


        addPage = (top, pageId = 0) ->
            newPage = 
                element: $ '<div>',
                    class: 'pageScroller_page'
                height: options.perPage * options.minHeight
                scope: scope.$new()

            if top
                if pages.length == 0
                    newPage.page = pageId
                else
                    _lastPage = pages[0]
                    newPage.page = _lastPage.page - 1

            else
                if pages.length == 0
                    newPage.page = pageId
                else
                    _lastPage = pages[pages.length - 1]
                    newPage.page = _lastPage.page + 1

            newPage.element.addClass 'page_' + newPage.page
            options.getPage newPage.page, (items) ->
                for item in items
                    newScope = newPage.scope.$new()
                    newScope[options.itemVar] = item
                    newElem = $compile(options.template)(newScope)
                    newPage.element.append newElem

            pagesContainer.append newPage.element

            if top
                pages.unshift newPage
            else
                pages.push newPage
            newPage

        elem.on 'mousewheel', (e, delta) ->
            if delta > scrollHeight
                delta = scrollHeight

            if delta < -scrollHeight
                delta = -scrollHeight

            scroll delta

            handler.css
                'top': keyPage.page * handlerHei

            e.stopPropagation()
            e.preventDefault()

        scrollBar.on 'mousemove', (e) ->
            top = e.pageY - elem.offset().top
            page = Math.ceil(top / handlerHei)

            helper.html page
            helper.css
                'top': page * handlerHei - handlerHei / 2 #e.pageY - elem.offset().top

        scrollBar.on 'click', (e) ->
            top = e.pageY - elem.offset().top
            page = Math.ceil(top / handlerHei)

            lastPage = page - 1
            clearPages()
            scroll 0

            handler.css
                'top': keyPage.page * handlerHei
