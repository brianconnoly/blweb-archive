buzzlike.factory('properties', [ () ->
    properties =
        serverUrl : '$ServerUrl'
        version: '$frontVersion'

    getProperty: (name) ->
        if properties[name].indexOf('$') == 0
            return undefined
        return properties[name]

])