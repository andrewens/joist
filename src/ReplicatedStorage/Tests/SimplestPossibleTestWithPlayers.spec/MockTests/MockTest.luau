return function(Action, Object, NewObject)
    NewObject.Game { -- create server
        TestVariable = 1, -- set server properties and check them
    }
    NewObject.Player { -- Players automatically trigger the creation of a client
        UserId = 156, -- set the properties and stuff
        Name = "builderman",
    }

    -- create the client
    -- check that the server properties got replicated to the client
    Action.TestAction(2)

    Object.Game {
        TestVariable = 2,
    }
end
