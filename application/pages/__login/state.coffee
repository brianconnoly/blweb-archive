buzzlike.service 'loginState', (stateManager) ->
    
    stateManager.registerState 'login',
        enter: 'default'
        name: 'login'
        noMenu: true
        hideRight: true