buzzlike.service 'filterSettings', (localStorageService) ->

    save = (state, settings) ->
        text = JSON.stringify settings
        localStorageService.add 'filterSettings_' + state, text

    get = (state) ->
        JSON.parse localStorageService.get 'filterSettings_' + state

    {    
        save
        get
    }