return function(Action, Object, NewObject)
    -- first State initializes all the new objects

    NewObject.Game { -- this is just a normal server
        TestVariable = 1, -- we call a setter method to set the TestVariable
    }

    Action.TestAction(2) -- all actions work the same; they just call methods

    -- subsequent States are
    Object.Game {
        TestVariable = 2,
    }



end
