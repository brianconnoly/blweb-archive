buzzlike
    .service 'infinityScroll', ($compile, $rootScope) ->
        # Добавляем список в директиву и компилем ее в .nwfl_viewport
        # Чтобы он был над остальными элементами
        addList = (list, type, offset) ->
            scope = $rootScope
            scope.infinityOffset = offset
            scope.infinityScrollList = list
            $('.nwfl_viewport').append $compile('<div class="infinity-scroll" ng-model="infinityScrollList" options="'+type+'" ng-click="hideInfinity(0)"></div>')(scope)
            $('.infinity-scroll').transition(
                opacity: 0
            , 0)
            .transition(
                opacity: 1
            , 300)
            true
        {
            addList
        }

buzzlike.directive "infinityScroll", (localStorageService, smartDate, stateManager) ->
    restrict: "C"
    require: 'ngModel'
    template: templateCache['/elements/infinityScroll']
    link: (scope, element, attrs, ctrl) ->
        t_timer = {}
        minelement = []

        # Получаем список
        scope.options = []

        # Выходим и убиваем директиву
        escapeState = ->
            clearTimeout(t_timer)
            $('.infinity-scroll').remove()
            stateManager.goBack()

        # Сохраняем данные в зависимости от переданного в element.option списка
        saveState = ->
            if attrs.options == 'timezone'
                if minelement.length != 0
                    scope.userOptions.timezone = minelement.attr('utc')

                    localStorageService.remove 'user.timezone'
                    localStorageService.add 'user.timezone', true
                    smartDate.setShiftTime(Math.floor(minelement.attr('utc')))

                escapeState()

        addScrollState =
            'enter': saveState
            'escape': escapeState

        stateManager.applyState addScrollState

        ctrl.$render = () ->
            scope.options = ctrl.$viewValue
            setTimeout ->
                init()
            , 0

        init = ->
            padding = 16 # Отступы
            countVis = 7 # Количество видимых элементов в списке
            selectedElement = 0
            lastDelta = 0

            # Высота одного элемента
            allItems = $('.infinity-scroll .list .item')
            h = allItems.height() + padding

            # Если элементов больше чем видимых, выставляем высоту на нужное нам кол-во видимых элементов
            # Иначе выставляем другое значение высоты, которое покажет все элементы
            if allItems.length > countVis
                $('.infinity-scroll .list').css
                    height: h * countVis
            else
                $('.infinity-scroll .list').css
                    height: h * allItems.length

            # Высота скролла
            $('.infinity-scroll .wrapper').css
                height: $('.infinity-scroll .list').height()
            # Высота select блока
            $('.infinity-scroll .cur').css
                height: h + padding/2
                marginTop: -h/2
            $('.infinity-scroll .cur div').css
                top: -(h/2) + padding/2

            tmp_h = 0
            $('.infinity-scroll .list .item').each ->
                if scope.selectedtimezone == $(this).attr('utc')
                    selectedElement = $(this).index()

                $(this).css
                    top: tmp_h
                tmp_h += h

            # Ставим курсор на сохраненное значение
            i = 0
            $('.infinity-scroll .list .item').each ->
                elem = $(this)
                list = $('.infinity-scroll .list')
                countVisPos = (selectedElement-Math.floor(countVis/2))

                if countVisPos < 0
                    if i > countVisPos
                        list.scrollTop(0)
                        $('.infinity-scroll .list').prepend($('.infinity-scroll .list .item').last())

                        # Выделяем выбранный элемент
                        if i-1 <= countVisPos
                            $('.infinity-scroll .list .item:eq('+Math.floor(countVis/2)+') span').css
                                color: '#000'
                            $('.infinity-scroll .cur div').css
                                display: 'block'

                    i--

                else if i < countVisPos
                    list.scrollTop(h)
                    if list.scrollTop() >= h-1
                        list.scrollTop(0)
                        $('.infinity-scroll .list').append($('.infinity-scroll .list .item').first())

                        # Выделяем выбранный элемент
                        if i+1 >= countVisPos
                            $('.infinity-scroll .list .item:eq('+Math.floor(countVis/2)+') span').css
                                color: '#000'
                            $('.infinity-scroll .cur div').css
                                display: 'block'
                    i++

                tmp_h = 0
                $('.infinity-scroll .list .item').each ->
                    $(this).css
                        top: tmp_h
                    tmp_h += h

            # Определяем позиции для разных типов
            if element.options == 'timezone'
                $('.infinity-scroll .wrapper').css
                    left: scope.infinityOffset.left - 65
                    top: (padding+8) + scope.infinityOffset.top - $('.infinity-scroll .wrapper').height()/2
            else
                $('.infinity-scroll .wrapper').css
                    left: scope.infinityOffset.left
                    top: padding + scope.infinityOffset.top - $('.infinity-scroll .wrapper').height()/2

            # Обрабатываем скролл
            $('.infinity-scroll .list').off('mousewheel')
            $('.infinity-scroll .list').on('mousewheel', (event, delta, deltaX, deltaY) ->

                if lastDelta % 40 == 0 and delta % 40 == 0
                    speedCenter = 0
                else
                    speedCenter = 500

                # Подгоняем курсор в центр после того как пользователь отпустил тачпад или скролл
                clearTimeout(t_timer)
                t_timer = setTimeout ->
                    cur_top = $('.infinity-scroll .cur').offset().top
                    min = 1000
                    minelement = []
                    tmp_result = 0
                    tmp_min = 1000
                    $('.infinity-scroll .list .item').each ->
                        result = tmp_result = $(this).offset().top - cur_top

                        if result < 0
                            tmp_result *= -1

                        # Определяем самое близкое значение к центру
                        if tmp_result < tmp_min
                            tmp_min = tmp_result
                            min = result
                            # Сохраняем самый близкий к центру элемент
                            minelement = $(this)

                    # Анимируем движение элемента к центру
                    scroll = $('.infinity-scroll .list').scrollTop()

                    # Смещение к центру только для тачпада
                    if lastDelta % 40 == 0 and delta % 40 == 0
                        minelement.children('span').css
                            color: '#000'
                        $('.infinity-scroll .cur div').css
                            display: 'block'
                    else
                        $('.infinity-scroll .list').animate
                            scrollTop: (scroll + min)
                        , '100', 'swing', ->
                            # Выставляем значение, когда анимация завершена
                            minelement.children('span').css
                                color: '#000'
                            $('.infinity-scroll .cur div').css
                                display: 'block'
                , speedCenter

                if event.originalEvent.wheelDelta/120 > 0
                    # up scroll
                    scroll = $(this).scrollTop() - delta
                    $(this).scrollTop(scroll)
                    if $(this).scrollTop() == 0
                        $(this).scrollTop(h)
                        $('.infinity-scroll .list').prepend($('.infinity-scroll .list .item').last())
                else
                    # down scroll
                    scroll = $(this).scrollTop() - delta
                    $(this).scrollTop(scroll)
                    if $(this).scrollTop() > h
                        $(this).scrollTop(0)
                        $('.infinity-scroll .list').append($('.infinity-scroll .list .item').first())

                tmp_h = 0
                $('.infinity-scroll .list .item').each ->
                    $(this).children('span').css
                        color: '#fff'
                    $(this).css
                        top: tmp_h
                    tmp_h += h

                if lastDelta % 40 != 0 and delta % 40 != 0
                    $('.infinity-scroll .cur div').css
                        display: 'none'

                lastDelta = delta
            )

        scope.hideInfinity = (save) ->
            $('.infinity-scroll').transition
                opacity: 0
            , 200, ->
                if save
                    saveState()
                else
                    escapeState()

                scope.$apply()
            true