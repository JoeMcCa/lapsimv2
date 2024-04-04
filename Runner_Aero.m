clear all
%clearvars -except hubawd hub barn

%% Define simulation settings
simsetup.dx = 0.25;

%% Sensitivity Study %%

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

%%    

var = linspace(0,4,10);
var2 = linspace(1,3,10);

T_laps = [];
E_laps = [];
P_setting = [];
T_setting = [];
Accu_E_Loss = [];
Vmax_setting = [];


settinglist = [];
settinglist2 = [];
Energy_Used = [];
textprogressbar('calculating outputs: ');
iii = 0;
for sensindex = 1:length(sens.MuXsenslist)

    for setting = var
        for setting2 = var2
            iii = iii + 1/(length(var)*length(var2));
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
vehicle.MuXsens = 1.07*sens.MuXsenslist(sensindex);
vehicle.MuYsens = 1.07*sens.MuYsenslist(sensindex);

vehicle.Car_mass = 176;
vehicle.Driver_mass = 65;
vehicle.m = (vehicle.Car_mass+vehicle.Driver_mass)*sens.msens(sensindex); %kg
vehicle.CGH = 250*sens.CGHsens(sensindex); %mm
vehicle.rw = 0.5; %proportion
vehicle.l = 1550; %mm
vehicle.t = 1100; %mm
vehicle.Pmax = 50*sens.Psens(sensindex); %kW

vehicle.ClA = setting*sens.ClAsens(sensindex);
vehicle.AeroBias = 0.5;
vehicle.CdA = setting2*sens.CdAsens(sensindex);
vehicle.DragCentreHeight = 0; %mm
%~~~~~~~~ [ED] Modify Voltage, Irms, Gearing, RPM per volt, Pack_R etc to suit
%new powertrain. also add in 4wd = 0 or 1
vehicle.hub = 0;
vehicle.awd = 0;
vehicle.regen = 0;
vehicle.regenmax = vehicle.Pmax*0.5;
if vehicle.hub == 0
    vehicle.awd = 0;
    vehicle.Voltage = 386.4;
    vehicle.Irmsmax = 225;
    vehicle.Gearing = 3;
    vehicle.Rollingradius = 197; %mm
    vehicle.rpmpervolt = 12;
    vehicle.Pack_R = 0.3;
    vehicle.motorconst = 0.82;
    vehicle.Torquemaxlong = (vehicle.Irmsmax*vehicle.motorconst*vehicle.Gearing*(1000/vehicle.Rollingradius));
else
    vehicle.Voltage = 588;
    vehicle.Irmsmax = 60;
    vehicle.Gearing = 10;
    vehicle.Rollingradius = 197; %mm
    vehicle.rpmpervolt = 1/0.031;
    vehicle.Pack_R = 0.1;
    vehicle.motorconst = 0.492;
    vehicle.Torquemaxlong = (2+2*vehicle.awd)*(vehicle.Irmsmax*vehicle.motorconst*vehicle.Gearing*(1000/vehicle.Rollingradius));

end
vehicle.Vmaxvoltage = vehicle.Voltage*vehicle.rpmpervolt*(1/vehicle.Gearing)*(1/60)*2*pi()*vehicle.Rollingradius*(1/1000);
%vehicle.Vmaxset = 150; 
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
Energy_Used = [autoxresults.Energy_Used];

    textprogressbar(100*iii);
        end
    end
end
Accu_heatrise = Accu_E_Loss*22/(840*29);

%% Scoring

Results.accel = accelresults;
Results.skid = skidresults;
Results.Autox = T_laps;
Results.Enduro = 22* T_laps;
Results.Eff = Energy_Used; %Conversion from Joule to KWH

[Results] = ptcalcsens(Results);

%% Plotting results
if sensitivity_study == 1
    
    Results.points_delta = Results.points_total(1,2:end)-Results.points_total(1);
    
    Results.barY = reshape(Results.points_delta,[2,7])'
    Results.barX = categorical(sens_input_list)
    bar(Results.barX,Results.barY)
    %bar(Results.barX,Results.barY)
    title('Autox, Enduro & Eff Sensitivities')
    ylabel('Points Delta - Positive=Points Gain')
    grid on
end
    