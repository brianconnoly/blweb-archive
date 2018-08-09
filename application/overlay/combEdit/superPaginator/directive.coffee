buzzlike.directive 'superPaginator', (resize) ->
    restrict: 'C'
    template: tC['/overlay/combEdit/superPaginator']
    link: (scope, element, attrs) ->

        oldwid = 0
        numbers = 3
        scope.totalPages = 0

        paginatorParams = scope.paginatorParams

        scope.beforeTypes = []
        scope.afterTypes = []
        scope.pages = []

        scope.$on 'destroy', () ->
            resize.unregisterCb 'superPaginator'

        scope.$watch 'paginatorParams', (nVal) ->
            if nVal?
                render()

                if paginatorParams.currentPage > scope.totalPages - 1
                    paginatorParams.currentPage = scope.totalPages - 1
        , true

        pagesContentMap = {}

        iconWidth = 25
        scope.freeSpaceWidth = 10
        updateWidth = (wid) ->
            freeSpace = wid - (paginatorParams.contentTypes.length * 25) - 40
            # freeSpace -= 40

            scope.freeSpaceWidth = wid - 60

            console.log wid, freeSpace

            items = Math.floor(freeSpace / iconWidth)
            items -= paginatorParams.contentTypes.length
            numbers = Math.floor((items-1)/2)
            render()

        render = () ->
            scope.beforeTypes.length = 0
            scope.afterTypes.length = 0
            scope.pages.length = 0
            pageCnt = 0
            lastPageAdded = 0

            noTail = false

            #console.log '=> started rendering'

            for type,catCount in paginatorParams.contentTypes
                noTail = false
                pages = Math.ceil type.count / paginatorParams.contentSize

                totPages = paginatorParams.totalPages #- paginatorParams.contentTypes.length + 1

                leftTail = numbers
                rightTail = if totPages - paginatorParams.currentPage < numbers then totPages - paginatorParams.currentPage else numbers

                if rightTail < 0 
                    rightTail = 0

                if totPages - paginatorParams.currentPage < numbers
                    leftTail = numbers + numbers - rightTail

                #console.log '  |', type.type, leftTail, rightTail

                scope.shortcuts[type.type] = pageCnt

                if pageCnt <= paginatorParams.currentPage - leftTail
                    scope.beforeTypes.push 
                        num: pageCnt
                        class: 'icon_'+type.type + ' type'
                        type: type.type
                else
                    # Check if active
                    #console.log '  |=> check active', paginatorParams.currentPage, pageCnt - leftTail
                    if paginatorParams.currentPage >= pageCnt - leftTail
                        #console.log '    | active!'
                        scope.pages.push
                            num: pageCnt
                            class: 'icon_'+type.type + ' type' + if pages == 1 then ' typeFinal' else ''
                            type: type.type
                        lastPageAdded = pageCnt
                    else
                        #console.log '    | not'
                        scope.afterTypes.push
                            num: pageCnt
                            class: 'icon_'+type.type + ' type' + ' typeFinal'
                            type: type.type
                        noTail = true

                availableSpace = (leftTail + rightTail) + 1 - scope.pages.length
                if paginatorParams.currentPage >= pageCnt - leftTail
                    availableSpace++

                if !noTail and scope.pages.length <= (leftTail + rightTail) + 1

                    start = if paginatorParams.currentPage - leftTail < pageCnt + 1 then pageCnt + 1 else paginatorParams.currentPage - leftTail
                    if lastPageAdded >= start
                        start = lastPageAdded + 1

                    if start < pageCnt + 1
                        start = pageCnt + 1

                    #console.log '  |=> start:', start, availableSpace, scope.pages.length, leftTail, rightTail
                    end = start + (leftTail + rightTail) + 1

                    if end > pageCnt + pages
                        end = pageCnt + pages

                    if end > start

                        if end - start > pages - 1
                            end = start + pages - 1

                        if end - start >= availableSpace
                            end = start + availableSpace
                        else
                            otherPages = 0
                            for i in [catCount+1...paginatorParams.contentTypes.length]
                                catPages = Math.ceil(paginatorParams.contentTypes[i].count / paginatorParams.contentSize)
                                if catPages > 1
                                    otherPages += catPages - 1

                            #console.log '   | --- other pages', otherPages

                            if end == pageCnt + pages 
                                if otherPages == 0
                                    start = end - availableSpace #+ otherPages + 1
                                else if rightTail < numbers
                                    start = end - availableSpace + otherPages + 1

                                if start < pageCnt + 1
                                    start = pageCnt + 1

                        #console.log '  | putting tail', start, end

                        for i in [start...end]
                            scope.pages.push 
                                displayNum: i - pageCnt + 1
                                num: i
                                dots: (i == end-1 and i < pageCnt + pages - 1) or (i == start and i > pageCnt+1) and (end - start > 1)
                                class: 'number ' + if i == end-1 then ' typeFinal'
                            lastPageAdded = i
                            pagesContentMap[i] = type.type

                pageCnt += pages

            scope.totalPages = pageCnt

            true

        recalcWidth = (wid) ->
            teamPanel = if scope.comb.teamId? then 99 else 0

            if oldwid != wid - 350 - teamPanel
                oldwid = wid - 350 - teamPanel
                updateWidth oldwid

                if paginatorParams.currentPage > scope.totalPages - 1
                    paginatorParams.currentPage = scope.totalPages - 1

        scope.$watch 'comb.teamId', (nVal) ->
            recalcWidth scope.session.size.width

        scope.onResize (wid, hei) ->
            recalcWidth wid


        scope.goRight = () ->
            paginatorParams.currentPage++

        scope.goEnd = () ->
            paginatorParams.currentPage = scope.totalPages-1

        scope.goLeft = () ->
            paginatorParams.currentPage--
            if paginatorParams.currentPage < 0
                paginatorParams.currentPage = 0

        scope.goStart = () ->
            paginatorParams.currentPage = 0

        scope.goPage = (page) ->
            paginatorParams.currentPage = page

        scope.pageTitle = (page) ->
            if page.type?
                return ''
            else
                if page.dots == true and numbers >= 2
                    return '...'
                if scope.totalPages < 10
                    return '●'
                else
                    return page.displayNum

        scope.isActive = (page) ->
            if page.num == paginatorParams.currentPage 
                return true

            # if page.type?
            #     if pagesContentMap[paginatorParams.currentPage] == page.type
            #         return true

            false

        true