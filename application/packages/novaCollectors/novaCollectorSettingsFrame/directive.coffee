*deps: ugcService, novaDesktop

elem = $ element

# Frame params
scope.flowFrame.maxWidth = 320

scope.ugc = ugcService.getById scope.flowFrame.item.id

scope.save = ->
    ugcService.save scope.ugc

scope.deleteUGC = () ->
    novaDesktop.launchApp
        app: 'novaOptionsListApp'
        noSave: true
        data:
            text: 'novaCollectorSettings_confirm_delete'
            description: 'popup_collector_delete_subtitle'
            onAccept: =>
                ugcService.delete
                    id: scope.ugc.id
                    type: scope.ugc.type
                , ->
                    scope.flowBox.closeFlowFrame scope.flowFrame
