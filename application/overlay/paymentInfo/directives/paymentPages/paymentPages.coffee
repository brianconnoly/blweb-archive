buzzlike.directive "paymentPages", (paymentInfoService, $compile) ->
    restrict: "C"
    link: (scope, element, attrs) ->
        elem = $ element


        scope.showPage = (page) ->
            prevPage = elem.find ".page"
            paymentInfoService.showStep page

            newScope = scope.$new()
            newPage = $('<div>')
                .addClass("page")
                .addClass(page)
                .append( $compile(scope[page])(newScope) )
                .css( {display: 'none'} )
                .appendTo(elem)

            prevPage.fadeOut ->
                prevScope = angular.element(prevPage[0]).scope()
                prevPage.remove()
                prevScope?.$destroy()
                newPage.fadeIn()

            newPage.fadeIn() if !prevPage.length


        setTimeout ->
            scope.showPage 'introPage'
        , 0
        true