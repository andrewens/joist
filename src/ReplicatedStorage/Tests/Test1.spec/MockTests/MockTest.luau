return function(State, Action, Object, Constant, Enum, describe)
    describe("This is a fake test")

    State {
        Object.Game {
            TestVariable = 1
        }
    }

    Action.TestAction(2)

    State {
        Object.Game {
            TestVariable = 2
        }
    }
end
