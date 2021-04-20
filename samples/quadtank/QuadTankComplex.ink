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
    Tank1_SP: number<0.0 .. 100>,
    # VP Link analog tag (0.0,100.0), EU=%; Target setpoint for Tank 1
    Tank2_SP: number<0.0 .. 100>,
    Gamma1: number<0.0 .. 100>,
    Gamma2: number<0.0 .. 100>,
}

type SimAction {
    # VP Link analog tag (0.0,100.0), EU=%; Percentage of maximum speed of pump #1
    Pump1Speed: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), EU=%; Percentage of maximum speed of pump #2
    Pump2Speed: number<0.0 .. 100.0>,
}

type SimConfig {
    # VP Link configuration (deprecated)
    _configNumber: number,
    # Name of VP Link .icf file to load at start of episode. Available files are ['QuadTank_v4.icf', 'QuadTank_v5.icf']
    _initialConditions: string,
    # VP Link timestep (secs)
    _timeStep: number,
    # Bonsai timestep (secs)
    _reportEvery: number,
    # VP Link analog tag (0.0,8835.73), Level Tag at press =14.7; lfngen:\otherusers\Winston\QuadTank\QuadTank.xlsx[LFNStd]
    Tank1Volume: number<0.0 .. TankVolume>,
    # VP Link analog tag (0.0,8835.73), Level Tag at press =14.7; lfngen:\otherusers\Winston\QuadTank\QuadTank.xlsx[LFNStd]
    Tank2Volume: number<0.0 .. TankVolume>,
    # VP Link analog tag (0.0,8835.73), Level Tag at press =14.7; lfngen:\otherusers\Winston\QuadTank\QuadTank.xlsx[LFNStd]
    Tank3Volume: number<0.0 .. TankVolume>,
    # VP Link analog tag (0.0,8835.73), EU=cm3; Level Tag at press =14.7; lfngen:\otherusers\Winston\QuadTank\QuadTank.xlsx[LFNStd]
    Tank4Volume: number<0.0 .. TankVolume>,
    # VP Link analog tag (0.0,100.0), EU=%; Target setpoint for Tank 1
    Tank1_SP: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), EU=%; Target setpoint for Tank 1
    Tank2_SP: number<0.0 .. 100.0>,
    GammaSum: number <0.0 .. 200>,
    Gamma1: number<0.0 .. 100.0>,
    Gamma2: number<0.0 .. 100.0>,
}

# Make an Observable SimState a little smaller
type ObservableState {
    # VP Link analog tag (0.0,8835.73), Level Tag at press =14.7; lfngen:\otherusers\Winston\QuadTank\QuadTank.xlsx[LFNStd]
    Tank1Volume: number<0.0 .. TankVolume>[2],
    # VP Link analog tag (0.0,8835.73), Level Tag at press =14.7; lfngen:\otherusers\Winston\QuadTank\QuadTank.xlsx[LFNStd]
    Tank2Volume: number<0.0 .. TankVolume>[2],
    # VP Link analog tag (0.0,8835.73), Level Tag at press =14.7; lfngen:\otherusers\Winston\QuadTank\QuadTank.xlsx[LFNStd]
    Tank3Volume: number<0.0 .. TankVolume>,
    # VP Link analog tag (0.0,8835.73), EU=cm3; Level Tag at press =14.7; lfngen:\otherusers\Winston\QuadTank\QuadTank.xlsx[LFNStd]
    Tank4Volume: number<0.0 .. TankVolume>,
    # VP Link analog tag (0.0,100.0), EU=%; Target setpoint for Tank 1
    Tank1_SP: number<0.0 .. 100>,
    # VP Link analog tag (0.0,100.0), EU=%; Target setpoint for Tank 1
    Tank2_SP: number<0.0 .. 100>,
    # Gamma1: number,
    # Gamma2: number,
}

