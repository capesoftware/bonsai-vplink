###

# Quad Tank Tutorial

# The Quand Tank model is simulated in the process simulator VP Link which is developed by Wood Plc.

# This example demonstrates how to teach a policy for controlling liquid levels in two tanks by 
# varrying the speed of two pumps supplying liquid to each of the tank. However, the two level 
# controllers interact with each other because some of fluid pumped by each pump flows to the
# other tank. The flow going to the other tank is further delayed in time by passing through the
# third and fourth tanks.

# To understand this Inkling better, please refer the detailled explanation of the problem statement:
#

###

inkling "2.0"
using Math
using Goal
using Number

const TankVolumePercent = 100

## Define a type that represents the per-iteration state
# returned by the simulator.
type SimState {
    # Volume of Tank1 in %. The trem [4] defined below signified that last four historized
    # values will be used in the exponential function to train the brain.
    Tank1_PV: number<0.0 .. 100.00>[4],
    # Volume of Tank2 in %. The trem [4] defined below signified that last four historized
    # values will be used in the exponential function to train the brain.
    Tank2_PV: number<0.0 .. 100.00>[4],
    # Volume of Tank3 in %
    Tank3_PV: number<0.0 .. 100.00>,
    # Volume of Tank4 in %
    Tank4_PV: number<0.0 .. 100.00>,
    # Set Point to Tank1 Level Controller in %
    Tank1_SP: number<0.0 .. 100.0>,
    # Set Point to Tank2 Level Controller in %
    Tank2_SP: number<0.0 .. 100.0>,
    # Valve Opening of valve Gamma1 in %
    Gamma1: number<0.0 .. 100.0>,
    # Valve Opening of valve Gamma2 in %. This value is calculated as GammaSum - Gamma1
    Gamma2: number<0.0 .. 100.0>,
    # Sum of the percentages of Gamma1 and Gamma2 (note max is 200)
    GammaSum: number<0.0 .. 200.0>,
}

type SimAction {
    # Speed of Pump1 in % (Percent of max speed)
    Pump1Speed: number<0.0 .. 100.0>,
    # Speed of Pump2 in % (Percent of max speed)
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
    #  Volume of Tank1 in %
    Tank1_PV: number<0.0 .. 100.00>,
    #  Volume of Tank2 in %
    Tank2_PV: number<0.0 .. 100.00>,
    #  Volume of Tank3 in %
    Tank3_PV: number<0.0 .. 100.00>,
    #  Volume of Tank4 in %
    Tank4_PV: number<0.0 .. 100.00>,
    # Set Point to Tank1 Level Controller in %
    Tank1_SP: number<0.0 .. 100.0>,
    # Set Point to Tank2 Level Controller in %
    Tank2_SP: number<0.0 .. 100.0>,
    # Valve Opening of valve Gamma1 in %
    Gamma1: number<0.0 .. 100.0>,
    # Valve Opening of valve Gamma2 in %. This value is calculated as GammaSum - Gamma1
    Gamma2: number<0.0 .. 100.0>,
    # Sum of the percentages of Gamma1 and Gamma2 (note max is 200)
    GammaSum: number<0.0 .. 200.0>,
}

# Make an Observable SimState a little smaller
type ObservableState {
    # Volume of Tank1 in %. The trem [4] defined below signified that last four historized
    # values will be used in the exponential function to train the brain.
    Tank1_PV: number<0.0 .. 100.00>[4],
    # Volume of Tank2 in %. The trem [4] defined below signified that last four historized
    # values will be used in the exponential function to train the brain.
    Tank2_PV: number<0.0 .. 100.00>[4],
    # Volume of Tank3 in %
    Tank3_PV: number<0.0 .. 100.00>,
    # Volume of Tank4 in %
    Tank4_PV: number<0.0 .. 100.00>,
    # Set Point to Tank1 Level Controller in %
    Tank1_SP: number<0.0 .. 100.0>,
    # Set Point to Tank2 Level Controller in %
    Tank2_SP: number<0.0 .. 100.0>,
    # Valve Opening of valve Gamma1 in %
    #Gamma1: number<0.0 .. 100.0>,
    # Valve Opening of valve Gamma2 in %. This value is calculated as GammaSum - Gamma1
    #Gamma2: number<0.0 .. 100.0>,
    # Sum of the percentages of Gamma1 and Gamma2 (note max is 200)
    #GammaSum: number<0.0 .. 200.0>, 
  }

simulator Simulator(action: SimAction, config: SimConfig): SimState {
    # Automatically launch the simulator with this
    # registered package name.
    package "ST_QTRev2"
}

# An Exponential Reward Function with landing zone is being used to train the Bonsai Brain.
# The reward gained by the brain will exponentially ,if the brain is able to maintain the
# difference between Level Controller setpoint and the actual level (process variable = PV)
# in the tanks to a minimum value (ideal value of difference = 0).

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
    tank1Error = Math.Abs(s.Tank1_SP-s.Tank1_PV[0])
    tank2Error = Math.Abs(s.Tank2_SP-s.Tank2_PV[0])
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
    var tank1Error = Math.Abs(s.Tank1_SP-s.Tank1_PV[0])
    var tank2Error = Math.Abs(s.Tank2_SP-s.Tank2_PV[0])
    return (Normalizer -tank1Error - tank2Error)/Normalizer
}

