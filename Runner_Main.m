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
addpath 'Track Map Data'
addpath 'Lapsim Functions'

%% Define simulation settings
simsetup.dx             = 0.25;     %m
simsetup.vmax           = 40;       %m/s max GGV generation considered velocity
simsetup.vcounts        = 15;       %u/less GGV generator V indexes
simsetup.combinedcounts = 20;       %u/less GGV generator Ax indexes
simsetup.debugmode      = 0;        %displays additional debugging plots

%% Sensitivity Study %%
% sensitivity studies are done by creating an array of mostly ones where
% each column a new parameter is scaled up or down 10% from the baseline by
% being set to 0.9 or 1.1. A total of num_sens_params*2 + 1 simulations are
% run.
sensitivity_study = 0;

if sensitivity_study == 1
    
    n_sens_params=7;
    
    sets = ones(n_sens_params,2*n_sens_params+1);
    for i = 1:n_sens_params
        sets(i,(i-1)*2+2) = 1.1;
        sets(i,(i-1)*2+3) = 0.9;
    end
          
    sens.MuXsenslist = sets(1,:);
    sens.MuYsenslist = sets(2,:);
    sens.msens = sets(3,:);
    sens.CGHsens = sets(4,:);
    sens.Psens = sets(5,:);
    sens.ClAsens = sets(6,:);
    sens.CdAsens = sets(7,:);
    
    sens_input_list = {'+10% Longit Mu -10%',...
        '+10% Lat Mu -10%',...
        '+10% Mass -10%',...
        '+10% CGH -10%',...
        '+10% Power -10%',...
        '+10% ClA -10%',...
        '+10% CdA -10%'};
else
    n_sens_params = 1;

    sens.MuXsenslist = 1;
    sens.MuYsenslist = 1;
    sens.msens = 1;
    sens.CGHsens = 1;
    sens.Psens = 1;
    sens.ClAsens = 1;
    sens.CdAsens = 1;
end

%%  Setting sweeps  
%var and var2 can be set to vectors to sweep through both in a grid array
%fashion. Replace the defition of the param they are defining with setting 
% and setting 2 respectively. If not required, set var and var2 to a single value.

var = 588;%linspace(350,588,10);%linspace(30,120,1+(170-50)/10);%linspace(15,25,5);
var2 = 80;%linspace(30,80,10);%linspace(60,80,5);

% clear results vectors
T_laps = [];
E_laps = [];
P_setting = [];
T_setting = [];
Accu_E_Loss = [];
Vmax_setting = [];
accel_times = [];
skidpan_times = [];


settinglist = [];
settinglist2 = [];
Energy_Used = [];

%progress bar things
textprogressbar('calculating outputs: ');
iii = 0;

%define first value for cell array for timeseries vector data
celli = 1;
for sensindex = 1:length(sens.MuXsenslist)

    for setting = var
        for setting2 = var2
            iii = iii + 1/(length(var)*length(var2)); %increment progress bar value
            settinglist = [settinglist, setting];
            settinglist2 = [settinglist2, setting2];

        
%% Load track map and define track struct
load wintonmap2018_processed.mat
%load('EGGlakeside_processed.mat')

track.K_section = K_section;
track.L_section = L_section;
%track.POS = POS;

%% Define vehicle struct
%tyres
load ggvtyre.mat
vehicle.muXfitgg = muXfitgg;
vehicle.muYfitgg = muYfitgg;
vehicle.MuXsens = sens.MuXsenslist(sensindex);
vehicle.MuYsens = sens.MuYsenslist(sensindex);

%basic vehicle
vehicle.Car_mass = 190; %kg
vehicle.Driver_mass = 75; %kg
vehicle.m = (vehicle.Car_mass+vehicle.Driver_mass)*sens.msens(sensindex); %kg
vehicle.CGH = 250*sens.CGHsens(sensindex); %mm
vehicle.rw = 0.52; %proportion
vehicle.l = 1550; %mm
vehicle.t = 1200; %mm
vehicle.Pmax = setting2*sens.Psens(sensindex); %kW 
% vehicle.Pmax is written here to convert the IDC value to power based on 
% the pack voltage at the time of validation test

