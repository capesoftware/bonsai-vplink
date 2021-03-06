# Sample Inkling for VP Link Enzyme Reactor demonstration

# Overview
# Use a VP Link model to teach a Bonsai brain to startup and control
# a continuous enzyme reactor

# More details about the model are available at
# https://github.com/capesoftware/bonsai-vplink/tree/main/samples/enzymereactor

inkling "2.0"
using Goal
using Math
using Number

# Define a type that represents the per-iteration state
# returned by the simulator.
type SimState {
    # VP Link analog tag (0.0,100.0), EU=kg/min; Production rate of Microbes
    Enzyme_Prod_Rate: number<0.0 .. 100.0>[3],
    # VP Link analog tag (0.0,2000.0), Level Tag at press =1.4; lfngen:\otherusers\winston\MicrobeReactor\MicrobeReactorDD.xls[lfnWDJ]
    LvlFermenter: number<0.0 .. 2000.0>[3],
    # VP Link digital tag (--,ContinuousMode), 
    Continuous_Mode: number<0 .. 1>,
    # VP Link digital tag (--,PastStartup), 
    Past_Startup_Mode: number<0 .. 1>,
    # VP Link digital tag (--,ReactorStartup), 
    Reactor_Startup_Mode: number<0 .. 1>,
    # VP Link digital tag (--,ContinuousMode), 
    Continuous_Mode_Button: number<0 .. 1>,
    # VP Link digital tag (--,PastStartup), 
    Past_Startup_Mode_Button: number<0 .. 1>,
    # VP Link digital tag (--,ReactorStartup), 
    Reactor_Startup_Mode_Button: number<0 .. 1>,
    # VP Link analog tag (0.0,5000.0), EU=kg; Amount of live Microbes (healthy and unhealthy) in the reactor
    Microbes: number<0.0 .. 5000.0>,
    # VP Link analog tag (0.0,2000.0), EU=kg; The amount of food in the reactor
    Food: number<0.0 .. 2000.0>,
    # VP Link analog tag (0.0,10.0), EU=l/min; Rate of Acid addition
    Acid_Flow: number<0.0 .. 10.0>,
    # VP Link analog tag (0.0,50.0), EU=%; What is the dissolved Oxygen concentration? Target is 17.5%
    Reactor_O2: number<0.0 .. 50.0>[3],
    # VP Link analog tag (0.0,10.0), 
    Base_Flow: number<0.0 .. 10.0>,
    Reactor_Temp: number<0.0 .. 212.0>[3],
    # VP Link analog tag (0.0,14.0), EU=pH; What is pH of the reactor
    Reactor_pH: number<0.0 .. 14.0>[3],
    # VP Link analog tag (0.0,300.0), Eu=°F;
    Temp_E002_FoodIn: number<0.0 .. 300.0>[3],
    # VP Link analog tag (0.0,300.0), Eu=°F;
    Temp_E003_FoodIn: number<0.0 .. 300.0>[3],
    # VP Link analog tag (0.0,300.0), Eu=°F;
    Temp_PastLoop_In: number<0.0 .. 300.0>[3],
    # VP Link analog tag (0.0,300.0), Eu=°F;
    Temp_PastLoop_OUT: number<0.0 .. 300.0>[3],
    # VP Link analog tag (0.0,300.0), Eu=°F;
    Temp_ReactorFood_In: number<0.0 .. 300.0>[3],
}

#define a type that returns the per-iteration Actions sent to the simulator
type SimAction {
    # VP Link analog tag (0.0,2000.0), EU=l; Setpoint for Level in the Fermenter (normally 300)
    Reactor_Level_Setpoint_C: number<300.0 .. 1800.0>,
    # VP Link analog tag (0.0,2000.0), EU=l; Setpoint for Level in the Fermenter (normally 300)
    Reactor_Level_Setpoint_St: number<1100.0 .. 1250.0>,
    # VP Link analog tag (0.0,200.0), Eu=°F;
    PastLoop_TempSetpoint: number<160.0 .. 185.0>,
    # VP Link analog tag (0.0,200.0), Eu=°F;
    ReactorFoodInlet_PastLoop_TempSetpoint: number<0.0 .. 200.0>,
    # VP Link analog tag (0.0,100.0), Eu=%;
    Acid_Flow_Vlv: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), Eu=%;
    Base_Flow_Vlv: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), 
    Air_Blower_Speed: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,130.0), EU=l/min;
    FlowSetPoint_C: number<0.0 .. 130.0>,
    # VP Link analog tag (10.0,15.0), EU=l/min;
    FlowSetPoint_St: number<10.0 .. 15.0>,
}

