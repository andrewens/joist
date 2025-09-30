return function(Action, Object, NewObject)
    NewObject.Game { -- makes a new server
        TestVariable = 1, -- sets the server's properties to these
    }

    Action.TestAction(2) -- calls a function on the server and passes the arguments

    Object.Game { -- reads the server state and checks that it's the same as this
        TestVariable = 2,
    }
end
