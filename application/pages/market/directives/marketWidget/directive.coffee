buzzlike.directive 'marketWidget', (lotService, resize) ->
    restrict: 'C'
    template: tC['/pages/market/directives/marketWidget']
    link: (scope, element, attrs) ->
        elem = $ element
        itemH = 170
        if 'post' in scope.widget.query.contentTypes? or 'post' in scope.widget.query.contentTypes?
            itemW = 320
        else
            itemW = 170
        elem.find('.content').height scope.widget.lines*itemH

        screen =
            wid: 0
            hei: 0

        resize.registerCb (wid, hei) ->
            nu_wid = ( wid - 300 ) / itemW | 0
            nu_hei = ( hei - 150 ) / itemH | 0

            #diff = ( hei - 150 ) - ( nu_hei * itemH )
            #per_elem = diff / nu_hei

            if screen.wid != nu_wid || screen.hei != nu_hei
                screen.wid = nu_wid
                screen.hei = nu_hei
                elem.find('.content').width screen.wid*itemW

        scope.pages = []
        scope.currentPage = 0
        scope.currentLots = []

        scope.noRight = true
        scope.noLeft = true

        query = $.extend {}, scope.widget.query
        if query.catsIn?
            newCats = []
            for cat in query.catsIn
                newCats.push lotService.categoriesKeys[cat]?.id

            query.catsIn = newCats

        query.count = screen.wid * scope.widget.lines * scope.widget.screens
        query.page = 0

        lotService.fetchLotsByQuery query, (result) ->
            
            # Прячем кнопку "вправо" если пришла 
            # неполная страница

            page = 0
            cnt = 0
            for item in result
                if cnt >= screen.wid * scope.widget.lines
                    page++
                    cnt = 0
                if !scope.pages[page]?
                    scope.pages[page] = []
                scope.pages[page].push item if item
                cnt++

            if page > 0
                scope.noRight = false

            scope.currentPage = scope.pages[0]

        scope.freshOnTop = (item) ->
            -item.createdWhen

        scope.goPage = (page) ->
            scope.currentPage = page

            scope.noRight = false
            scope.noLeft = false

            index = scope.pages.indexOf scope.currentPage
            if index == scope.pages.length-1
                scope.noRight = true

            if index == 0
                scope.noLeft = true
            true

        scope.goRight = ->
            index = scope.pages.indexOf scope.currentPage
            if index < scope.pages.length
                scope.currentPage = scope.pages[index+1]

            if index == scope.pages.length-2
                scope.noRight = true

            scope.noLeft = false
            false

        scope.goLeft = ->
            index = scope.pages.indexOf scope.currentPage
            if index > 0
                scope.currentPage = scope.pages[index-1]

            if index == 1
                scope.noLeft = true

            scope.noRight = false
            false