#define a type that is the Simulation configuration
type SimConfig {
    # VP Link configuration (deprecated); Built from CreateBonsaiInterface v0.9.1
    _configNumber: number,
    # Name of VP Link .icf file to load at start of episode. Available files are []
    _initialConditions: string,
    # VP Link timestep (secs)
    _timeStep: number,
    # Bonsai timestep (secs)
    _reportEvery: number,
    # VP Link analog tag (0.0,100.0), EU=kg/min; Production rate of Microbes
    Enzyme_Prod_Rate: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,2000.0), Level Tag at press =1.4; lfngen:\otherusers\winston\MicrobeReactor\MicrobeReactorDD.xls[lfnWDJ]
    LvlFermenter: number<0.0 .. 2000.0>,
    # VP Link digital tag (--,ContinuousMode), 
    Continuous_Mode: number<0 .. 1>,
    # VP Link digital tag (--,PastStartup), 
    Past_Startup_Mode: number<0 .. 1>,
    # VP Link digital tag (--,ReactorStartup), 
    Reactor_Startup_Mode: number<0 .. 1>,
    # VP Link digital tag (--,ContinuousMode), 
    Continuous_Mode_Button: number<0 .. 1>,
    # VP Link digital tag (--,PastStartup), 
    Past_Startup_Mode_Button: number<0 .. 1>,
    # VP Link digital tag (--,ReactorStartup), 
    Reactor_Startup_Mode_Button: number<0 .. 1>,
    # VP Link analog tag (0.0,5000.0), EU=kg; Amount of live Microbes (healthy and unhealthy) in the reactor
    Microbes: number<0.0 .. 5000.0>,
    # VP Link analog tag (0.0,2000.0), EU=kg; The amount of food in the reactor
    Food: number<0.0 .. 2000.0>,
    # VP Link analog tag (0.0,10.0), EU=l/min; Rate of Acid addition
    Acid_Flow: number<0.0 .. 10.0>,
    # VP Link analog tag (0.0,50.0), EU=%; What is the dissolved Oxygen concentration? Target is 17.5%
    Reactor_O2: number<0.0 .. 50.0>,
    # VP Link analog tag (0.0,10.0), 
    Base_Flow: number<0.0 .. 10.0>,
    # VP Link analog tag (0.0,212.0), EU=degF; What is Temperature of the reactor
    Reactor_Temp: number<0.0 .. 212.0>,
    # VP Link analog tag (0.0,14.0), EU=pH; What is pH of the reactor
    Reactor_pH: number<0.0 .. 14.0>,
    # VP Link analog tag (0.0,300.0), Eu=°F;
    Temp_E002_FoodIn: number<0.0 .. 300.0>,
    # VP Link analog tag (0.0,300.0), Eu=°F;
    Temp_E003_FoodIn: number<0.0 .. 300.0>,
    # VP Link analog tag (0.0,300.0), Eu=°F;
    Temp_PastLoop_In: number<0.0 .. 300.0>,
    # VP Link analog tag (0.0,300.0), Eu=°F;
    Temp_PastLoop_OUT: number<0.0 .. 300.0>,
    # VP Link analog tag (0.0,300.0), Eu=°F;
    Temp_ReactorFood_In: number<0.0 .. 300.0>,
}

#define narrowed Action Space for Reactor Startup process conditions
# (see github repository for detail on different process modes)
type ReactorStartupAction {
    # VP Link analog tag (0.0,2000.0), EU=l; Setpoint for Level in the Fermenter (normally 300)
    Reactor_Level_Setpoint_St: number<1100.0 .. 1250.0>,
    # VP Link analog tag (0.0,200.0), Eu=°F;
    ReactorFoodInlet_PastLoop_TempSetpoint: number<0.0 .. 200.0>,
    # VP Link analog tag (0.0,100.0), Eu=%;
    Acid_Flow_Vlv: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), Eu=%;
    Base_Flow_Vlv: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), 
    Air_Blower_Speed: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,130.0), EU=l/min;
    FlowSetPoint_St: number<10.0 .. 15.0>,
}

