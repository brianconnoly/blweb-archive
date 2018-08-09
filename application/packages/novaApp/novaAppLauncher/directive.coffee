*deps: $parse, $compile

elem = $ element
setTimeout ->
    elem.addClass 'created'
, 0

if !scope.session
    scope.session = $parse(attrs.session)(scope)

if attrs.appData?
    scope.appData = $parse(attrs.appData)(scope)
else
    scope.appData = scope.session

scope.$watch 'session.closing', (nVal) ->
    if nVal == true
        elem.removeClass 'created'

if scope.appData.item?
    elem.addClass scope.appData.item.type + '_' + scope.appData.item.id

launcherItem = $ '<div>',
    class: scope.appData.app + 'Launcher' + ' appLauncherContents'
tmpl = tC['/' + scope.appData.app + 'Launcher' + '/template.jade']
launcherItem.append tmpl if tmpl?

elem.append launcherItem
$compile(launcherItem)(scope)