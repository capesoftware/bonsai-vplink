# Sample Inkling for VP Link SimpleTank demonstration

inkling "2.0"
using Goal

# Define a type that represents the per-iteration state
# returned by the simulator.
type SimState {
    # VP Link analog tag (0.0,100.0), EU=%, Tank Level
    LI100: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), EU=%, Tank Level Setpoint
    LI100_SP: number<0.0 .. 100.0>,
}

# Define a type that represents the per-iteration action
# accepted by the simulator.
type SimAction {
    # VP Link analog tag (0.0,100.0), Control Valve Position (normally ANLIN)
    FY100: number<0.0 .. 100.0>,
}

# Per-episode configuration that can be sent to the simulator.
# All iterations within an episode will use the same configuration.
type SimConfig {
    # VP Link configuration (deprecated); Built from CreateBonsaiInterface v0.9.1
    _configNumber: number,
    # Name of VP Link .icf file to load at start of episode. Available files are []
    _initialConditions: string,
    # VP Link timestep (secs)
    _timeStep: number,
    # Bonsai timestep (secs)
    _reportEvery: number,
    # VP Link analog tag (0.0,100.0), EU=%, Tank Level
    LI100: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), EU=%, Tank Level Setpoint
    LI100_SP: number<0.0 .. 100.0>,
}

simulator Simulator(action: SimAction, config: SimConfig): SimState {
    # Automatically launch the simulator with this
    # registered package name.
    package "zzSimpleTank"
}

# Define a concept graph
graph (input: SimState): SimAction {
    concept Concept1(input): SimAction {
        curriculum {
            # The source of training for this concept is a simulator
            # that takes an action as an input and outputs a state.
            source Simulator

			# No terminal or rewards allowed in goal-based curriculums
			#   terminal Terminal
			#   reward LevelPenalty
			goal (s: SimState)
			{
				drive TargetLevel: s.LI100 in Goal.Sphere(s.LI100_SP, 0.5)
				avoid Overflow: s.LI100 in Goal.RangeAbove(100)
			}
			training {
					EpisodeIterationLimit : 75
			}
			lesson StartFromRandomLevel
			{
				# Scenarios set the values in the SimConfig to drive the starting state
				scenario
				{
					# configNumber: < 1, 2, 3, >
					_configNumber: 0, # deprecated
					_initialConditions: "",
					_timeStep: 5,
					_reportEvery: 15,
					LI100: number <20..90 step 2>,  # BRAIN needs to see all sorts of starting levels...
					LI100_SP: number <20..80 step 1>,  # ...and a variety of starting sepoints.
				}
			}
    }
  }
}
