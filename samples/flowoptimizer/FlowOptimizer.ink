inkling "2.0"

# Define a type that represents the per-iteration state
# returned by the simulator.
type SimState {
    # VP Link analog tag (-20000.0,20000.0), EU=$/min; Sum of all Stream Values
    OverallValue: number<-20000.0 .. 20000.0>,
}
using Math
using Goal

# Define a type that represents the per-iteration action
# accepted by the simulator.
type SimAction {
    # VP Link analog tag (0.0,100.0), Brain Output for a Valve on Stream 05
    Action_05: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), Brain Output for a Valve on Stream 12
    Action_12: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), Brain Output for a Valve on Stream 04
    Action_04: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), Brain Output for a Valve on Stream 01
    Action_01: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), Brain Output for a Valve on Stream 11
    Action_11: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), Brain Output for a Valve on Stream 08
    Action_08: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), Brain Output for a Valve on Stream 10
    Action_10: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), Brain Output for a Valve on Stream 09
    Action_09: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), Brain Output for a Valve on Stream 02
    Action_02: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), Brain Output for a Valve on Stream 06
    Action_06: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), Brain Output for a Valve on Stream 03
    Action_03: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), Brain Output for a Valve on Stream 07
    Action_07: number<0.0 .. 100.0>,
}

# Per-episode configuration that can be sent to the simulator.
# All iterations within an episode will use the same configuration.
type SimConfig {
    # Name of VP Link .icf file to load at start of episode. Available files are ['FlowOptimizer_Base.icf', 'Function_Inverted.icf', 'Function_Linear.icf', 'Function_SingleMax.icf']
    _initialConditions: string,
    # Comma separated list of VP Link .sce file(s) to load at start of episode. Available files are []
    _scenarios: string,
    # VP Link timestep (secs)
    _timeStep: number,
    # Bonsai timestep (secs, 0 < x <= 3E6)
    _reportEvery: number,
    # VP Link analog tag (-20000.0,20000.0), EU=$/min; Sum of all Stream Values
    OverallValue: number<-20000.0 .. 20000.0>,
}

simulator Simulator(action: SimAction, config: SimConfig): SimState {
    # Automatically launch the simulator with this
    # registered package name.

    # Change this package to the name of the Simulator you built from the FlowOptimizer_sim.zip file
    package "WDJ_FlowOpt"
}

# Define a concept graph
graph (input: SimState): SimAction {
    concept Concept1(input): SimAction {
        curriculum {
            # The source of training for this concept is a simulator
            # that takes an action as an input and outputs a state.
            source Simulator

            # Add goals here describing what you want to teach the brain
            # See the Inkling documentation for goals syntax
            # https://docs.microsoft.com/bonsai/inkling/keywords/goal
            goal (s: SimState)
            {
              maximize MaxValue: s.OverallValue in Goal.RangeAbove(400)
            }
            training {
                EpisodeIterationLimit : 40,
            }
            lesson BaseState
            {
                # Scenarios set the values in the SimConfig to drive the starting state
                scenario
                {
                    _initialConditions: "FlowOptimizer_Base.icf",
                    _timeStep: 1,
                    _reportEvery: 1,
                }
            }
        }
    }
}