#define the narrowed Action space for the Continuous mode conditions
# (see github repository for detail on different process modes)
type ContinuousAction {
    # VP Link analog tag (0.0,2000.0), EU=l; Setpoint for Level in the Fermenter (normally 300)
    Reactor_Level_Setpoint_C: number<300.0 .. 1800.0>,
    # VP Link analog tag (0.0,200.0), Eu=°F;
    ReactorFoodInlet_PastLoop_TempSetpoint: number<0.0 .. 200.0>,
    # VP Link analog tag (0.0,100.0), Eu=%;
    Acid_Flow_Vlv: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), Eu=%;
    Base_Flow_Vlv: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,100.0), 
    Air_Blower_Speed: number<0.0 .. 100.0>,
    # VP Link analog tag (0.0,130.0), EU=l/min;
    FlowSetPoint_C: number<0.0 .. 130.0>,
}

#define the narrowed Action space for the Pasteurisation mode conditions
# (see github repository for detail on different process modes)
type SterilisationAction {
    PastLoop_TempSetpoint: number<160.0 .. 185.0>
}

#define the narrowed state space for Pastuerisation
type PasteurizeState {
    Past_Startup_Mode: number<0 .. 1>,
    # VP Link digital tag (--,ReactorStartup), 
    Temp_PastLoop_In: number<0.0 .. 300.0>[3],
    # VP Link analog tag (0.0,300.0), Eu=°F;
    Temp_PastLoop_OUT: number<0.0 .. 300.0>[3],
}
#This function will be used in the pasteurisation concept to reduce the overall state space
function ReducePasteurizeState(s: SimState) : PasteurizeState
{
    return {
        Past_Startup_Mode: s.Past_Startup_Mode,
        Temp_PastLoop_In: s.Temp_PastLoop_In,
        Temp_PastLoop_OUT: s.Temp_PastLoop_OUT
    }
}

#Define the reactor startup mode state space
type ReactorStartupState {
    # VP Link analog tag (0.0,2000.0), Level Tag at press =1.4; lfngen:\otherusers\winston\MicrobeReactor\MicrobeReactorDD.xls[lfnWDJ]
    LvlFermenter: number<0.0 .. 2000.0>[3],
    # VP Link digital tag (--,ReactorStartup), 
    Reactor_Startup_Mode: number<0 .. 1>,
    # VP Link analog tag (0.0,5000.0), EU=kg; Amount of live Microbes (healthy and unhealthy) in the reactor
    Microbes: number<0.0 .. 5000.0>,
    # VP Link analog tag (0.0,2000.0), EU=kg; The amount of food in the reactor
    Food: number<0.0 .. 2000.0>,
    # VP Link analog tag (0.0,10.0), EU=l/min; Rate of Acid addition
    Acid_Flow: number<0.0 .. 10.0>,
    # VP Link analog tag (0.0,50.0), EU=%; What is the dissolved Oxygen concentration? Target is 17.5%
    Reactor_O2: number<0.0 .. 50.0>[3],
    # VP Link analog tag (0.0,10.0), 
    Base_Flow: number<0.0 .. 10.0>,
    # VP Link analog tag (0.0,212.0), EU=degF; What is Temperature of the reactor
    Reactor_Temp: number<0.0 .. 212.0>[3],
    # VP Link analog tag (0.0,14.0), EU=pH; What is pH of the reactor
    Reactor_pH: number<0.0 .. 14.0>[3],
    # VP Link analog tag (0.0,300.0), Eu=°F;
    Temp_ReactorFood_In: number<0.0 .. 300.0>[3],
}
#function to be used in the reactor startup concept as the narrowed state space
function ReduceReactStartState(s: SimState) : ReactorStartupState
{
    return {
    LvlFermenter: s.LvlFermenter,
    Reactor_Startup_Mode: s.Reactor_Startup_Mode,
    Microbes: s.Microbes,
    Food: s.Food,
    Acid_Flow: s.Acid_Flow,
    Reactor_O2: s.Reactor_O2,
    Base_Flow: s.Base_Flow,
    Reactor_Temp: s.Reactor_Temp,
    Reactor_pH: s.Reactor_pH,
    Temp_ReactorFood_In: s.Temp_ReactorFood_In,
    }
}