simulator Simulator(action: SimAction, config: SimConfig): SimState {
    # Automatically launch the simulator with this registered package name.
    # Comment out to manually pick an unregsitered simulator
    #   Useful for testing....
    package "<YourSimHere>"   # TODO: use your Brain name here
}

function DistanceReward( s: SimState)
{
    var tank1Reward: number
    var tank2Reward: number
    var tank1Error: number
    var tank2Error: number
    var tank1PrecisionReward: number
    var tank2PrecisionReward: number
    var halfdiff: number  = 5
    var precisionRewardFactor = 2
    tank1Error = Math.Abs(s.Tank1_SP-s.Tank1Volume[0])
    tank2Error = Math.Abs(s.Tank2_SP-s.Tank2Volume[0])
    tank1Reward = Math.E**(-((tank1Error/halfdiff)**2))
    tank2Reward = Math.E**(-((tank2Error/halfdiff)**2))
    tank1PrecisionReward = 0
    tank2PrecisionReward = 0
    if ( tank1Error < halfdiff/2 )
    {
        tank1PrecisionReward = 1 - Math.Sqrt(tank1Error/(halfdiff/2))
    }
    if ( tank2Error < halfdiff/2 )
    {
        tank2PrecisionReward = 1 - Math.Sqrt(tank2Error/(halfdiff/2))
    }
  return tank1Reward + tank2Reward  + precisionRewardFactor*(tank1PrecisionReward + tank2PrecisionReward)
}

function LinearReward(s: SimState)
{
    var Normalizer = 25
    var tank1Error = Math.Abs(s.Tank1_SP-s.Tank1Volume[0])
    var tank2Error = Math.Abs(s.Tank2_SP-s.Tank2Volume[0])
    return (Normalizer -tank1Error - tank2Error)/Normalizer
}

