*deps: contentService

scope.saveText = ->
    contentService.save
        id: scope.item.id
        type: 'text'
        value: scope.item.value
