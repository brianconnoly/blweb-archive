buzzlike
    .directive "popup", () ->
        restrict: "C"
        link: (scope, elem, attrs) ->
            elem = $(elem)
            elem.on "click", (e) ->
                if e.target == elem[0] || $(e.target).hasClass('closer')
                    scope[attrs.ngShow] = ''
                    elem.fadeOut () ->
                        scope.$apply()
            $(document).on "keyup.popup", (e) ->
                if e.which == 27 || e.keyCode == 27
                    scope[attrs.ngShow] = ''
                    elem.fadeOut()