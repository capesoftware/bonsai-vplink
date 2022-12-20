# 19-Dec-2022 WDJ  This brain is the second step in the Lunar Lander training series.
#                  This changes the monolithic brain to a multi-concept brain.
#                  For the full series information, discussion and materials, visit
#                  https://github.com/capesoftware/bonsai-vplink/tree/main/samples/lunarlander
inkling "2.0"
using Math
using Goal

# Note that the SimState, SimAction and SimConfig can all be generated from a VP Link simulation
#   by the Bonsai Interface Creator tool.
# SimState, SimAction, and SimConfig are identical to the prior version--no changes here

# Define a type that represents the per-iteration state returned by the simulator to the brain
type SimState {
    # VP Link analog tag (-50.0,50.0), EU=m; distance left or right of the target
    x_position: number<-50.0 .. 50.0>,
    # VP Link analog tag (-100.0,100.0), EU=m/s;  Velocity left or right
    x_velocity: number<-100.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), EU=m; distance above the surface.
    y_position: number<0.0 .. 100.0>,
    # VP Link analog tag (-100.0,100.0), EU=m/s;  Velocity up (positive) or down
    y_velocity: number<-100.0 .. 100.0>,
}

# Define a type that represents the per-iteration action output by the brain and 
#   accepted by the simulator.
type SimAction {
    # VP Link analog tag (0.0,1.0), Thrust from the vertical engine, scaled to match 2 Gs with a 100kg lander.
    engine1: number<0.0 .. 1.0>,
    # VP Link analog tag (-1.0,1.0), Net thrust from the horizontal engines.
    engine2: number<-1.0 .. 1.0>,
}

# Per-episode configuration data that is sent to the simulator.
# All iterations within an episode will use the same configuration.
type SimConfig {
    # Name of VP Link .icf file to load at start of episode. Available files are ['PreLandingPos.icf', 'StartingPoint.icf']
    _initialConditions: string,
    # Comma separated list of VP Link .sce file(s) to load at start of episode. Available files are ['EnableFuel.sce']
    _scenarios: string,
    # VP Link timestep (secs)
    _timeStep: number,
    # Bonsai timestep (secs, 0 < x <= 3E6)
    _reportEvery: number,
    # VP Link analog tag (-50.0,50.0), EU=m; distance left or right of the target
    x_position: number<-50.0 .. 50.0>,
    # VP Link analog tag (-100.0,100.0), EU=m/s;  Velocity left or right
    x_velocity: number<-100.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), EU=m; distance above the surface.
    y_position: number<0.0 .. 100.0>,
    # VP Link analog tag (-100.0,100.0), EU=m/s;  Velocity up (positive) or down
    y_velocity: number<-100.0 .. 100.0>,
}

# Define a number of constants to keep hard-coded numbers out of the Inkling file.
const TargetCrashThreshold = 0.5  # m/s, max velocity which should not crash the lander
const VPLinkTimeStepSecs = 0.1    # s, this is the timestep of the underlying model
const ReportEverySecs = 0.1       # s, this is the interval between SimState -> SimAction exchanges w/ bonsai
const kTotalIterationLimit = 20000000  # iterations, limits an episode to this many iterations
const kNoProgressLimit = 500000   # iterations, gives bonsai an idea of when to quit
const kEpisodeHoverMaxSecs = 30   # s, how long (in sim time) should it take the brain to hover the lander
const kEpisodeLandMaxSecs = 20    # s, how long (in sim time) should it take the brain to land the lander

