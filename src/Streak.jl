"""
The Streak Julia package allows you to use Streak's API RESTful interface.


The Streak API powers a majority of the functions and actions a user can make within Streak – creating boxes, pipelines, snippets, etc. 

As a rule: anything you can do in Streak can be done in the API.

We've designed the platform and these docs to be easy to use and understand for people with or without development experience.

Source: https://streak.readme.io/docs/overview
"""
module Streak

    using JSON3, JSONTables, DataFrames, Dates, HTTP
    export apiKey, user, team, pipeline!, table, newsfeed, box, boxespipeline, date!

    mutable struct apiKey
        key::String
    end

    function date!(timestamp)
        return unix2datetime(timestamp/1e3)
    end

    function table(object::JSON3.Array)
        return DataFrame(jsontable(object))
    end

    function table(object::JSON3.Object)

        object = Dict(object)

        if haskey(object, :stageOrder) && haskey(object, :fields) && haskey(object, :aclEntries)
            
            aclEntries = deepcopy(object[:aclEntries])
            stageOrder = deepcopy(object[:stageOrder])
            fields = deepcopy(object[:fields])
            
            for key in [:stageOrder, :fields, :aclEntries]
                pop!(object, key)
            end

            return DataFrame(object), stageOrder, fields, aclEntries

        end

        return DataFrame(object)

    end


    function user(apikey::apiKey)::JSON3.Object
        
        res = HTTP.request("GET", "https://www.streak.com/api/v1/users/me", 
        ["Content-Type" => "application/json", "Authorization"=> "Basic $(apikey.key)"]) |> response -> String(response.body)         
        
        return JSON3.read(res)

    end

    function user(apikey::apiKey, userKey::String)::JSON3.Object
        
        res = HTTP.request("GET", "https://www.streak.com/api/v1/users/$userKey", 
        ["Content-Type" => "application/json", "Authorization"=> "Basic $(apikey.key)"]) |> response -> String(response.body)

        return JSON3.read(res)

    end

    function team(apikey::apiKey)
        
        res = HTTP.request("GET", "https://www.streak.com/api/v2/users/me/teams", 
        ["Content-Type" => "application/json", "Authorization"=> "Basic $(apikey.key)"]) |> response -> String(response.body)

        return JSON3.read(res).results    

    end

    function team(apikey::apiKey, teamKey::String)

        res = HTTP.request("GET", "https://www.streak.com/api/v2/teams/$teamKey", 
        ["Content-Type" => "application/json", "Authorization"=> "Basic $(apikey.key)"]) |> response -> String(response.body)

        return JSON3.read(res)        

    end

    function pipeline!(apikey::apiKey)

        res = HTTP.request("GET", "https://www.streak.com/api/v1/pipelines", 
        ["Content-Type" => "application/json", "Authorization"=> "Basic $(apikey.key)"]) |> response -> String(response.body)

        return JSON3.read(res)      

    end

    function pipeline!(apikey::apiKey, pipelineKey::String)

        res = HTTP.request("GET", "https://www.streak.com/api/v1/pipelines/$pipelineKey", 
        ["Content-Type" => "application/json", "Authorization"=> "Basic $(apikey.key)"]) |> response -> String(response.body)

        return JSON3.read(res)        

    end

    function newsfeed(apikey::apiKey, pipelinekey::String)
        url = "https://www.streak.com/api/v1/pipelines/$pipelinekey/newsfeed"
        res = HTTP.request("GET", url, 
        ["Content-Type" => "application/json", "Authorization"=> "Basic $(apikey.key)"]) |> response -> String(response.body)
        return JSON3.read(res)  
    end

    function newsfeed(apikey::apiKey, key::String, as::Symbol) 
        
        try
            if as == :pipeline
                url = "https://www.streak.com/api/v1/pipelines/$key/newsfeed"
            elseif as == :box
                url = "https://www.streak.com/api/v1/boxes/$key/newsfeed"
            else
                @warn "$as was not recognized, use :box or :pipeline\nUsing newsfeed(apikey::apiKey, key::String) method instead"
                return newsfeed(apikey, key)
            end

            res = HTTP.request("GET", url, 
            ["Content-Type" => "application/json", "Authorization"=> "Basic $(apikey.key)"]) |> response -> String(response.body)


            return JSON3.read(res)
        catch error
            if error == HTTP.ExceptionRequest.StatusError
                @error "Check the api key or if '$key' is a valid box or pipeline key"
            end
        end

    end

    function box(apikey::apiKey, boxkey::String)
        url = "https://www.streak.com/api/v1/boxes/$boxkey"
        res = HTTP.request("GET", url, 
            ["Content-Type" => "application/json", "Authorization"=> "Basic $(apikey.key)"]) |> response -> String(response.body)
        return JSON3.read(res)
    end

    function boxespipeline(apikey::apiKey, pipelinekey::String)
        url = "https://www.streak.com/api/v1/pipelines/$pipelinekey/boxes"
        res = HTTP.request("GET", url, 
            ["Content-Type" => "application/json", "Authorization"=> "Basic $(apikey.key)"]) |> response -> String(response.body)
        return JSON3.read(res)        
    end

end # module