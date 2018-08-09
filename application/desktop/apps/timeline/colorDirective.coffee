buzzlike.directive 'colorDirective', (localStorageService) ->
    restrict: 'C'
    link: (scope, element, attrs) ->
        color = localStorageService.get 'timeline_color'
        if color?
            $(element).css 'background', color
            element.parent().addClass 'customColor'