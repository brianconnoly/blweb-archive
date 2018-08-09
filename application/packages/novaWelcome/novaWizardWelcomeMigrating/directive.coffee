*deps: rpc

rpc.call
    method: 'novaMigration.migrate'
    progress: (status, perc) ->
        scope.migrationStatus = 'novaWelcome_migration:' + status.replace(/\ /g,'')
        scope.migrationProgress = perc+'%'
    success: ->
        scope.wizard.pick
            id: true
