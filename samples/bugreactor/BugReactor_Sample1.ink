inkling "2.0"
using Goal
using Math

# Define a type that represents the per-iteration state
# returned by the simulator.
type SimState {
    # VP Link analog tag (0.0,2000.0), Level Tag at press =1.4; lfngen:\otherusers\winston\BugReactor\BugReactorDD.xls[lfnWDJ]
    LvlFermenter: number<0.0 .. 2000.0>,
    # VP Link analog tag (0.0,212.0), EU=degF; What is Temperature of the reactor
    Reactor_Temp: number<0.0 .. 212.0>,
    # VP Link analog tag (0.0,14.0), EU=pH; What is pH of the reactor
    Reactor_pH: number<0.0 .. 14.0>,
    # VP Link analog tag (0.0,300.0), Eu=°F;
    Temp_E003_Out: number<0.0 .. 300.0>,
    # VP Link analog tag (0.0,1000.0), EU=kg/min; Production rate of bugs
    BugsProdRate: number<0.0 .. 1000.0>,
    # VP Link analog tag (0.0,130.0), EU=l/min; Flow(design=65) from P_Exch_Disch to 1.4 lfngen:\otherusers\winston\BugReactor\BugReactorDD.xls[lfnWDJ]
    FoodFeedRate: number<0.0 .. 130.0>,
    # VP Link analog tag (0.0,300.0), Eu=°F;
    Temp_E001_ShellIn: number<0.0 .. 300.0>[4],
}

# Define a type that represents the per-iteration action
# accepted by the simulator.
type SimAction {
    ## VP Link analog tag (0.0,100.0), Eu=%;
    V_Acid_Open_Vlv: number<0.0 .. 100.0>,
    ## VP Link analog tag (0.0,100.0), Eu=%;
    V_Base_Open_Vlv: number<0.0 .. 100.0>,
    ## VP Link analog tag (0.0,2000.0), EU=l; Setpoint for Level in the Fermenter (normally 300)
    LvlFermenter_SP: number<0.0 .. 2000.0>,
    ## VP Link analog tag (0.0,130.0), EU=l/min;
    FlowSetPoint: number<0.0 .. 130.0>,
    ## VP Link analog tag (0.0,200.0), Eu=°F;
    TempCWSetPoint: number<0.0 .. 200.0>,

    # VP Link analog tag (0.0,200.0), Eu=°F;
    TempSetPoint: number<0.0 .. 200.0>,
}

# Per-episode configuration that can be sent to the simulator.
# All iterations within an episode will use the same configuration.
type SimConfig {
    # VP Link configuration (deprecated); Built from CreateBonsaiInterface v0.9.1
    _configNumber: number,
    # Name of VP Link .icf file to load at start of episode. Available files are ['Magic_pH_Control.icf', 'PasteurizationStartup.icf', 'ReactorOperation.icf', 'ReactorStartup.icf']
    _initialConditions: string,
    # VP Link timestep (secs)
    _timeStep: number,
    # Bonsai timestep (secs)
    _reportEvery: number,

    # # VP Link analog tag (0.0,2000.0), Level Tag at press =1.4; lfngen:\otherusers\winston\BugReactor\BugReactorDD.xls[lfnWDJ]
    # LvlFermenter: number<0.0 .. 2000.0>,
    # # VP Link analog tag (0.0,212.0), EU=degF; What is Temperature of the reactor
    # Reactor_Temp: number<0.0 .. 212.0>,
    # # VP Link analog tag (0.0,14.0), EU=pH; What is pH of the reactor
    # Reactor_pH: number<0.0 .. 14.0>,
    # # VP Link analog tag (0.0,300.0), Eu=°F;
    # Temp_E003_Out: number<0.0 .. 300.0>,
    # # VP Link analog tag (0.0,1000.0), EU=kg/min; Production rate of bugs
    # BugsProdRate: number<0.0 .. 1000.0>,
    # # VP Link analog tag (0.0,130.0), EU=l/min; Flow(design=65) from P_Exch_Disch to 1.4 lfngen:\otherusers\winston\BugReactor\BugReactorDD.xls[lfnWDJ]
    # FoodFeedRate: number<0.0 .. 130.0>,
    # # VP Link analog tag (0.0,300.0), Eu=°F;
    # Temp_E001_ShellIn: number<0.0 .. 300.0>,
}

simulator Simulator(action: SimAction, config: SimConfig): SimState {
    # package "BugReactorDevTesting"
}

const kJustRight = 176.0
const kLearnToKeepWarm = 140.0
const kTooHot = 180.0


function VPLinkReward(target: number, currentValue: number, radius: number)
{
    # See https://medium.com/@BonsaiAI/reward-functions-writing-for-reinforcement-learning-video-85f1219a0bde
    # This reward is a combination of inverse exponential and a power function
    # The rewardA is the eponential reward that gives a nice gradient to get near
    #   the target.
    # Choose 'radius' at error (=current-target) where you want the rewardA to be about half of the max
    # The rewardB is a steeply sloped reward to encourage getting right on the target
    # The precisionRewardFactor determines how important it is to get right on the target
    # The range of this function is <0 .. precisionRewardFactor+1>
    var rewardA: number
    var error: number
    var rewardB: number
    var precisionRewardFactor = 2.0
    error = Math.Abs(target-currentValue)
    rewardA = Math.E**(-((error/radius)**2))
    var precisionRadius = radius/2
    if ( error < precisionRadius )
    {
        rewardB = 1 - Math.Sqrt(error/precisionRadius)
    } else
    {
        rewardB = 0
    }
    return rewardA + precisionRewardFactor*(rewardB)
}

function PasteurReward( s: SimState)
{
    var good: number
    var bad: number
    good = VPLinkReward( 90, s.Temp_E001_ShellIn[0], 3.0)
    bad = Math.Max(0, 10 * (s.Temp_E001_ShellIn[0] - kTooHot))
    return good - bad
}

# Define a concept graph
graph (input: SimState): SimAction {
    concept Sterilize(input): SimAction {
        curriculum {
            source Simulator
            # reward PasteurReward

          goal (s: SimState)
          {
              # Get within 1 deg of the target
              drive Pasteurize: s.Temp_E001_ShellIn[0] in Goal.Sphere(kLearnToKeepWarm, 1)
              avoid TooHot: s.Temp_E001_ShellIn[0] in Goal.RangeAbove(kTooHot)
          }
          training
          {
                # Give the brain 20 minutes to get the pasteurization going.
                # That is 40 '_reportEvery' increments
                EpisodeIterationLimit: 40, # Brain has 60 "_reportEvery" time steps to make this work
                # NoProgressIterationLimit : 1000000
          }
          lesson MaintainTemperature
          {
          # Scenarios set the values in the SimConfig to drive the starting state
          scenario
          {
          	_configNumber: 0,
            # Each episode will use the same starting conditions
            _initialConditions: "PasteurizationStartup.icf",
            _timeStep: 2,  # VP Link model takes 2 second time steps (for the PIDs to work well)...
            _reportEvery: 30,  # but reports to Bonsai after 30 seconds of sim time has elapsed.
            # We do not need to set any other values, because they are all set in the initialConditions file, above
            }
          }
        }
    }
}
