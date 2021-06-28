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

const TankVolume = 8835.73
const TankVolumeToPercent = TankVolume/100

## Define a type that represents the per-iteration state
# returned by the simulator.
type SimState {
    # Volume of Tank1 in cm3. The trem [2] defined below signified that last three historized
    # values will be used in the exponential function to train the brain.
    Tank1Volume: number<0.0 .. 8835.73>[2],
    # Volume of Tank2 in cm3. The trem [2] defined below signified that last three historized
    # values will be used in the exponential function to train the brain.
    Tank2Volume: number<0.0 .. 8835.73>[2],
    # Volume of Tank3 in cm3
    Tank3Volume: number<0.0 .. 8835.73>,
    # Volume of Tank4 in cm3
    Tank4Volume: number<0.0 .. 8835.73>,
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
    #  Volume of Tank1 in cm3
    Tank1Volume: number<0.0 .. 8835.73>,
    #  Volume of Tank2 in cm3
    Tank2Volume: number<0.0 .. 8835.73>,
    #  Volume of Tank3 in cm3
    Tank3Volume: number<0.0 .. 8835.73>,
    #  Volume of Tank4 in cm3
    Tank4Volume: number<0.0 .. 8835.73>,
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

simulator Simulator(action: SimAction, config: SimConfig): SimState {
    # Automatically launch the simulator with this
    # registered package name.
    package "<YourSimHere>" # TODO: use your Brain name here
}

# An Exponential Reward Function with landing zone is being used to train the Bonsai Brain.
# The reward gained by the brain will exponentially ,if the brain is able to maintain the
# difference between Level Controller setpoint and the actual level (process variable = PV)
# in the tanks to a minimum value (ideal value of difference = 0).

function RewardFunction( s: SimState)
{
    var Tank1reward: number
    var Tank2reward: number
    var adjFactor: number
    var Tank1error: number 
    var Tank2error: number 
    var Tank1diff: number 
    var Tank2diff: number 
    Tank1diff=Math.Abs(s.Tank1Volume[0]/TankVolumeToPercent) - s.Tank1_SP
    Tank2diff=Math.Abs(s.Tank2Volume[0]/TankVolumeToPercent) - s.Tank2_SP
    adjFactor=15
    # Exponential reward function
    Tank1error=Math.Abs((Tank1diff/adjFactor)**2)
    Tank2error=Math.Abs((Tank2diff/adjFactor)**2)
    Tank1reward=Math.E**(-Tank1error)
    Tank2reward=Math.E**(-Tank2error)
    # create 'landing zone' of +- 0.5% around the setpoint
    #set landing zone to be worth 10 times max reward function
    if (Math.Abs(Tank1diff) < 0.5) 
    {
    Tank1reward=10
    }
    if (Math.Abs(Tank2diff) < 0.5) 
    {
    Tank2reward=10
    }    
   #normalise so value lies between 0 and 1
    return ((Tank1reward + Tank2reward) / 20)
}

# Define a concept graph
graph (input: SimState): SimAction {
    concept BasicConcept(input): SimAction {
        curriculum {
            # The source of training for this concept is a simulator
            # that takes an action as an input and outputs a state.
            source Simulator
            reward RewardFunction
            training {
                EpisodeIterationLimit : 30,
                NoProgressIterationLimit : 1000000
            }
            lesson StartFromRandomLevel
            {
                #Scenarios set the values in the SimCOnfig to drive the starting state
                scenario 
                {
                    _configNumber: 0,
					_initialConditions: "",
					_timeStep: 10,
					_reportEvery: 30,
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

            
        
