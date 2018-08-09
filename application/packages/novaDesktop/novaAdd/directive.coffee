*deps: novaAddMenu, novaWizard
*replace: true

scope.novaAddMenu = novaAddMenu
scope.showAddMenu = (e) ->
    novaAddMenu.launch 
        left: $(e.target).offset().left + 10
        bottom: 45
    true

scope.recentWizards = ['text','project']
scope.fireAdd = (recent) ->
    novaWizard.fire recent