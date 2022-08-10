# 05-Aug-2022 WDJ Added debug visualizer
inkling "2.0"

# Define a type that represents the per-iteration state
# returned by the simulator.
type SimState {
    # VP Link analog tag (-50.0,50.0), meters left or right of the target
    x_position: number<-50.0 .. 50.0>,
    # VP Link analog tag (-100.0,100.0), EU=m/s;  Velocity left or right
    x_velocity: number<-100.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), meters above the surface.
    y_position: number<0.0 .. 100.0>,
    # VP Link analog tag (-100.0,100.0), EU=m/s;  Velocity up (positive) or down
    y_velocity: number<-100.0 .. 100.0>,
}
using Math
using Goal

const SimulatorVisualizer = "https://intelligent-ops.com/bonsai/visualizations/lunarlander/index.html"

# Define a type that represents the per-iteration action
# accepted by the simulator.
type SimAction {
    # VP Link analog tag (0.0,1.0), Thrust from the vertical engine, scaled to match 2 Gs with a 100kg lander.
    engine1: number<0.0 .. 1.0>,
    # VP Link analog tag (-1.0,1.0), Net thrust from the horizontal engines.
    engine2: number<-1.0 .. 1.0>,
}

# Per-episode configuration that can be sent to the simulator.
# All iterations within an episode will use the same configuration.
type SimConfig {
    # Name of VP Link .icf file to load at start of episode. Available files are ['PreLandingPos.icf', 'StartingPoint.icf']
    _initialConditions: string,
    # Comma separated list of VP Link .sce file(s) to load at start of episode. Available files are []
    _scenarios: string,
    # VP Link timestep (secs)
    _timeStep: number,
    # Bonsai timestep (secs, 0 < x <= 3E6)
    _reportEvery: number,
    # VP Link analog tag (-50.0,50.0), meters left or right of the target
    x_position: number<-50.0 .. 50.0>,
    # VP Link analog tag (-100.0,100.0), EU=m/s;  Velocity left or right
    x_velocity: number<-100.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), meters above the surface.
    y_position: number<0.0 .. 100.0>,
    # VP Link analog tag (-100.0,100.0), EU=m/s;  Velocity up (positive) or down
    y_velocity: number<-100.0 .. 100.0>,
}

simulator Simulator(action: SimAction, config: SimConfig): SimState {
    # Automatically launch the simulator with this
    # registered package/SIM name.
    package "lunarlander"
}

