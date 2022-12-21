# 19-Dec-2022 WDJ  This brain is the first step in the Lunar Lander training series.
#                  It is meant to be a simple brain design, so we can add improvements later.
#                  For the full series information, discussion and materials, visit
#                  https://github.com/capesoftware/bonsai-vplink/tree/main/samples/lunarlander
inkling "2.0"
using Math
using Goal

# Note that the SimState, SimAction and SimConfig can all be generated from a VP Link simulation
#   by the Bonsai Interface Creator tool.

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
const kEpisodeLandMaxSecs = 60    # s, how long (in sim time) should it take the brain to land the lander

# This defines the simulator to be used.
simulator Simulator(action: SimAction, config: SimConfig): SimState {
    # Automatically launch the simulator with this registered package/SIM name.
    package "lunarlander"
}

# Define a concept graph
graph (input: SimState): SimAction {

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
                    # v01 [s.y_position, s.y_velocity] in Goal.Box([0,1], [-100, -TargetCrashThreshold])
                    [s.y_position, s.y_velocity] in Goal.Box([0,1], [-100, -(TargetCrashThreshold+0.5)])
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
}
