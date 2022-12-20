# 19-Dec-2022 WDJ  This brain is the full brain in the Lunar Lander training series.
#                  It is very complicated because it attempts to show off all kinds of
#                  bonsai features.  If you want to get started without drinking from a firehose,
#                  follow the example by starting with a simpler brain at 
#                  https://github.com/capesoftware/bonsai-vplink/tree/main/samples/lunarlander/chapter_1
inkling "2.0"
using Math
using Goal

# A visualizer is optional, but a nice way to see what is happening while your brain is training 
#  or in custom assessments.  Note this web site provides two different visualizers, a normal one
#  and a "Debug Visualizer".
const SimulatorVisualizer = "https://intelligent-ops.com/bonsai/visualizations/lunarlander/index.html"


# Note that the SimState, SimAction and SimConfig can all be generated from a VP Link simulation
#   by the Bonsai Interface Creator tool. This tool creates the SIM.ZIP file you can drop into
#   an empty VP Link SIM to create your project-specific managed SIM.

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

type XSubState {  # Used as a smaller state for the concepts that train the horizontal engine.
    x_position: number<-50.0 .. 50.0>,
    x_velocity: number<-100.0 .. 100.0>,
}

type YSubState {  # Used as a smaller state for the concepts that train the vertical (main) engine.
    y_position: number<0.0 .. 100.0>,
    y_velocity: number<-100.0 .. 100.0>,
}

type Engine1Action {
    # VP Link analog tag (0.0,1.0), Thrust from the vertical engine, scaled to match 2 Gs with a 100kg lander.
    engine1: number<0.0 .. 1.0>,
}

type Engine2Action {
    # VP Link analog tag (-1.0,1.0), Net thrust from the horizontal engines.
    engine2: number<-1.0 .. 1.0>,
}

# This function is used in the programmed concept to reduce the size of the full SimState to only
#   the bits that a specific learned concept need.
function ReduceStateForHorizontalEngine(s: SimState): XSubState {
    return {
        x_position: s.x_position,
        x_velocity: s.x_velocity,
    }
}

# This function is used in the programmed concept to reduce the size of the full SimState to only
#   the bits that a specific learned concept need.
function ReduceStateForMainEngine(s: SimState): YSubState {
    return {
        y_position: s.y_position,
        y_velocity: s.y_velocity,
    }
}

# This function is used to recreate the full SimAction from the output of individual concepts
function CombineEngines(e1: Engine1Action, e2: Engine2Action): SimAction {
    return {
        engine1: e1.engine1,
        engine2: e2.engine2
    }
}

# A function which is useful inside a programmed reward function
function VPLinkReward(target: number, currentValue: number, halfdiffA: number, halfdiffB: number) {
    # See https://medium.com/@BonsaiAI/reward-functions-writing-for-reinforcement-learning-video-85f1219a0bde
    # This reward is a combination of inverse exponential and a power function
    # The rewardA is the eponential reward that gives a nice gradient to get near
    #   the target.  
    # The rewardB is a steeply sloped reward to encourage getting right on the target
    # The precisionRewardFactor determines how important it is to get right on the target
    # The range of this function is <0 .. precisionRewardFactor+1>
    # 20-Sep-2021 WDJ Divided result by (1+precisionRewardFactor) so output range is now <0 .. 1>
    var rewardA: number
    var error: number
    var rewardB: number
    var precisionRewardFactor = 1
    error = Math.Abs(target - currentValue)
    rewardA = Math.E ** (-((error / halfdiffA) ** 2))
    rewardB = 0
    if (error < halfdiffB / 2) {
        rewardB = 1 - Math.Sqrt(error / (halfdiffB / 2))
    }
    return (rewardA + precisionRewardFactor * (rewardB)) / (1 + precisionRewardFactor)
}

