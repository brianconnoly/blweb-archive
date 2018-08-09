buzzlike.controller 'moderationCtrl', ($scope, updateService, lotService, operationsService, desktopService, httpWrapped, env, socketAuth) ->

    $scope.session.expandedHeader = false
    
    $scope.lotCategories = [
            phrase: 'marketCategory_none'
            value: null
        ,
            phrase: 'marketCategory_1'
            value: 1
        ,
            phrase: 'marketCategory_2'
            value: 2
        ,
            phrase: 'marketCategory_3'
            value: 3
        ,
            phrase: 'marketCategory_4'
            value: 4
    ]
    $scope.lotCat = null

    # TODO: проверять роль пользователя при входе.
    # Если роли "модератор" нет - перенаправлять в маркет

    # Список лотов для модерации
    $scope.moderationLots = []

    # Не будем кэшировать эти лоты. Каждый раз запрашиваем их по особому
    # маршруту, доступному только пользователям с ролью модератора
    reloadList = ->
        lotService.getModeration (list) ->
            $scope.moderationLots.length = 0

            for item in list
                $scope.moderationLots.push item

    socketAuth.init () ->
        reloadList()

    # Одобрение размещения лота
    # Проверка прав осуществляется на бэкенде
    $scope.acceptLot = (lot) ->
        lot.categoryIds = [$scope.lotCat] 
        doModerate lot, 'accepted'
        true

    # При отклонении нужно указать причину
    $scope.rejectLot = (lot) ->
        desktopService.launchApp 'optionsList',
            message: 'reject_lot_reason_request'
            options: [
                {
                    text: 'wrong_tags'
                    action: -> doModerate lot, 'badTags'
                },
                {
                    text: 'wrong_content'
                    action: -> doModerate lot, 'badContent'
                }
            ]

    # Для того чтобы не дублировать код на каждую причину,
    # выносим этот участок в отдельную функцию.
    doModerate = (lot, status, cb) ->
        lotService.moderate 
            lotId: lot.id
            status: status
            categoryIds: if lot.lotCat? then [lot.lotCat] else null
        , cb
        removeLot lot
        true

    # Нужно убирать из списка отмодерированные
    removeLot = (lot) ->
        index = $scope.moderationLots.indexOf lot
        if index > -1
            $scope.moderationLots.splice index, 1
    true

    #
    # Update service
    #

    updateId = updateService.registerUpdateHandler (data) ->
        if data['lot']?
            reloadList()

    $scope.$on '$destroy', ->
        updateService.unRegisterUpdateHandler updateId