# Define a concept graph
graph (input: SimState): SimAction {
    concept Hover(input): SimAction {
        curriculum {
            # The source of training for this concept is a simulator
            # that takes an action as an input and outputs a state.
            source Simulator
            training {
                EpisodeIterationLimit: 60,
                # LessonRewardThreshold: 27,
                # LessonSuccessThreshold: 0.82,
            }

            # Add goals here describing what you want to teach the brain
            # See the Inkling documentation for goals syntax
            # https://docs.microsoft.com/bonsai/inkling/keywords/goal
            goal (s: SimState) {
                drive FourMetersOffGround:
                    s.y_position
                    in Goal.Sphere(4, 0.4)
                avoid HittingGround:
                    s.y_position
                    in Goal.Range(-1, 0.0)
            }
            lesson StartNear4m {
                # Scenarios set the values in the SimConfig to drive the starting state
                scenario {
                    _timeStep: 0.5,
                    _reportEvery: 0.5,
                    _initialConditions: "StartingPoint.icf",
                    y_position: number<2 .. 6>, # Start near target Y value
                }
            }
            lesson StartUpTo10m {
                # Scenarios set the values in the SimConfig to drive the starting state
                scenario {
                    _timeStep: 0.5,
                    _reportEvery: 0.5,
                    _initialConditions: "StartingPoint.icf",
                    y_position: number<2 .. 10>, # Start farther away
                }
            }
            lesson StartUpTo40m {
                # Scenarios set the values in the SimConfig to drive the starting state
                scenario {
                    _timeStep: 0.5,
                    _reportEvery: 0.5,
                    _initialConditions: "StartingPoint.icf",
                    y_position: number<1 .. 40>, # Start really high up
                }
            }
        }
    }
    concept Maintain_HPos(input): SimAction {
        curriculum {
            # The source of training for this concept is a simulator
            # that takes an action as an input and outputs a state.
            source Simulator
            training {
                EpisodeIterationLimit: 60,
                # LessonRewardThreshold: 27,
                # LessonSuccessThreshold: 0.82,
            }

            # Add goals here describing what you want to teach the brain
            # See the Inkling documentation for goals syntax
            # https://docs.microsoft.com/bonsai/inkling/keywords/goal
            goal (s: SimState) {
                drive FourMetersOffGround:
                    s.y_position
                    in Goal.Sphere(4, 0.5)
                avoid HittingGround:
                    s.y_position
                    in Goal.Range(-1, 0.0)
                drive StayWithinFlags:
                    s.x_position
                    in Goal.Sphere(0, 1)
                # drive QuietValve2: s.FY100 in Goal.Sphere(s.FY100[1], 1)
                # avoid Overflow: s.LI100 in Goal.RangeAbove(92)
            }
            lesson StartNearFlags {
                # Scenarios set the values in the SimConfig to drive the starting state
                scenario {
                    _timeStep: 0.5,
                    _reportEvery: 0.5,
                    _initialConditions: "StartingPoint.icf",
                    x_position: number<-3 .. 3>, # Start near the flags
                }
            }
            lesson StartWithin_5m {
                # Scenarios set the values in the SimConfig to drive the starting state
                scenario {
                    _timeStep: 0.5,
                    _reportEvery: 0.5,
                    _initialConditions: "StartingPoint.icf",
                    x_position: number<-5 .. 5>, # Start within 5m of the flags
                }
            }
        }
    }
    concept Land(input): SimAction {
        curriculum {
            # The source of training for this concept is a simulator
            # that takes an action as an input and outputs a state.
            source Simulator
            training {
                EpisodeIterationLimit: 60,
            }

            # Add goals here describing what you want to teach the brain
            # See the Inkling documentation for goals syntax
            # https://docs.microsoft.com/bonsai/inkling/keywords/goal
            goal (s: SimState) {
                reach LandOnGround:
                    Math.Abs(s.y_position)
                    in Goal.Range(0, 0.01)
                reach LandSlowly:
                    Math.Abs(s.y_velocity)
                    in Goal.Range(-0.2, -0.01)
                drive WithinFlags:
                    Math.Abs(s.x_position)
                    in Goal.Range(-1, 1)
                # drive QuietValve2: s.FY100 in Goal.Sphere(s.FY100[1], 1)
                # avoid Overflow: s.LI100 in Goal.RangeAbove(92)
            }
            lesson StartNearFlags {
                # Scenarios set the values in the SimConfig to drive the starting state
                scenario {
                    _timeStep: 0.5,
                    _reportEvery: 0.5,
                    _scenarios: "StartingPoint.icf",
                    x_position: number<-3 .. 3 step 0.1>, # Start near the flags
                    y_position: number<1 .. 4>, # Start really high up
                }
            }
            lesson StartAwayFromFlags {
                # Scenarios set the values in the SimConfig to drive the starting state
                scenario {
                    _timeStep: 0.5,
                    _reportEvery: 0.5,
                    _scenarios: "StartingPoint.icf",
                    x_position: number<-15 .. 15>, # Start farther away from the flags
                    y_position: number<1 .. 10>, # Start really high up
                }
            }
        }
    }
    output concept TheMission(input): SimAction {
        select Hover
        select Maintain_HPos
        select Land
        curriculum {
            source Simulator
            training {
                EpisodeIterationLimit: 80,
            }
            goal (s: SimState) {
                reach LandOnGround:
                    Math.Abs(s.y_position)
                    in Goal.Range(0, 0.01)
                reach LandSlowly:
                    Math.Abs(s.y_velocity)
                    in Goal.Range(-0.2, -0.01)
                drive WithinFlags:
                    Math.Abs(s.x_position)
                    in Goal.Range(-1, 1)
            }
            lesson One {
                # Because we're using relative positions, just need to randomize initial position to be far and close to the target
                # "PickOne" starts at a random position within the full range.
                scenario {
                    _timeStep: 0.5,
                    _reportEvery: 0.5,
                    _scenarios: "StartingPoint.icf",
                    x_position: number<-14 .. 14>, # Start far away from the flags
                }
            }
        }
    }
}

#! Visual authoring information
#! eyJ2ZXJzaW9uIjoiMi4wLjAiLCJ2aXN1YWxpemVycyI6eyJTaW11bGF0b3JWaXN1YWxpemVyIjoiaHR0cHM6Ly9pbnRlbGxpZ2VudC1vcHMuY29tL2JvbnNhaS92aXN1YWxpemF0aW9ucy9sdW5hcmxhbmRlci8iLCJEZWJ1ZyBWaXN1YWxpemVyIjoiaHR0cHM6Ly9pbnRlbGxpZ2VudC1vcHMuY29tL2JvbnNhaS92aXN1YWxpemF0aW9ucy9sdW5hcmxhbmRlci9pbmRleC5odG1sP2RlYnVnPXRydWUifSwiZ2xvYmFsIjp7InZpc3VhbGl6ZXJOYW1lcyI6WyJTaW11bGF0b3JWaXN1YWxpemVyIl19fQ==
