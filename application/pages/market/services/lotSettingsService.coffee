# Buzzlike.Market
# Сервис настроек лота контента

# Сервис управляет отображением overlay-окна и редактируемой сущностью

buzzlike.service 'lotSettings', (overlayManager, lotService) ->

    # Состояние объекта
    state = 
        currentLot: null

    # Инициирование редактирования лота
    # Вызываем overlay
    editLotById = (lotId) ->
        lot = lotService.lotsById[lotId]

        return false if !lot?

        state.currentLot = lot
        overlayManager.loadOverlay 'lotSettings'
        true

    # Закрываем окно редактирования
    # При вызове unloadOverlay сработает событие '$destroy' у скоупа окна
    close = ->
        overlayManager.unloadOverlay 'lotSettings'
        state.currentLot = null

    {   
        state

        editLotById
        close
    }