#Define the Continuous state space
type ContinuousState {
    # VP Link analog tag (0.0,2000.0), Level Tag at press =1.4; lfngen:\otherusers\winston\MicrobeReactor\MicrobeReactorDD.xls[lfnWDJ]
    LvlFermenter: number<0.0 .. 2000.0>[3],
    # VP Link digital tag (--,Continuous_Mode), 
    Continuous_Mode: number<0 .. 1>,
    # VP Link analog tag (0.0,5000.0), EU=kg; Amount of live Microbes (healthy and unhealthy) in the reactor
    Microbes: number<0.0 .. 5000.0>,
    # VP Link analog tag (0.0,2000.0), EU=kg; The amount of food in the reactor
    Food: number<0.0 .. 2000.0>,
    # VP Link analog tag (0.0,10.0), EU=l/min; Rate of Acid addition
    Acid_Flow: number<0.0 .. 10.0>,
    # VP Link analog tag (0.0,50.0), EU=%; What is the dissolved Oxygen concentration? Target is 17.5%
    Reactor_O2: number<0.0 .. 50.0>[3],
    # VP Link analog tag (0.0,10.0), 
    Base_Flow: number<0.0 .. 10.0>,
    # VP Link analog tag (0.0,212.0), EU=degF; What is Temperature of the reactor
    Reactor_Temp: number<0.0 .. 212.0>[3],
    # VP Link analog tag (0.0,14.0), EU=pH; What is pH of the reactor
    Reactor_pH: number<0.0 .. 14.0>[3],
    # VP Link analog tag (0.0,300.0), Eu=°F;
    Temp_ReactorFood_In: number<0.0 .. 300.0>[3],
    # VP Link analog tag (0.0,100.0), EU=kg/min; Production rate of Microbes
    Enzyme_Prod_Rate: number<0.0 .. 100.0>[3],
}
#function to be used in the reactor startup concept as the narrowed state space
function ReduceContinuousState(s: SimState) : ContinuousState
{
    return {
    LvlFermenter: s.LvlFermenter,
    Continuous_Mode: s.Continuous_Mode,
    Microbes: s.Microbes,
    Food: s.Food,
    Acid_Flow: s.Acid_Flow,
    Reactor_O2: s.Reactor_O2,
    Base_Flow: s.Base_Flow,
    Reactor_Temp: s.Reactor_Temp,
    Reactor_pH: s.Reactor_pH,
    Temp_ReactorFood_In: s.Temp_ReactorFood_In,
    Enzyme_Prod_Rate: s.Enzyme_Prod_Rate
    }
}
#Define simulator
simulator Simulator(action: SimAction, config: SimConfig): SimState {
    # Automatically launch the simulator with this
    # registered package name.
    package "EnzymeReactorFinal_v2"
}

#Define simulator that uses the narrowed action space Pasteurisation
simulator SterilisationSimulator(action: SterilisationAction, config: SimConfig): SimState {
    # Automatically launch the simulator with this
    # registered package name.
    package "EnzymeReactorFinal_v2"
}

#Define simulator that uses the narrowed action space for Reactor Startup
simulator ReactorStartupSimulator(action: ReactorStartupAction, config: SimConfig): SimState {
    # Automatically launch the simulator with this
    # registered package name.
    package "EnzymeReactorFinal_v2"
}

#Define simulator that uses the narrowed action space for Continuous
simulator ContinuousSimulator(action: ContinuousAction, config: SimConfig): SimState {
    # Automatically launch the simulator with this
    # registered package name.
    package "EnzymeReactorFinal_v2"
}

#define a constant to use in the Pasteurisation function
const kTooHot = 180.0
const kTooCold = 169.0

#Pasteurisaiton reward function
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

# This statement turns the generic VP Link reward into one specific to the Pasteurisation
function PasteurReward( s: SimState)
{
    var good: number
    var bad: number
    good = VPLinkReward( 172.5, s.Temp_PastLoop_OUT[0], 2.5)
    bad = Math.Max(0, 10 * (s.Temp_PastLoop_OUT[0] - kTooHot))
    return good - bad
}

