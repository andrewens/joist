return function(Action, Object, NewObject)
    NewObject.Game { -- create server
        TestVariable = 1, -- set server properties and check them
    }
    NewObject.Player { -- Players automatically trigger the creation of a client
        UserId = 156, -- set the properties and stuff
        Name = "builderman",
    }
    NewObject.Player { -- second Player is so that we can check that the Players are replicated to other Clients
        UserId = 1,
        Name = "Roblox",
    }
     NewObject.Player { -- third Player cuz I felt like it
        UserId = 261,
        Name = "shedletsky",
    }

    Action.TestAction(2)

    Object.Game { -- this has to be replicated to all of the Players as well
        TestVariable = 2,
    }

    -- TODO: insidious ways of testing breaking the API:
    -- 1. Don't replicate server properties to clients
    -- 2. Don't replicate Player to client
    -- 3. Don't replicate new players to old clients
    -- 4. DON'T REPLICATE OLD PLAYERS TO NEW CLIENT
    -- ...
end
