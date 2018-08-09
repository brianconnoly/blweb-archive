PaymentInfoCtrl = ($scope, stateManager, paymentInfoService, localStorageService, $sce) ->

    lang = localStorageService.get 'user.lang'

    paymentInfoState =
        'noMenu': true
        'hideRight': true
        'escape': () ->
            stateManager.goBack()

    stateManager.applyState paymentInfoState

    # all templates
    $scope.introPage = $sce.trustAsHtml tC['/overlay/paymentInfo/partials/intro/' + lang]

    $scope.postPage1 = $sce.trustAsHtml tC['/overlay/paymentInfo/partials/postPage1/' + lang]
    $scope.postPage2 = $sce.trustAsHtml tC['/overlay/paymentInfo/partials/postPage2/' + lang]
    $scope.postPage3 = $sce.trustAsHtml tC['/overlay/paymentInfo/partials/offer/' + lang]

    $scope.moneyPage1 = $sce.trustAsHtml tC['/overlay/paymentInfo/partials/moneyPage1/' + lang]
    $scope.moneyPage2 = $sce.trustAsHtml tC['/overlay/paymentInfo/partials/moneyPage2/' + lang]
    $scope.moneyPage3 = $sce.trustAsHtml tC['/overlay/paymentInfo/partials/offer/' + lang]

    $scope.contactsPage = $sce.trustAsHtml tC['/overlay/paymentInfo/partials/contactsPage/' + lang]

    # service
    $scope.status = paymentInfoService.status
    $scope.map = paymentInfoService.map
    $scope.showPage = paymentInfoService.showPage

    $scope.nextStep = ->
        if $scope.allowNext()
            paymentInfoService.nextStep()
    $scope.prevStep = paymentInfoService.prevStep

    $scope.allowNext = ->
        if $scope.status.step == $scope.map[$scope.status.sequence].steps
            return $scope.status.agreed
        true

    $scope.showPage 'introPage'
    #$scope.showPage 'contactsPage', 1

    $scope.$on '$destroy', () ->
        stateManager.goBack()