% aerodynamics
vehicle.ClA = 3.3*sens.ClAsens(sensindex);
vehicle.AeroBias = 0.5;
vehicle.CdA = 1.5*sens.CdAsens(sensindex);
vehicle.DragCentreHeight = 0; %mm

%~~~~~~~~ [ED] Modify Voltage, Irms, Gearing, RPM per volt, Pack_R etc to suit
%new powertrain. also add in 4wd = 0 or 1
vehicle.hub = 1;
vehicle.awd = 0;
vehicle.regen = 0;
vehicle.regenmax = vehicle.Pmax*0.5;
if vehicle.hub == 0  % DATA FOR EMRAX VEHICLE:
    vehicle.awd = 0;
    vehicle.Voltage = 386.4;
    vehicle.Irmsmax = 175;
    vehicle.Gearing = 3;
    vehicle.Rollingradius = 197; %mm
    vehicle.rpmpervolt = 12;
    vehicle.Pack_R = 0.3;
    vehicle.motorconst = 0.82;
    vehicle.Torquemaxlong = (vehicle.Irmsmax*vehicle.motorconst*vehicle.Gearing*(1000/vehicle.Rollingradius));
else % DATA FOR HUBMOTOR VEHICLE:
    vehicle.Voltage = setting;
    vehicle.Irmsmax = 60;
    vehicle.Gearing = 11;
    vehicle.Rollingradius = 225; %mm
    vehicle.rpmpervolt = 1/0.031;
    vehicle.Pack_R = 0.3;
    vehicle.motorconst = 0.492;
    vehicle.Torquemaxlong = (2+2*vehicle.awd)*(vehicle.Irmsmax*vehicle.motorconst*vehicle.Gearing*(1000/vehicle.Rollingradius));

end
vehicle.Vmaxvoltage = (vehicle.Voltage)*vehicle.rpmpervolt*(1/vehicle.Gearing)*(1/60)*2*pi()*vehicle.Rollingradius*(1/1000);
vehicle.Vmaxset = 20000*(1/vehicle.Gearing)*(1/60)*2*pi()*vehicle.Rollingradius*(1/1000);

%% Run Autox/Skidpan Sim
[autoxresults,skidresults] = autoxsim(vehicle,track,simsetup);

%% Run Accel Sim
[accelresults] = accelsim(vehicle,simsetup);


%% store results
T_laps = [T_laps, autoxresults.T_lap];
E_laps = [E_laps, autoxresults.Energy_Used];
P_setting = [P_setting, vehicle.Pmax];
T_setting = [T_setting, vehicle.Irmsmax];
Vmax_setting = [Vmax_setting, vehicle.Vmaxvoltage];
Accu_E_Loss = [Accu_E_Loss, autoxresults.Accu_E_Loss];
Energy_Used = [autoxresults.Energy_Used];
skidpan_times = [skidpan_times, skidresults];
accel_times = [accel_times, accelresults];

%Store Power and Time lap vectors for accu post processing
P_lap{celli} = autoxresults.P_track;
T_lap{celli} = autoxresults.T_track;
celli = celli + 1;

textprogressbar(100*iii);%text progress bar display update

        end
    end
end

%% Scoring

Results.accel = accel_times;
Results.skid = skidpan_times;
Results.Autox = T_laps;
Results.Enduro = 22* T_laps;
Results.Eff = Energy_Used; %Conversion from Joule to KWH
Results.P_lap = P_lap;
Results.T_lap = T_lap;

%store swept values as meshgrid and axes vectors
[Results.sweep.vargrid,Results.sweep.var2grid] = meshgrid(var,var2);
Results.sweep.var = var;
Results.sweep.var2 = var2;

[Results] = ptcalcsens(Results);

%% Plotting results
if sensitivity_study == 1
    
    Results.points_delta = Results.points_total(1,2:end)-Results.points_total(1);
    
    figure(1)
    Results.barY = reshape(Results.points_delta,[2,7])';
    Results.barX = categorical(sens_input_list);
    %bar(Results.barY)
    bar(Results.barX,Results.barY)
    title('Dynamic Points Sensitivities')
    ylabel('Points Delta - Positive=Points Gain')
    grid on
end
autoxresults.T_lap