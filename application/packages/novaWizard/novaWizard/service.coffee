*deps: novaDesktop


class novaWizard

    constructor: ->
        @wizardsData = {}
        @wizards = []

    register: (id, wizard) ->
        @wizardsData[id] = wizard
        @wizards.push id if wizard.system != true

    fire: (id, data = {}, cb) ->
        wizard = @wizardsData[id]
        if !wizard?
            console.log 'Not implemented wizard:', id
            return

        switch wizard.type
            when 'simple'
                wizard.action data
            when 'sequence'
                # sequence = new novaWizardSequence wizard, data
                novaDesktop.launchApp
                    app: 'novaWizardApp'
                    wizardId: id
                    data: data
            else
                console.log 'TODO fire wizard', wizard.type

new novaWizard()
