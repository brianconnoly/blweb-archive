*deps: communityService, $filter

if !scope.wizard.data.name?
    scope.wizard.data.name = $filter('timestampMask')('hh:mm, DD ofMMM')
