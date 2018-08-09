buzzlike.directive "offer", (paymentInfoService, $compile, localStorageService) ->
    restrict: "C"
    template: ->
        lang = localStorageService.get 'user.lang'
        tC['/overlay/paymentInfo/partials/offer/' + lang]

