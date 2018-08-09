buzzlike.directive "introPage", (paymentInfoService, $compile, localStorageService) ->
    restrict: "C"
    template: ->
        lang = localStorageService.get 'user.lang'
        tC['/overlay/paymentInfo/partials/intro/' + lang]

    link: (scope, element, attrs) ->  true
