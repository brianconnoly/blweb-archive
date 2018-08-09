buzzlike.directive "shader", (stateManager, $rootScope) ->
    restrict: "C"
    link: (scope, elem, attrs) ->
        elem = $ elem
        elem.on "click", (e) ->

            # if !tutorialService.lockAction 'closeshader'
            #     return false

            if !attrs['noclose']
                if e.target == this || $(e.target).hasClass("closer") || $(".bl-droplist .list-position").hasClass("visible")
                    $rootScope.$apply () ->
                        stateManager.faderClick()