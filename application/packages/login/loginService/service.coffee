*deps: $rootScope, rpc, env, socketService, socketAuth, localStorageService, browserPopup, localization

# Login state
state =
    mode: 'default'

# Login events
socketService.on 'loginEvent', (msg) ->
    closePopup()

    console.log msg

    switch msg?.type
        when 'AUTH_OK'
            socketAuth.fetchSession()

        when 'REGISTER'
            state.mode = 'newSocial'

        when 'FAIL'
            console.log 'FAIL'

        when 'CLOSE'
            console.log 'CLOSE'

    $rootScope.$applyAsync()

window.try = (msg) ->
    switch msg
        when 'AUTH_OK'
            socketAuth.fetchSession()

        when 'REGISTER'
            state.mode = 'newSocial'

        when 'FAIL'
            console.log 'FAIL'

        when 'CLOSE'
            console.log 'CLOSE'

    $rootScope.$applyAsync()

# Login via external service
networksData = {}
popup = null
popupWatcher = null
closePopup = ->
    if popup?
        popup.close()
        popup = null
    if popupWatcher?
        clearInterval popupWatcher
        popupWatcher = null

loginSn = (sn) ->
    closePopup()

    # state.mode = 'wait'
    url = env.baseurl + 'auth/snauth/' + sn + '?sid=' + localStorageService.get('sid')

    popup = browserPopup.open location.origin+'/resources/static/login.jade?ver=' + (window.frontVersion or ""), # + 'blclose',
        caption: localization.translate('userOptions_updateAccount')
        width: 671
    popup.color = networksData[sn].background

    popup.onload = -> 
        popup.location.href = url
    # popup.onbeforeunload = ->
    #     console.log 'unload'
    #     state.mode = 'default'
    #     $rootScope.$applyAsync()

state: state
networksData: networksData
init: (cb) ->
    rpc.call 
        method: 'social.getNetworks'
        anyway: (data) ->
            if data?.err?
                cb data
                return

            $rootScope.networks = data #[]
            $rootScope.pickerNetworks = []
            $rootScope.availableNetworks = {}
            $rootScope.networksData = {}

            if !data then return cb error 0
            for sn in $rootScope.networks
                if sn.enable or localStorage['DEV_MODE'] == true
                    networksData[sn.type] = 
                        enable: sn.enable
                        background: sn.background

                    $rootScope.pickerNetworks.push
                        name: sn.name
                        value: sn.type
                        title: sn.type
                        class: sn.type
                        style:
                            background: sn.background

                $rootScope.availableNetworks[sn.type] = sn.enable
                $rootScope.networksData[sn.type] = {
                    enable: sn.enable
                    background: sn.background
                }

            $rootScope.pickerNetworks.push
                value: null
                title: "bl"
                class: "null"
                style:
                    background: "#000"

            $rootScope.networks.push
                type: 'bl'
                
            cb data

doLogin: (sn) ->
    if sn == 'bl'
        state.mode = 'blLogin'
    else 
        loginSn sn

auth: (data, cb, merge = false) ->
    socketAuth.authBuzzlike
        login: data.login.toLowerCase()
        password: data.password
    , (res) ->
        if merge
            rpc.call 
                method: 'social.addAccountToUser'
        cb

newSocial: (cb) ->
    rpc.call 
        method: 'auth.registerGuestSN'
        success: () ->
            socketAuth.fetchSession()
            cb? true

register: (data, cb, merge = false) ->
    rpc.call
        method: 'auth.register'
        data: 
            login: data.login.toLowerCase()
            password: data.password
        success: =>
            @auth data, cb, merge
    