function NormalizeState(s: SimState) : ObservableState
{
    # NOTE: Gamma1 and Gamma2 are NOT returned in this structure
    #  because sending extraneous inputs to the brain is wasteful.
    return {
        Tank1_PV: s.Tank1_PV,
        Tank2_PV: s.Tank2_PV,
        Tank3_PV: s.Tank3_PV,
        Tank4_PV: s.Tank4_PV,
        Tank1_SP: s.Tank1_SP,
        Tank2_SP: s.Tank2_SP,
        #Gamma1: s.Gamma1,
        #Gamma2: s.Gamma2,
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
                drive LevelSP1: s.Tank1_PV[0] in Goal.Sphere(s.Tank1_SP, 0.5)
			 	drive LevelSP2: s.Tank2_PV[0] in Goal.Sphere(s.Tank2_SP, 0.5)
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
                    Tank1_PV: number <0.1*TankVolumePercent..0.9*TankVolumePercent step 0.02*TankVolumePercent>,  # BRAIN needs to see all sorts of starting levels...
	                Tank2_PV: number <0.1*TankVolumePercent..0.9*TankVolumePercent step 0.02*TankVolumePercent>,  # ...in both tanks.
	                Tank3_PV: number <0.1*TankVolumePercent..0.9*TankVolumePercent step 0.02*TankVolumePercent>,  # BRAIN needs to see all sorts of starting levels...
	                Tank4_PV: number <0.1*TankVolumePercent..0.9*TankVolumePercent step 0.02*TankVolumePercent>,  # ...in these tanks, too.
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
                    Tank1_PV: number <0.1*TankVolumePercent..0.9*TankVolumePercent step 0.02*TankVolumePercent>,  # BRAIN needs to see all sorts of starting levels...
	                Tank2_PV: number <0.1*TankVolumePercent..0.9*TankVolumePercent step 0.02*TankVolumePercent>,  # ...in both tanks.
	                Tank3_PV: number <0.1*TankVolumePercent..0.9*TankVolumePercent step 0.02*TankVolumePercent>,  # BRAIN needs to see all sorts of starting levels...
	                Tank4_PV: number <0.1*TankVolumePercent..0.9*TankVolumePercent step 0.02*TankVolumePercent>,  # ...in these tanks, too.
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
                drive LevelSP1: s.Tank1_PV[0] in Goal.Sphere(s.Tank1_SP, 0.5)
			 	drive LevelSP2: s.Tank2_PV[0] in Goal.Sphere(s.Tank2_SP, 0.5)
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
                    Tank1_PV: number <0.1*TankVolumePercent..0.9*TankVolumePercent step 0.02*TankVolumePercent>,  # BRAIN needs to see all sorts of starting levels...
	                Tank2_PV: number <0.1*TankVolumePercent..0.9*TankVolumePercent step 0.02*TankVolumePercent>,  # ...in both tanks.
	                Tank3_PV: number <0.1*TankVolumePercent..0.9*TankVolumePercent step 0.02*TankVolumePercent>,  # BRAIN needs to see all sorts of starting levels...
	                Tank4_PV: number <0.1*TankVolumePercent..0.9*TankVolumePercent step 0.02*TankVolumePercent>,  # ...in these tanks, too.
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
                    Tank1_PV: number <0.1*TankVolumePercent..0.9*TankVolumePercent step 0.02*TankVolumePercent>,  # BRAIN needs to see all sorts of starting levels...
	                Tank2_PV: number <0.1*TankVolumePercent..0.9*TankVolumePercent step 0.02*TankVolumePercent>,  # ...in both tanks.
	                Tank3_PV: number <0.1*TankVolumePercent..0.9*TankVolumePercent step 0.02*TankVolumePercent>,  # BRAIN needs to see all sorts of starting levels...
	                Tank4_PV: number <0.1*TankVolumePercent..0.9*TankVolumePercent step 0.02*TankVolumePercent>,  # ...in these tanks, too.
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
                    Tank1_PV: number <0.1*TankVolumePercent..0.9*TankVolumePercent step 0.02*TankVolumePercent>,  # BRAIN needs to see all sorts of starting levels...
	                Tank2_PV: number <0.1*TankVolumePercent..0.9*TankVolumePercent step 0.02*TankVolumePercent>,  # ...in both tanks.
	                Tank3_PV: number <0.1*TankVolumePercent..0.9*TankVolumePercent step 0.02*TankVolumePercent>,  # BRAIN needs to see all sorts of starting levels...
	                Tank4_PV: number <0.1*TankVolumePercent..0.9*TankVolumePercent step 0.02*TankVolumePercent>,  # ...in these tanks, too.
                    Tank1_SP:    number <10..80 step 1>,  # BRAIN needs to see all sorts of target setpoints...
                    Tank2_SP:    number <10..80 step 1>,  # ...in both tanks.
                    GammaSum: number <40 .. 99>,
                    Gamma1: number <20 .. 50>,  # Note that 0.5 - 0.7 leads to a weird situation, which is just Gamma2 = 0
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