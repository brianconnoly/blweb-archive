buzzlike.directive 'loadHtml', () ->
    restrict: 'A'
    scope:
        loadHtml: '='
    link: (scope, element, attrs) ->
        elem = $ element
        console.log scope.loadHtml
        $.get scope.loadHtml, (html) ->
            elem.html html
        # $(elem).load scope.loadHtml