# QuadTankSimple.ink -- QuadTank Simplest Example Inkling
inkling "2.0"
using Math
using Number
using Goal

const PIDThreshold = 5

const LowSPThreshold = 25
const HighSPThreshold = 25
const TankVolume = 8835.73
const TankVolumeToPercent = TankVolume/100

# Define a type that represents the per-iteration state
# returned by the simulator.
type SimState {
    # VP Link analog tag (0.0,8835.73), Level Tag at press =14.7; lfngen:\otherusers\Winston\QuadTank\QuadTank.xlsx[LFNStd]
    Tank1Volume: number<0.0 .. 8835.73>[2],
    # VP Link analog tag (0.0,8835.73), Level Tag at press =14.7; lfngen:\otherusers\Winston\QuadTank\QuadTank.xlsx[LFNStd]
    Tank2Volume: number<0.0 .. 8835.73>[2],
    # VP Link analog tag (0.0,8835.73), Level Tag at press =14.7; lfngen:\otherusers\Winston\QuadTank\QuadTank.xlsx[LFNStd]
    Tank3Volume: number<0.0 .. 8835.73>,
    # VP Link analog tag (0.0,8835.73), EU=cm3; Level Tag at press =14.7; lfngen:\otherusers\Winston\QuadTank\QuadTank.xlsx[LFNStd]
    Tank4Volume: number<0.0 .. 8835.73>,
    # VP Link analog tag (0.0,100.0), EU=%; Target setpoint for Tank 1
    Tank1_SP: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), EU=%; Target setpoint for Tank 1
    Tank2_SP: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), EU=%; Valve opening from Pump #1 to Tank #1
    Gamma1: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), EU=%; Valve opening from Pump #2 to Tank #2  In QT5, This value is calculated as GammaSum - Gamma1
    Gamma2: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,200.0), EU=%; Sum of the percentages of Gamma1 and Gamma2 (note max is 200)
    GammaSum: number<0.0 .. 200.0>,
}

type SimAction {
    # VP Link analog tag (0.0,100.0), EU=%; Percentage of maximum speed of pump #1
    Pump1Speed: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), EU=%; Percentage of maximum speed of pump #2
    Pump2Speed: number<0.0 .. 100.0>,
}

type SimConfig {
    # VP Link configuration (deprecated); Built from CreateBonsaiInterface v0.9.1
    _configNumber: number,
    # Name of VP Link .icf file to load at start of episode. Available files are ['QuadTank_v4.icf', 'QuadTank_v5.icf']
    _initialConditions: string,
    # VP Link timestep (secs)
    _timeStep: number,
    # Bonsai timestep (secs)
    _reportEvery: number,
    # VP Link analog tag (0.0,8835.73), Level Tag at press =14.7; lfngen:\otherusers\Winston\QuadTank\QuadTank.xlsx[LFNStd]
    Tank1Volume: number<0.0 .. 8835.73>,
    # VP Link analog tag (0.0,8835.73), Level Tag at press =14.7; lfngen:\otherusers\Winston\QuadTank\QuadTank.xlsx[LFNStd]
    Tank2Volume: number<0.0 .. 8835.73>,
    # VP Link analog tag (0.0,8835.73), Level Tag at press =14.7; lfngen:\otherusers\Winston\QuadTank\QuadTank.xlsx[LFNStd]
    Tank3Volume: number<0.0 .. 8835.73>,
    # VP Link analog tag (0.0,8835.73), EU=cm3; Level Tag at press =14.7; lfngen:\otherusers\Winston\QuadTank\QuadTank.xlsx[LFNStd]
    Tank4Volume: number<0.0 .. 8835.73>,
    # VP Link analog tag (0.0,100.0), EU=%; Target setpoint for Tank 1
    Tank1_SP: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), EU=%; Target setpoint for Tank 1
    Tank2_SP: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), EU=%; Valve opening from Pump #1 to Tank #1
    Gamma1: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), EU=%; Valve opening from Pump #2 to Tank #2  In QT5, This value is calculated as GammaSum - Gamma1
    Gamma2: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,200.0), EU=%; Sum of the percentages of Gamma1 and Gamma2 (note max is 200)
    GammaSum: number<0.0 .. 200.0>,
}

simulator Simulator(action: SimAction, config: SimConfig): SimState {
    # Automatically launch the simulator with this registered package name.
    # Comment out to manually pick an unregsitered simulator
    #   Useful for testing....
    package "<YourSimHere>"  # TODO: use your Brain name here
}

# Define a concept graph
graph (input: SimState): SimAction {

  output concept Concept1(input): SimAction {
    curriculum {
     # The source of training for this concept is a simulator
        # that takes an action as an input and outputs a state.
        source Simulator

      goal (s: SimState)
      {
        # Get within 0.5% of the target
        drive LevelSP1: s.Tank1Volume[0]/TankVolumeToPercent in Goal.Sphere(s.Tank1_SP, 0.5)
        drive LevelSP2: s.Tank2Volume[0]/TankVolumeToPercent in Goal.Sphere(s.Tank2_SP, 0.5)
      }
      training {
        EpisodeIterationLimit: 20, # Brain has 30 "_reportEvery" time steps to make this work
        NoProgressIterationLimit : 1000000
      }
      lesson EasyGammaSettings
      {
        # Scenarios set the values in the SimConfig to drive the starting state
        scenario
        {
          # configNumber: < 1, 2, 3, >
          _configNumber: 0,
          # For the _initialConditions, QuadTank_v4.icf sets up the model to use Gamma1 and Gamma2
          # For the _initialConditions, QuadTank_v5.icf sets up the model to use GammaSum and Gamma1
          _initialConditions: "QuadTank_v5.icf",
          _timeStep: 10,  # VP Link model takes 10 second time steps...
          _reportEvery: 30,  # but reports to Bonsai after 30 seconds of sim time has elapsed.
	        Tank1Volume: number <0.1*TankVolume..0.9*TankVolume step 0.02*TankVolume>,  # BRAIN needs to see all sorts of starting levels...
	        Tank2Volume: number <0.1*TankVolume..0.9*TankVolume step 0.02*TankVolume>,  # ...in both tanks.
	        Tank3Volume: number <0.1*TankVolume..0.9*TankVolume step 0.02*TankVolume>,  # BRAIN needs to see all sorts of starting levels...
	        Tank4Volume: number <0.1*TankVolume..0.9*TankVolume step 0.02*TankVolume>,  # ...in these tanks, too.
	        Tank1_SP:    number <10..80 step 1>,  # BRAIN needs to see all sorts of target setpoints...
	        Tank2_SP:    number <10..80 step 1>,  # ...in both tanks.
	        GammaSum: 150,
	        Gamma1: 75,   # This sets Gamma1 and Gamma2 to 75% each
				}
			}
		}
	}
}