function NormalizeState(s: SimState) : ObservableState
{
    # NOTE: Gamma1 and Gamma2 are NOT returned in this structure
    #  because sending extraneous inputs to the brain is wasteful.
    return {
        Tank1Volume: s.Tank1Volume,
        Tank2Volume: s.Tank2Volume,
        Tank3Volume: s.Tank3Volume,
        Tank4Volume: s.Tank4Volume,
        Tank1_SP: s.Tank1_SP,
        Tank2_SP: s.Tank2_SP,
        # Gamma1: s.Gamma1,
        # Gamma2: s.Gamma2,
    }
}
# Define a concept graph
    graph (input: SimState): SimAction {


    concept Normalized(input): ObservableState {
        programmed NormalizeState
    }

    # Note: as written, this concept ends up having to learn to deal with the entire range of setpoints. Could split into a HighLow and LowHigh...
    concept MoreThanOne(Normalized): SimAction {
        curriculum {
         # The source of training for this concept is a simulator
            # that takes an action as an input and outputs a state.
            source Simulator
            # reward DistanceReward

             goal (s: SimState)
			 {
                drive LevelSP1: s.Tank1Volume[0]/TankVolumeToPercent in Goal.Sphere(s.Tank1_SP, 0.5)
			 	drive LevelSP2: s.Tank2Volume[0]/TankVolumeToPercent in Goal.Sphere(s.Tank2_SP, 0.5)
			 	# avoid Overflow: s.Tank1Volume[0] in Goal.RangeAbove(TankVolume)
			 	# avoid TankEmpty: s.Tank1Volume[0] in Goal.RangeBelow(5)
			}
        training {
          EpisodeIterationLimit: 20, # Brain has 30 "_reportEvery" time steps to make this work
          NoProgressIterationLimit : 1000000  # 1e6
          # Set the next two entries if you are using a reward, comment out if using a Goal
          # An episode is considered "successful" if reward > this value.
          # LessonRewardThreshold: 85,
          # Move on to the next lesson, once this fraction of assessment episodes is "successful"
          # LessonSuccessThreshold: 0.8,
      }

      lesson GammaSum140
			{
				# Scenarios set the values in the SimConfig to drive the starting state
				scenario
				{
					# configNumber: < 1, 2, 3, >
					_configNumber: 0,
					_initialConditions: "QuadTank_v5.icf",
					_timeStep: 10,
					_reportEvery: 30,
          Tank1Volume: number <0.1*TankVolume..0.9*TankVolume step 0.02*TankVolume>,  # BRAIN needs to see all sorts of starting levels...
          Tank2Volume: number <0.1*TankVolume..0.9*TankVolume step 0.02*TankVolume>,  # ...in both tanks.
          Tank3Volume: number <0.1*TankVolume..0.9*TankVolume step 0.02*TankVolume>,  # BRAIN needs to see all sorts of starting levels...
          Tank4Volume: number <0.1*TankVolume..0.9*TankVolume step 0.02*TankVolume>,  # ...in these tanks, too.
          Tank1_SP:    number <10..80 step 1>,  # BRAIN needs to see all sorts of target setpoints...
          Tank2_SP:    number <10..80 step 1>,  # ...in both tanks.
          GammaSum: 140,
          Gamma1: number <60 .. 80>,
          # Gamma2: GammaSum - Gamma1,  # done in the simulation with QuadTank_v5.icf
        }
      }

      lesson GammaSum110_160
			{
				# Scenarios set the values in the SimConfig to drive the starting state
				scenario
				{
					# configNumber: < 1, 2, 3, >
					_configNumber: 0,
					_initialConditions: "QuadTank_v5.icf",
					_timeStep: 10,
					_reportEvery: 30,
                    Tank1Volume: number <0.1*TankVolume..0.9*TankVolume step 0.02*TankVolume>,  # BRAIN needs to see all sorts of starting levels...
                    Tank2Volume: number <0.1*TankVolume..0.9*TankVolume step 0.02*TankVolume>,  # ...in both tanks.
                    Tank3Volume: number <0.1*TankVolume..0.9*TankVolume step 0.02*TankVolume>,  # BRAIN needs to see all sorts of starting levels...
                    Tank4Volume: number <0.1*TankVolume..0.9*TankVolume step 0.02*TankVolume>,  # ...in these tanks, too.
                    Tank1_SP:    number <10..80 step 1>,  # BRAIN needs to see all sorts of target setpoints...
                    Tank2_SP:    number <10..80 step 1>,  # ...in both tanks.
                    GammaSum: number <110 .. 160>,
                    Gamma1: number <60 .. 80>,
                    # Gamma2: GammaSum - Gamma1,
				}
            }

        }
    }
    concept LessThanOne(Normalized): SimAction {
        curriculum {
         # The source of training for this concept is a simulator
            # that takes an action as an input and outputs a state.
            source Simulator
            # reward DistanceReward

             goal (s: SimState)
			 {
                drive LevelSP1: s.Tank1Volume[0]/TankVolumeToPercent in Goal.Sphere(s.Tank1_SP, 0.5)
			 	drive LevelSP2: s.Tank2Volume[0]/TankVolumeToPercent in Goal.Sphere(s.Tank2_SP, 0.5)
			 	# avoid Overflow: s.Tank1Volume[0] in Goal.RangeAbove(100)
			 	# avoid TankEmpty: s.Tank1Volume[0] in Goal.RangeBelow(5)
			 }
            training {
                EpisodeIterationLimit: 20, # Brain has 30 "_reportEvery" time steps to make this work
                NoProgressIterationLimit : 1000000
                # Set the next two entries if you are using a reward, comment out if using a Goal
                # An episode is considered "successful" if reward > this value.
                # LessonRewardThreshold: 85,
                # Move on to the next lesson, once this fraction of assessment episodes is "successful"
                # LessonSuccessThreshold: 0.8,
            }

            lesson GammaSum60_70
            {
                scenario
				{
					# configNumber: < 1, 2, 3, >
					_configNumber: 0,
					_initialConditions: "QuadTank_v5.icf",
					_timeStep: 10,
					_reportEvery: 30,
                    Tank1Volume: number <0.1*TankVolume..0.9*TankVolume step 0.02*TankVolume>,  # BRAIN needs to see all sorts of starting levels...
                    Tank2Volume: number <0.1*TankVolume..0.9*TankVolume step 0.02*TankVolume>,  # ...in both tanks.
                    Tank3Volume: number <0.1*TankVolume..0.9*TankVolume step 0.02*TankVolume>,  # BRAIN needs to see all sorts of starting levels...
                    Tank4Volume: number <0.1*TankVolume..0.9*TankVolume step 0.02*TankVolume>,  # ...in these tanks, too.
                    Tank1_SP:    number <10..80 step 1>,  # BRAIN needs to see all sorts of target setpoints...
                    Tank2_SP:    number <10..80 step 1>,  # ...in both tanks.
                    GammaSum: number <60 .. 70>,
                    Gamma1: number <30 .. 40>,
                    # Gamma2: 0.4,
				}
            }

            lesson GammaSum60_99
            {
                scenario
				{
					# configNumber: < 1, 2, 3, >
					_configNumber: 0,
					_initialConditions: "QuadTank_v5.icf",
					_timeStep: 10,
					_reportEvery: 30,
                    Tank1Volume: number <0.1*TankVolume..0.9*TankVolume step 0.02*TankVolume>,  # BRAIN needs to see all sorts of starting levels...
                    Tank2Volume: number <0.1*TankVolume..0.9*TankVolume step 0.02*TankVolume>,  # ...in both tanks.
                    Tank3Volume: number <0.1*TankVolume..0.9*TankVolume step 0.02*TankVolume>,  # BRAIN needs to see all sorts of starting levels...
                    Tank4Volume: number <0.1*TankVolume..0.9*TankVolume step 0.02*TankVolume>,  # ...in these tanks, too.
                    Tank1_SP:    number <10..80 step 1>,  # BRAIN needs to see all sorts of target setpoints...
                    Tank2_SP:    number <10..80 step 1>,  # ...in both tanks.
                    GammaSum: number <60 .. 99>,
                    Gamma1: number <20 .. 50>,
                    # Gamma2: 0.4,
				}
            }
            lesson GammaSum40_99
			{
				# Scenarios set the values in the SimConfig to drive the starting state
				scenario
				{
					# configNumber: < 1, 2, 3, >
					_configNumber: 0,
					_initialConditions: "QuadTank_v5.icf",
					_timeStep: 10,
					_reportEvery: 30,
                    Tank1Volume: number <0.1*TankVolume..0.9*TankVolume step 0.02*TankVolume>,  # BRAIN needs to see all sorts of starting levels...
                    Tank2Volume: number <0.1*TankVolume..0.9*TankVolume step 0.02*TankVolume>,  # ...in both tanks.
                    Tank3Volume: number <0.1*TankVolume..0.9*TankVolume step 0.02*TankVolume>,  # BRAIN needs to see all sorts of starting levels...
                    Tank4Volume: number <0.1*TankVolume..0.9*TankVolume step 0.02*TankVolume>,  # ...in these tanks, too.
                    Tank1_SP:    number <10..80 step 1>,  # BRAIN needs to see all sorts of target setpoints...
                    Tank2_SP:    number <10..80 step 1>,  # ...in both tanks.
                    GammaSum: number <40 .. 99>,
                    Gamma1: number <20 .. 50>,  # WDJHUH Note that 0.5 - 0.7 leads to a weird situation, which is just Gamma2 = 0
                    # Gamma2: 0.4,
                }
            }
        }
    }

    output concept chooseMode(input, LessThanOne, MoreThanOne) : SimAction
    {
        programmed function chooseSomething(state: SimState, ltOne: SimAction, gtOne: SimAction)
        {
          if state.Gamma1 + state.Gamma2 < 1
          {
            return ltOne
          } else
          {
            return gtOne
          }
        }
    }
}
