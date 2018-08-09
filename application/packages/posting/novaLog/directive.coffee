scope.getContent = (data) ->
    if typeof data == 'string'
        try
            return JSON.stringify JSON.parse(data), null, 4
        catch e
            return data

    try
        return JSON.stringify data, null, 4
    catch e
        data.toString()
    
    
