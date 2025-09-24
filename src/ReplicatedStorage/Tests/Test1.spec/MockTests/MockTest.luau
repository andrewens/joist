return function(Action, Object, NewObject)
    NewObject.Game {
        TestVariable = 1,
    }

    Action.TestAction(2)

    Object.Game {
        TestVariable = 2,
    }
end
