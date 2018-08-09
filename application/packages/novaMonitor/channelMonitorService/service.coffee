*deps: itemService, account, novaWizard

class classEntity extends itemService
    itemType: 'channelMonitor'

    init: () ->
        super()

        novaWizard.register 'socialPaintPicker',
            type: 'sequence'
            steps: [
                id: 'picker'
                directive: 'novaSocialPaintPicker'
                provide: 'paintData'
                customNext: 'novaWizardAction_create'
            ]
            final: (data) =>
                data.cb? data.paintData

new classEntity()