# This defines the simulator to be used.
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
                EpisodeIterationLimit: kEpisodeHoverMaxSecs/ReportEverySecs,
                ## LessonRewardThreshold: 40,
                # LessonSuccessThreshold: 0.82,
                TotalIterationLimit: kTotalIterationLimit,
                NoProgressIterationLimit: kNoProgressLimit,
            }

            goal (s: SimState) {
                drive Hovering weight 5:
                    [s.y_position, s.y_velocity]
                    in Goal.Box([3, 5], [-TargetCrashThreshold, TargetCrashThreshold])
                # These avoid statements will stop the episode early if reached (makes training go faster)
                drive WithinFlags:
                    s.x_position in Goal.Range(-2, 2)
                avoid HittingGround:
                    s.y_position in Goal.RangeBelow(0)
                avoid FlyingIntoSpace:
                    s.y_position in Goal.RangeAbove(45)
            }
            lesson StartNear4m {
                # Scenarios set the values in the SimConfig to drive the starting state
                scenario {
                    _timeStep: VPLinkTimeStepSecs,
                    _reportEvery: ReportEverySecs,
                    _initialConditions: "StartingPoint.icf",
                    y_position: number<2 .. 7>, # Start near target Y 
                }
            }
            lesson StartUpTo10m {
                # Scenarios set the values in the SimConfig to drive the starting state
                scenario {
                    _timeStep: VPLinkTimeStepSecs,
                    _reportEvery: ReportEverySecs,
                    _initialConditions: "StartingPoint.icf",
                    y_position: number<2 .. 10>, # Start farther away
                }
            }
            lesson StartUpTo40m {
                # Scenarios set the values in the SimConfig to drive the starting state
                scenario {
                    _timeStep: VPLinkTimeStepSecs,
                    _reportEvery: ReportEverySecs,
                    _initialConditions: "StartingPoint.icf",
                    y_position: number<1 .. 40>, # Start really high up
                }
            }
        }
    }

    # This concept teachs the brain to land slowly between the flags while keeping the downward 
    #   velocity less than the TargetCrashThreshold
    concept Land(input): SimAction {
        curriculum {
            # The source of training for this concept is a simulator
            # that takes an action as an input and outputs a state.
            source Simulator
            training {
                EpisodeIterationLimit: kEpisodeLandMaxSecs/ReportEverySecs,
                TotalIterationLimit: kTotalIterationLimit,
                NoProgressIterationLimit: kNoProgressLimit,
            }
            # Add goals or programmed rewares here describing what you want to teach the brain

            # See the Inkling documentation for goals syntax
            #    https://docs.microsoft.com/bonsai/inkling/keywords/goal
            goal (s: SimState) {
                reach LandOnGround:  # "reach" stops the episode with success once this occurs
                    s.y_position in Goal.RangeBelow(0)
                drive LandSlowly:   # i.e. do not crash the lander
                    s.y_velocity in Goal.Range(-TargetCrashThreshold, 0)
                drive WithinFlags:
                    s.x_position in Goal.Range(-2, 2)
                avoid HardLanding:
                    # s.y_velocity in Goal.RangeBelow(-(TargetCrashThreshold+0.2))  # give a little buffer
                    [s.y_position, s.y_velocity] in Goal.Box([0,1], [-100, -TargetCrashThreshold])
                avoid FlyingIntoSpace:
                    s.y_position in Goal.RangeAbove(50)  # y_postion can go to 100, the visualizer only goes to 50
            }
            lesson StartAnywhere {
                # Set the starting state a farther away from the flags. This should be more difficult
                #   for the brain to achieve the result.
                scenario {
                    _initialConditions: "StartingPoint.icf",
                    _timeStep: VPLinkTimeStepSecs,
                    _reportEvery: ReportEverySecs,
                    x_position: number<-45 .. 45>, # Give a 5 meter margin from the boundary of the problem
                    y_position: number<1 .. 45>, # Start off the groun up to pretty high (but within the visualizer)
                }
            }
        }
    }

    output concept TheMission(Hover, Land): SimAction {
        curriculum {
            source Simulator
            training {
                EpisodeIterationLimit: (kEpisodeHoverMaxSecs+kEpisodeLandMaxSecs)/ReportEverySecs,
            }
            goal (s: SimState) {
                reach LandOnGround:
                    s.y_position in Goal.RangeBelow(0.0)
                drive WithinFlags:
                    s.x_position in Goal.Range(-2, 2)
                avoid HardLanding:
                    # s.y_velocity in Goal.RangeBelow(-(TargetCrashThreshold+0.2))  # give a little buffer
                    [s.y_position, s.y_velocity] in Goal.Box([0,1], [-100, -TargetCrashThreshold])
            }
            lesson One {
                # Because we're using relative positions, just need to randomize initial position to be far and close to the target
                # "PickOne" starts at a random position within the full range.
                scenario {
                    _initialConditions: "StartingPoint.icf",
                    _timeStep: VPLinkTimeStepSecs,
                    _reportEvery: ReportEverySecs,
                    x_position: number<-14 .. 14>, # Start far away from the flags
                    y_position: number<30 .. 40>, # Start high up
                }
            }
        }
    }

}
