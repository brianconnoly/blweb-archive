buzzlike.factory 'confirmService', (optionsList, localization) ->
    confTimer = null

    callbacks = []
    deleteItem = (data) ->
        callbacks.push data.cb

        questionText = ''
        if data.entity.type == 'comb'
            questionText = 'delete_lot_withrequests'
        if data.entity.type == 'post'
            questionText = 'delete_lot'
        if data.entity.type == 'lot'
            questionText = 'delete_lot_withrequests'

        optionsList.init questionText, [
            {
                text: 'textEditor_yes'
                action: () ->

                    for cb in callbacks
                        cb(true)

                    callbacks.length = 0
            }
            {
                text: 'textEditor_no'
                action: () ->

                    for cb in callbacks
                        cb(false)

                    callbacks.length = 0
            }
        ]
    {
        deleteItem
    }
