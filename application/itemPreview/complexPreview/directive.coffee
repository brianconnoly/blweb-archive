buzzlike.directive 'complexPreview', ($compile) ->
    restrict: 'E'
    # template: tC['itemPreview/complexPreview']
    link: (scope, element, attrs) ->
        scope.$watch 'previewItem.contentIds', (nVal) ->
            if !nVal?
                return

            element.empty()

            # Считаем количество контента
            itemsCounter = 0
            singleItem = null
            for type, list of nVal
                itemsCounter += list.length
                singleItem = list[0] if list[0]?

            # Если всего одна сущность - делаем увеличенное превью
            if itemsCounter == 1
                previewScope = scope.$new()
                previewScope.id = singleItem
                previewElem = $compile('<div class="itemPreview single" type="content" id="id" mini></div>')(previewScope)

                element.append previewElem

            # Если меньше или 4, то выводим список
            else if itemsCounter <= 4
                for type, list of nVal
                    for item in list
                        miniScope = scope.$new()
                        miniScope.id = item
                        miniElem = $compile('<div class="itemPreview mini" type="content" id="id" mini></div>')(miniScope)

                        element.append miniElem

            # More than 4 items. Lets group them up!
            else if itemsCounter > 4

                if nVal.image.length > 1
                    # Смотрим количество картинок и прочего контента
                    otherContent = itemsCounter - nVal.image.length

                    # First preview
                    if otherContent < 3
                        miniScope = scope.$new()
                        miniScope.id = nVal.image[nVal.image.length - 1]
                        miniScope.counter = nVal.image.length - ( 3 - otherContent )
                        miniElem = $compile('<div class="itemPreview mini" type="content" id="id" counter="counter" mini></div>')(miniScope)

                        element.append miniElem

                        for i in [0...( 3 - otherContent )]
                            miniScope = scope.$new()
                            miniScope.id = nVal.image[i]
                            miniElem = $compile('<div class="itemPreview mini" type="content" id="id" mini></div>')(miniScope)

                            element.append miniElem

                        # Оставшиеся
                        for type, list of nVal
                            if type != 'image'
                                for item in list
                                    miniScope = scope.$new()
                                    miniScope.id = item
                                    miniElem = $compile('<div class="itemPreview mini" type="content" id="id" mini></div>')(miniScope)

                                    element.append miniElem

                    else
                        miniScope = scope.$new()
                        miniScope.id = nVal.image[nVal.image.length - 1]
                        miniScope.counter = nVal.image.length
                        miniElem = $compile('<div class="itemPreview mini" type="content" id="id" counter="counter" mini></div>')(miniScope)

                        element.append miniElem

                        # Оставшиеся группами
                        if itemsCounter - nVal.image.length > 3
                            for type, list of nVal
                                if type != 'image' && list.length > 0
                                    miniScope = scope.$new()
                                    miniScope.id = list[0]
                                    miniScope.counter = list.length if list.length > 1
                                    miniElem = $compile('<div class="itemPreview mini" type="content" id="id" counter="counter" mini></div>')(miniScope)

                                    element.append miniElem
                    true
                else

                    if nVal.image.length == 1
                        miniScope = scope.$new()
                        miniScope.id = nVal.image[0]
                        miniElem = $compile('<div class="itemPreview mini" type="content" id="id" mini></div>')(miniScope)

                        element.append miniElem

                    if itemsCounter - nVal.image.length <= 3
                        # Оставшиеся
                        for type, list of nVal
                            if type != 'image'
                                for item in list
                                    miniScope = scope.$new()
                                    miniScope.id = item
                                    miniElem = $compile('<div class="itemPreview mini" type="content" id="id" mini></div>')(miniScope)

                                    element.append miniElem
                        return

                    if itemsCounter - nVal.image.length > 3
                        for type, list of nVal
                            if type != 'image' && list.length > 0
                                miniScope = scope.$new()
                                miniScope.id = list[0]
                                miniScope.counter = list.length if list.length > 1
                                miniElem = $compile('<div class="itemPreview mini" type="content" id="id" counter="counter" mini></div>')(miniScope)

                                element.append miniElem

            # Щит (главная картинка)
            if nVal.image.length > 0
                
                shieldPic = nVal.image[0]

                shieldScope = scope.$new()
                shieldScope.id = shieldPic
                shieldElem = $compile('<div class="itemPreview shield" type="content" id="id" mini></div>')(shieldScope)

                element.append shieldElem
        ,true

        true