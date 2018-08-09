*deps: localStorageService, socketAuth

class novaAppStateSaver

    constructor: (@appSID) ->
        @savers = {}

    register: (id, data) ->
        @savers[id] = data
        data.load @load id

    save: (id) ->
        data = @savers[id].save()
        dataString = JSON.stringify data
        localStorageService.add socketAuth.session.user_id + ':appState:' + @appSID + ':' + id, dataString
        data

    load: (id) ->
        dataString = localStorageService.get socketAuth.session.user_id + ':appState:' + @appSID + ':' + id

        if dataString?.length > 0
            try
                data = JSON.parse dataString
                return data
            catch e
                true

         @save id


novaAppStateSaver