# reward for the reactor conditions during startup, based on available measurements pH, Temperature and Oxygen %
# This reward takes a different approach to the previous VP Link reward
# Exponenetal reward is defined that will vary from 0 to 1 depending on how close to the specified setpoint 
# the variable is. 
function StartupReactorReward( s: SimState)
{
#reward return variables  
    var pHreward: number
    var tempreward: number
    var O2reward: number
#pH variables    
    var pHhalf: number
    var pHExponent: number
    var pHTarget: number
    pHhalf = 0.5
    pHExponent = 2
    pHTarget = 7.5
#pH mathematical function. This will create a distribution around the target value that varies from 0 to 1
#The idea is bonsai will aim to maintain this process variable as close to 1 as it can
#adding a component related to the base valve opening will prevent bonsai from overusing expensive acid and base chemicals
    pHreward = (Math.E**(-(Math.Abs(s.Reactor_pH[0]-pHTarget)/pHhalf)*pHExponent))*(1-s.Base_Flow/20)
#Temperature variables    
    var temphalf: number
    var tempExponent: number
    var tempTarget: number
    temphalf = 4
    tempExponent = 2
    tempTarget = 98
#Temperature mathematical function. This will create a distribution around the target value that varies from 0 to 1
#The idea is bonsai will aim to maintain this process variable as close to 1 as it can
    tempreward = Math.E**(-(Math.Abs(s.Reactor_Temp[0]-tempTarget)/temphalf)*tempExponent)
#Oxygen variables    
    var O2half: number
    var O2Exponent: number
    var O2Target: number
    O2half = 4
    O2Exponent = 2
    O2Target = 17.5
#Oxygen mathematical function. This will create a distribution around the target value that varies from 0 to 1
#The idea is bonsai will aim to maintain this process variable as close to 1 as it can
    O2reward = Math.E**(-(Math.Abs(s.Reactor_O2[0]-O2Target)/O2half)*O2Exponent)
#Return functions times each other to ensure bonsai aims to keep all variables as close to 1 as possible
# this is analogous to how the Microbe health is calculated as described in github repository
    return (O2reward*tempreward*pHreward)
}


#Continuous reward function, this will be the same as the startup reward but factoring in enzyme production and 
# a factor that works with the reactor level
function ContinuousReward (s: SimState)
{
    #reward return variables  
    var pHreward: number
    var tempreward: number
    var O2reward: number
    var enzymereward: number
    var levelreward: number
    #pH variables    
    var pHhalf: number
    var pHExponent: number
    var pHTarget: number
    pHhalf = 0.5
    pHExponent = 2
    pHTarget = 7.5
    #pH function. This factors in Base flow. The idea is that the reward will be reduced if too much
    #base is used. This encourages Bonsai to learn an equilibrium where less acid and base 
    #chemicals are used
    pHreward = Math.E**(-(Math.Abs(s.Reactor_pH[0]-pHTarget)/pHhalf)*pHExponent)*(1-s.Base_Flow/20)
    #Temperature variables    
    var temphalf: number
    var tempExponent: number
    var tempTarget: number
    temphalf = 4
    tempExponent = 2
    tempTarget = 98
    #Temperature function
    tempreward = Math.E**(-(Math.Abs(s.Reactor_Temp[0]-tempTarget)/temphalf)*tempExponent)
    #Oxygen variables    
    var O2half: number
    var O2Exponent: number
    var O2Target: number
    O2half = 4
    O2Exponent = 2
    O2Target = 17.5
    #Oxygen function
    O2reward = Math.E**(-(Math.Abs(s.Reactor_O2[0]-O2Target)/O2half)*O2Exponent)
    #Enzyme variables    
    var Enzymehalf: number
    var EnzymeExponent: number
    var EnzymeTarget: number
    Enzymehalf = 10
    EnzymeExponent = 2
    EnzymeTarget = 30
    #Enzyme function
    enzymereward = Math.E**(-(Math.Abs(s.Enzyme_Prod_Rate[0]-EnzymeTarget)/Enzymehalf)*EnzymeExponent)
    # the following if statement will ensure that if the variable is above the target then the function retursn a 1
    # this allows bonsai to learn to reach the target but not to be punished or incentivise to go above it
    if (s.Enzyme_Prod_Rate[0] > EnzymeTarget) 
    {
        enzymereward = 1
    }
    #define the level aspect of the reward. This is intended to punish Bonsai if the tank level gets too low
    # as long as the level is above target it will remain at a value of 1 and thus not affect the output
    var Levelhalf: number
    var LevelExponent: number
    var LevelTarget: number
    Levelhalf = 200
    LevelExponent = 2
    LevelTarget = 900
    levelreward = Math.E**(-(Math.Abs(s.LvlFermenter[0]-LevelTarget)/Levelhalf)*LevelExponent)
    if (s.LvlFermenter[0] > LevelTarget)
    {
        levelreward = 1
    }
    #Return functions times each other- this is analogous to how the Microbe health is calculated
    # but factors in enzyme production rate and the level punishment
    return (O2reward*tempreward*pHreward*enzymereward*levelreward)
}

