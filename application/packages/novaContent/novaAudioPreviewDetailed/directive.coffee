*deps: $sce

scope.getAudioUrl = () ->
    $sce.trustAsResourceUrl scope.item.source