# A more flexible function which is useful inside a programmed reward function
function VPLinkRewardEx(target: number, currentValue: number, halfdiffA: number, halfdiffB: number, expon: number, precisionRewardFactor: number, basement: number) {
    # See https://medium.com/@BonsaiAI/reward-functions-writing-for-reinforcement-learning-video-85f1219a0bde
    # This reward is a combination of inverse exponential and a power function
    # The rewardA is the eponential reward that gives a nice gradient to get near
    #   the target.  
    # The rewardB is a steeply sloped reward to encourage getting right on the target
    # The precisionRewardFactor determines how important it is to get right on the target
    # The range of this function is <0 .. precisionRewardFactor+1>
    # 20-Sep-2021 WDJ Divided result by (1+precisionRewardFactor) so output range is now <0 .. 1>
    # 17-Dec-2022 WDJ Testing shows that with an expon of 0.7, the error/halfdiffA should be < 8
    #                 Higher exponents give a less sharp tip, but decay faster,
    #                 Exponent of 2.0 is not effective for error/halfdiffA > (2 to 2.5) 
    #                 basement should be negative
    var rewardA: number
    var error: number
    var rewardB: number
    basement = Math.Min(basement, 0.0)  # make sure this is negative
    error = Math.Abs(target - currentValue)
    rewardA = (1 - basement) * Math.E ** (-((error / halfdiffA) ** expon)) + basement
    rewardB = 0
    if (error < halfdiffB / 2) {
        rewardB = 1 - Math.Sqrt(error / (halfdiffB / 2))
    }
    return (rewardA + precisionRewardFactor * (rewardB)) / (1 + precisionRewardFactor)
}


# A possible function to teach the lander move between the flags
function HoverXReward(s: SimState) {
    var targetPos = VPLinkReward(0, s.x_position, 3, 0.5)
    var lowVelocity = VPLinkReward(0, s.x_velocity, 6 * 0.02, 0.02)
    return (targetPos + lowVelocity) / 2.0
}

# A possible function to teach the lander to Hover
function HoverYReward(s: SimState) {
    var targetPosReward = 0
    var lowVelocityReward = 0
    if (s.y_position > 0) {
        targetPosReward = VPLinkReward(4, s.y_position, 2, 0.5)
        lowVelocityReward = VPLinkReward(0, s.y_velocity, 15 * 0.1, 0.1)
    }
    return (3 * targetPosReward + lowVelocityReward) / 4.0
}

# A possible function to teach the lander to land slowly
function LandingReward(s: SimState) {
    var targetPosReward = 0
    var lowVelocityReward = 0
    if (s.y_position > 0) {
        targetPosReward = VPLinkReward(0, s.y_position, 1, 5) + VPLinkReward(0, s.x_position, 1, 1)
        lowVelocityReward = VPLinkReward(-0.4, s.y_velocity, 0.2, 0.4)
    } else if ((s.y_position == 0) and (s.y_velocity < 0) and ( s.y_velocity > -0.5))
    {
        lowVelocityReward = lowVelocityReward + 10
    } else 
    {
        lowVelocityReward = -100
    }
    return (targetPosReward + 3 * lowVelocityReward) / 5.0
}

# A revised reward function that teaches the lander to land slowly.
function LandingReward_v2(s: SimState) {
    var targetPosReward = 0
    var lowVelocityReward = 0
    # Reward for being close to (0,0)
    targetPosReward = VPLinkRewardEx(0, s.y_position, 5, 1, 0.7, 1.0, -0.5) + VPLinkRewardEx(0, s.x_position, 5, 1, 0.7, 1, 0.0)
    if (s.y_position > 0) {
        # Also reward for going down at -0.4 m/x
        lowVelocityReward = VPLinkRewardEx(-0.4, s.y_velocity, 0.4, 1, 0.7, 1.0, 0.0)
    } else if ((s.y_position == 0) and (s.y_velocity < 0) and ( s.y_velocity > -0.5))
    {
        # bonus for landeing anywhere (and not crashing)
        lowVelocityReward = lowVelocityReward + 100
        if ( (s.x_position >= -2.0) and (s.x_position <= 2.0) )
        {
            # Give a little extra the closer you are to the center
            targetPosReward = targetPosReward + 100  * (2 - Math.Abs(s.x_position))/2
        }
    } else 
    {
        lowVelocityReward = -100
    }
    return (targetPosReward + lowVelocityReward) / 2.0
}