# Define a concept graph
graph (input: SimState): SimAction {
    #This is the narrowed Pasteurisation State
    concept StateForPasteurization(input): PasteurizeState {
        programmed ReducePasteurizeState
    }
    #This is the Pasteurisation Concept
    concept SterilisationStartup(StateForPasteurization): SterilisationAction {
        curriculum {
            # The source of training for this concept is a simulator
            # that takes an action as an input and outputs a state.
            source SterilisationSimulator
            reward PasteurReward
          #Define the Training setup
          training 
          {
                # Give the brain 20 minutes to get the pasteurization going.
                # That is 40 '_reportEvery' increments
                EpisodeIterationLimit: 60, # Brain has 60 "_reportEvery" time steps to make this work
                NoProgressIterationLimit : 550000 
          }
          #Define the Lessons
          #could we do more lessons other than just startup? Flow fluctuations
          lesson StartfromNoHeating {
            scenario 
            {
              _configNumber: 0,
              # Each episode will use the same starting conditions
              _timeStep: 2,  # VP Link model takes 2 second time steps (for the PIDs to work well)...
              _reportEvery: 30,  # but reports to Bonsai after 30 seconds of sim time has elapsed.
              # We do not need to set any other values, because they are all set in the initialConditions file, above
              _initialConditions: "PasteurizationStartup.icf"
              
            }
          }
          #This teaches Bonsai to deal with the flow fluctuations arising during Reactor Startup
          lesson ReactorStartup {
            scenario 
            {
              _configNumber: 0,
              # Each episode will use the same starting conditions
              _timeStep: 2,  # VP Link model takes 2 second time steps (for the PIDs to work well)...
              _reportEvery: 30,  # but reports to Bonsai after 30 seconds of sim time has elapsed.
              #define initial conditions
              _initialConditions: "ReactorStartup.icf",
              # Add some variability in the inlet and outlet temperatures
              Temp_PastLoop_In: number<162 .. 178>,
              Temp_PastLoop_OUT: number<162 .. 178>,
              
            }
          }
          #This teaches Bonsai to deal with the flow fluctuations arising out of Continuous mode
          lesson Continuous {
            scenario 
            {
              _configNumber: 0,
              # Each episode will use the same starting conditions
              _timeStep: 2,  # VP Link model takes 2 second time steps (for the PIDs to work well)...
              _reportEvery: 30,  # but reports to Bonsai after 30 seconds of sim time has elapsed.
              # Define initial conditions
              _initialConditions: "Continuous.icf",
              # Add some variability in the inlet and outlet temperatures
              Temp_PastLoop_In: number<160 .. 180>,
              Temp_PastLoop_OUT: number<160 .. 180>,
              
            }
          }
           
        }
    }
    #This is the narrowed ReactorStartup State
    concept StateForReactStart(input): ReactorStartupState {
            programmed ReduceReactStartState        
        }
    # This is the Reactor Startup Concept
    concept ReactorStartup(StateForReactStart): ReactorStartupAction {
          curriculum {
            source ReactorStartupSimulator
            reward StartupReactorReward

            training {

                    EpisodeIterationLimit: 160, # Brain has this many "_reportEvery" time steps to make this work
                    NoProgressIterationLimit : 2100000 
            }
            lesson GoodStart {
                scenario {
                    _configNumber: 0,
                  # Each episode will use the same starting conditions
                    _initialConditions: "ReactorStartup.icf",
                    _timeStep: 2,  # VP Link model takes 2 second time steps (for the PIDs to work well)...
                    _reportEvery: 30,  # but reports to Bonsai after 30 seconds of sim time has elapsed. 
                    # the below variables are added as domain randomsation to overwrite the conditions 
                    # specified for those variables in the icf file
                    LvlFermenter: number<300.0 .. 500.0>,
                    Reactor_O2: number<16.5 .. 18.5>,
                    Reactor_Temp: number<96.0 .. 98.0>,
                    Reactor_pH: number<7.0 .. 7.5>,
                }
            }
           }
    }
    #This is the narrowed Continuous State
    concept StateForContinuous (input): ContinuousState {
        programmed ReduceContinuousState
    }  
    concept Continuous(StateForContinuous): ContinuousAction {
        curriculum {
          source ContinuousSimulator
          reward ContinuousReward
          training {

                  EpisodeIterationLimit: 120, # Brain has this many "_reportEvery" time steps to make this work
                  NoProgressIterationLimit : 1800000 
          }
          lesson GoodStart {
              scenario {
                  _configNumber: 0,
                  # Each episode will use the same starting conditions
                  _initialConditions: "Continuous.icf",
                  _timeStep: 2,  # VP Link model takes 2 second time steps (for the PIDs to work well)...
                  _reportEvery: 30,  # but reports to Bonsai after 30 seconds of sim time has elapsed.
                  # the below variables are added as domain randomsation to overwrite the conditions 
                  # specified for those variables in the icf file
                  LvlFermenter: number<1100.0 .. 1250.0>,
                  Reactor_O2: number<16.5 .. 18.5>,
                  Reactor_Temp: number<96.5 .. 99.5>,
                  Reactor_pH: number<7.3.. 7.7>,
                  Microbes: number<350.0 .. 500.0>,
                  Food: number<550.0 .. 700.0>,     
              }
          }
        }
  }  

  #This concept does two things
  # 1. it combines the output from all the concepts into one set of actions that can be sent to the simulator
  # 2. it selects which of the reactor specific actions (either continuous or reactor startup) to use
  # It is necessary to have this concept as there is only one possible output concept 
    concept CombineActions (input,  Continuous, ReactorStartup, SterilisationStartup) : SimAction{
        programmed    function (state: SimState,  c: ContinuousAction, r: ReactorStartupAction, Pt: SterilisationAction) { 
                if state.Reactor_Startup_Mode == 1 {
            return {
                Reactor_Level_Setpoint_C: c.Reactor_Level_Setpoint_C,
                Reactor_Level_Setpoint_St: r.Reactor_Level_Setpoint_St,
                PastLoop_TempSetpoint: Pt.PastLoop_TempSetpoint,
                ReactorFoodInlet_PastLoop_TempSetpoint: r.ReactorFoodInlet_PastLoop_TempSetpoint,
                Acid_Flow_Vlv: r.Acid_Flow_Vlv,
                Base_Flow_Vlv: r.Base_Flow_Vlv,
                Air_Blower_Speed: r.Air_Blower_Speed,
                FlowSetPoint_C: c.FlowSetPoint_C,
                FlowSetPoint_St: r.FlowSetPoint_St
                        }
                }
                   
        return {
            Reactor_Level_Setpoint_C: c.Reactor_Level_Setpoint_C,
            Reactor_Level_Setpoint_St: r.Reactor_Level_Setpoint_St,
            PastLoop_TempSetpoint: Pt.PastLoop_TempSetpoint,
            ReactorFoodInlet_PastLoop_TempSetpoint: c.ReactorFoodInlet_PastLoop_TempSetpoint,
            Acid_Flow_Vlv: c.Acid_Flow_Vlv,
            Base_Flow_Vlv: c.Base_Flow_Vlv,
            Air_Blower_Speed: c.Air_Blower_Speed,
            FlowSetPoint_C: c.FlowSetPoint_C,
            FlowSetPoint_St: r.FlowSetPoint_St
                }
            }
        }
    output CombineActions
}