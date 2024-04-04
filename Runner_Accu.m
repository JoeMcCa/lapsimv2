% Lapsim code developed by: Joe McCarrison
% E: mccarrison.joe@gmail.com
% P: 0403 259 893
% Feel free to contact me for support

% Modify parameters below to change vehicle settings.
% Change the loaded track file as required above vehicle params
% 
% to do sweeps of data:
    % 1) Use "var" & "var2" as indexes of the changing vehicle settings
    % 2) replace the definition of the vehicle parameters with "setting" and "setting2" respectively
    % 3) the results structure will be filled with vectors of length=length(var)*length(var2)
    % 4) settinglist and settinglist2 store the swept values
    % 4) In a seperate post processing function convert these results to format required.

% To do a sensitivity study:
    % 1) change sensitivity_study definition to 1
    % 2) ensure vehicle parameters are correct baseline configuration.
    % Remember that sensitivities will change considerably from one
    % baseline config to another.

    clear all
addpath 'Track Map Data'\
addpath 'Lapsim Functions'\

%% Define simulation settings
simsetup.dx = 0.25;

%%    

var = linspace(20,50,2); %Accu Cell Mass (kg)
%var = linspace(65,100,7); %vmax (m/s)
var2 = linspace(15,50,2); %Power Setting (KW)

T_laps = [];
E_laps = [];
P_setting = [];
T_setting = [];
Enduro_Energy_Used = [];
Vmax_setting = [];
Accu_inv_IR_Loss = [];
accel_times = [];
skidpan_times = [];


settinglist = [];
settinglist2 = [];
Energy_Used = [];

celli = 1
for setting = var
    for setting2 = var2
        settinglist = [settinglist, setting];
        settinglist2 = [settinglist2, setting2];

        
%% Load track map and define track struct

load wintonmap2018_processed.mat

track.K_section = K_section;
track.L_section = L_section;
track.POS = POS;

%% Define vehicle struct
load ggvtyre.mat
vehicle.muXfitgg = muXfitgg;
vehicle.muYfitgg = muYfitgg;
vehicle.MuXsens = 1.07;
vehicle.MuYsens = 1.07;

vehicle.Car_mass = 176 +(setting-29); %Adding delta to sigrid accu
vehicle.Driver_mass = 72;
vehicle.m = (vehicle.Car_mass+vehicle.Driver_mass); %kg
vehicle.CGH = 250; %mm
vehicle.rw = 0.5; %proportion
vehicle.l = 1550; %mm
vehicle.t = 1100; %mm
vehicle.Pmax = setting2; %kW

vehicle.ClA = 3;
vehicle.AeroBias = 0.5;
vehicle.CdA = 1.5;
vehicle.DragCentreHeight = 0; %mm

%ACCU DETAILS:
vehicle.cellmass    = 0.047;
vehicle.cellIR      = 0.03;
vehicle.cellE       = 0;
vehicle.cellV       = 4.2;%V
vehicle.accumass    = setting;
vehicle.accuV       = vehicle.cellV * vehicle.accumass./vehicle.cellmass;
vehicle.accuE       = vehicle.cellE * vehicle.accumass./vehicle.cellmass;
vehicle.accuIR      = vehicle.cellIR * vehicle.accumass./vehicle.cellmass;

vehicle.hub = 0;
vehicle.awd = 0;
vehicle.regen = 0;
vehicle.regenmax = vehicle.Pmax*0.5;

%~~~~~~~~ [ED] Modify Voltage, Irms, Gearing, RPM per volt, Pack_R etc to suit
%new powertrain. also add in 4wd = 0 or 1
vehicle.Voltage = 326.7;
vehicle.Irmsmax = 225;
vehicle.Gearing = 3;
vehicle.Rollingradius = 197; %mm
vehicle.rpmpervolt = 100; %TEMPORARY CHANGE TO DISREGARD VOLTAGE EFFECTS
vehicle.Pack_R = 0.3;
vehicle.motorconst = 0.82;

vehicle.Vmaxvoltage = vehicle.Voltage*vehicle.rpmpervolt*(1/vehicle.Gearing)*(1/60)*2*pi()*vehicle.Rollingradius*(1/1000);
vehicle.Vmaxset = 110;%setting/3.6; %km/h
vehicle.Torquemaxlong = (vehicle.Irmsmax*0.82*vehicle.Gearing*(1000/vehicle.Rollingradius));

%% Run Autox Sim

[autoxresults] = autoxsim(vehicle,track,simsetup);

%% Run Accel Sim

[accelresults] = accelsim(vehicle);

%% Run Skidpan Sim

[skidresults] = SkidSim(vehicle);

%% store results
T_laps = [T_laps, autoxresults.T_lap];
E_laps = [E_laps, autoxresults.Energy_Used];
P_setting = [P_setting, vehicle.Pmax];
T_setting = [T_setting, vehicle.Irmsmax];
Vmax_setting = [Vmax_setting, vehicle.Vmaxvoltage];
Enduro_Energy_Used = [Enduro_Energy_Used, autoxresults.Energy_Used];
skidpan_times = [skidpan_times, skidresults];
accel_times = [accel_times, accelresults];
%Accu_inv_IR_Loss = [Accu_inv_IR_Loss, autoxresults.accu.IR_losses];

P_lap{celli} = autoxresults.P_track;
T_lap{celli} = autoxresults.T_track;

celli = celli + 1
    end
end

%% Scoring

Results.accel = accel_times;
Results.skid = skidpan_times;
Results.Autox = T_laps;
Results.Enduro = 22* T_laps;
Results.Eff = Enduro_Energy_Used; %Conversion from Joule to KWH
Results.P_lap = P_lap;
Results.T_lap = T_lap;
[Results.sweep.accumassgrid,Results.sweep.powergrid] = meshgrid(var,var2);
Results.sweep.accumass = var;
Results.sweep.power = var2;

[Results] = ptcalcsens(Results);