# A terminal function used in the Land1 concept to terminate the episode
function LandingDone(s: SimState)
{
    return s.y_position == 0.0
}

# This defines the simulator to be used.
simulator Simulator(action: SimAction, config: SimConfig): SimState {
    # Automatically launch the simulator with this
    # registered package/SIM name.
    package "lunarlander"
}

# This defines the simulator to be used for the Hover concept.  Note that different
#   simulators can be used to train different concepts.  But in this case, while different
#   simulators are defined, they all use the same underlying SIM container.
simulator MainEngineSimulator(action: Engine1Action, config: SimConfig): SimState {
    # Automatically launch the simulator with this
    # registered package name.
    package "lunarlander"
}

simulator HorizontalEngineSimulator(action: Engine2Action, config: SimConfig): SimState {
    # Automatically launch the simulator with this
    # registered package name.
    package "lunarlander"
}

# Define a concept graph
graph (input: SimState): SimAction {
    # This conccept reduces the state so subsequent concepts are easier to train
    concept StateForHorizontalEngine(input): XSubState {
        programmed ReduceStateForHorizontalEngine
    }
    # This conccept reduces the state so subsequent concepts are easier to train
    concept StateForMainEngine(input): YSubState {
        programmed ReduceStateForMainEngine
    }
    # This concept teaches the brain to use the main engine (the vertical one) to hover 
    #   the lander at the target altitude (between 3 and 5 meters).
    concept Hover(StateForMainEngine): Engine1Action {
        curriculum {
            # The source of training for this concept is a simulator
            # that takes an action as an input and outputs a state.
            source MainEngineSimulator
            training {
                EpisodeIterationLimit: kEpisodeHoverMaxSecs/ReportEverySecs,
                ## LessonRewardThreshold: 40,
                # LessonSuccessThreshold: 0.82,
                TotalIterationLimit: kTotalIterationLimit,
                NoProgressIterationLimit: kNoProgressLimit,
            }

            # Add goals here describing what you want to teach the brain
            # See the Inkling documentation for goals syntax
            # https://docs.microsoft.com/bonsai/inkling/keywords/goal
            ##reward HoverYReward
            goal (s: SimState) {
                drive Hovering weight 5:
                    [s.y_position, s.y_velocity]
                    in Goal.Box([3, 5], [-TargetCrashThreshold, TargetCrashThreshold])
                # These avoid statements will stop the episode early if reached (makes training go faster)
                avoid HittingGround:
                    s.y_position
                    in Goal.RangeBelow(0.01)
                avoid FlyingIntoSpace:
                    s.y_position
                    in Goal.RangeAbove(95)
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

    # This concept teaches the brain to use the horizonal engine to maintain its position 
    #   between the flags.  Actually the flags are +/- 2 meters from the target, but we set
    #   the Goal.Box to +/- 0.5 meters.
    concept GetWithinFlags(StateForHorizontalEngine): Engine2Action {
        curriculum {
            # The source of training for this concept is a simulator
            # that takes an action as an input and outputs a state.
            source HorizontalEngineSimulator
            training {
                EpisodeIterationLimit: kEpisodeHoverMaxSecs/ReportEverySecs,
                # LessonRewardThreshold: 27,
                # LessonSuccessThreshold: 0.82,
            }

            # Add goals here describing what you want to teach the brain
            # See the Inkling documentation for goals syntax
            # https://docs.microsoft.com/bonsai/inkling/keywords/goal
            goal (s: SimState) {
                drive StayWithinFlags:
                    [s.x_position, s.x_velocity]
                    in Goal.Box([-0.5, 0.5], [-0.02, 0.02])
            }
            lesson StartNearFlags {
                # Scenarios set the values in the SimConfig to drive the starting state
                scenario {
                    _initialConditions: "StartingPoint.icf",  # Whoops, maybe this was _scenarios pre v22
                    _timeStep: VPLinkTimeStepSecs,
                    _reportEvery: ReportEverySecs,
                    x_position: number<-3 .. 3>, # Start near the flags
                }
            }
            lesson StartWithin_10m {
                # Scenarios set the values in the SimConfig to drive the starting state
                scenario {
                    _initialConditions: "StartingPoint.icf",  # Whoops, maybe this was _scenarios pre v22
                    _timeStep: VPLinkTimeStepSecs,
                    _reportEvery: ReportEverySecs,
                    x_position: number<-10 .. 10>, # Start within 5m of the flags
                }
            }
        }
    }
    # This concept combines the action of two input concepts to form the full SimAction that
    #   controls both engines.
    concept CombinedEngineThrust(Hover, GetWithinFlags): SimAction {
        programmed CombineEngines
    }

    # This concept teachs the brain to land slowly between the flags while keeping the downward 
    #   velocity less than the TargetCrashThreshold
    concept Land1(input): SimAction {
        curriculum {
            # The source of training for this concept is a simulator
            # that takes an action as an input and outputs a state.
            source Simulator
            training {
                EpisodeIterationLimit: kEpisodeLandMaxSecs/ReportEverySecs,
                TotalIterationLimit: kTotalIterationLimit,
                NoProgressIterationLimit: 500000,
            }
            # Add goals or programmed rewares here describing what you want to teach the brain
            reward LandingReward_v2
            terminal function (s: SimState){
                return s.y_position == 0
            }
            # See the Inkling documentation for goals syntax
            # https://docs.microsoft.com/bonsai/inkling/keywords/goal
            # goal (s: SimState) {
            #     reach LandOnGround:  # stops episode once this occurs
            #         s.y_position in Goal.RangeBelow(0.1)
            #     drive LandSlowly:
            #         s.y_velocity in Goal.Range(-TargetCrashThreshold, 0)
            #     drive WithinFlags:
            #         s.x_position
            #         in Goal.Range(-1, 1)
            #     avoid HardLanding:
            #         s.y_velocity in Goal.RangeBelow(-(TargetCrashThreshold+0.2))
            #     avoid FlyingTooHigh:
            #         s.y_position
            #         in Goal.RangeAbove(30)
            # }
            lesson StartNearFlags {
                # Here we set the values in the SimConfig to drive the starting state
                scenario {
                    _initialConditions: "PreLandingPos.icf",  # Whoops, this was _scenarios pre v22
                    _timeStep: VPLinkTimeStepSecs,
                    _reportEvery: ReportEverySecs,
                    x_position: number<-4 .. 4 step 0.25>, # Start near the flags
                    y_position: number<1 .. 4>, # Start low
                }
            }
            lesson StartAwayFromFlags {
                # Set the starting state a farther away from the flags. This should be more difficult
                #   for the brain to achieve the result.
                scenario {
                    _initialConditions: "PreLandingPos.icf",  # Whoops, this was _scenarios pre v22
                    _timeStep: VPLinkTimeStepSecs,
                    _reportEvery: ReportEverySecs,
                    x_position: number<-12 .. 12>, # Start farther away from the flags
                    y_position: number<1 .. 10>, # Start higher
                }
            }
        }
    }

    # The "output concept" puts everything together and outputs the final recommendation from the brain
    output concept TheMission(input): SimAction {
        select CombinedEngineThrust {
            mask function (s: SimState): number {
                # return 1 if this option should be prohibited, 0 otherwise
                # Do not hover if we are maintaining horizontal position or landing
                var enabled: number<0, 1, > = (s.y_position > 3) or (s.x_position < -2) or (s.x_position > 2) or (Math.Abs(s.y_velocity) > 0.1)
                return (enabled == false)
            }
        }
        select Land1 {
            mask function (s: SimState): number {
                # return 1 if this option should be prohibited, 0 otherwise
                # only Land if we are in the zone
                # Note: '(Abs(x - center) < radius)' is equivalent to 'x in Sphere(center, radius)'
                var enabled: number<0, 1, > = (s.y_position < 5) and (Math.Abs(s.y_velocity - (-0.2)) <= 0.3)
                return (enabled == false)
            }
        }
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
