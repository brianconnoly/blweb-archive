*deps: novaDesktop, account, novaWizard

scope.desktop = novaDesktop.getDesktop (attrs.desktopId or 0)

scope.streamsApp = novaDesktop.registerLauncher
    static: true
    item:
        type: 'streams'
        id: account.user.id
    app: 'novaStreamsApp'

if account.user.novaWelcome == false
    novaWizard.fire 'welcome'
