% Testing parameters to see what makes funky velocity trace
clc
clear all
%% Setup
simsetup.dx = 0.01;
%simsetup.debugmode = 1;

load("C:\Users\Joe\Documents\MATLAB\lapsimv2\Track Map Data\wintonmap2018_processed.mat")

%load Calder2023_processed.mat

track.K_section = K_section;
track.L_section = L_section;
track.POS = POS;

%% Define vehicle struct
% Tyres
%load ggvtyre.mat
%load 'ggvtyre_Hoosier 43075 16x7.5-10 LCO, 8 inch rim.mat'
load 'ggvtyre_Goodyear D2704 20.0x7.0-13, 7 inch rim.mat'
vehicle.muXfitgg = muXfitgg;
vehicle.muYfitgg = muYfitgg;
vehicle.MuXsens = 1;
vehicle.MuYsens = 1;
vehicle.Rollingradius = 221; %mm

% General Properties
vehicle.Car_mass = 196.6; %kg
vehicle.Driver_mass = 70; %kg
vehicle.m = vehicle.Car_mass+vehicle.Driver_mass; %kg
vehicle.CGH = 310; %mm
vehicle.rw = 0.52; %proportion (rearwards)
vehicle.l = 1535; %mm
vehicle.t = 1200; %mm

% Aero
vehicle.ClA = 4;
vehicle.AeroBias = 0.5;
vehicle.CdA = 1.5;
vehicle.DragCentreHeight = 0; %mm

% Driveline/Powertrain
vehicle.hub = 1; % Binary
vehicle.awd = 0; % Binary
vehicle.regen = 0; % Binary
vehicle.regenmax = 0; %kW
vehicle.Gearing = 11.15; %Ratio

vehicle.Pmax = 70; %kW
vehicle.Pack_R = 0.5; %Ohms
vehicle.Voltage = 579.6; %V
vehicle.Accumcapacity = 9*5*23*6/1000; %kWh; cell WH * parallel cels * series cells per segment * num of segments

vehicle.Irmsmax = 100; %Amps
vehicle.rpmpervolt = 18.8; %rpm/V
vehicle.motorconst = 0.26; %Nm/A

vehicle.Torquemaxlong = 18*(2+2*vehicle.awd)*(vehicle.Irmsmax*vehicle.motorconst*vehicle.Gearing*(1000/vehicle.Rollingradius)); %Nm??? bruh where does 18 come from
vehicle.Vmaxvoltage = vehicle.Voltage*vehicle.rpmpervolt*(1/vehicle.Gearing)*(1/60)*2*pi()*vehicle.Rollingradius*(1/1000);

[autoxresults] = autoxsim(vehicle,track,simsetup);
BestResults.AutoxTime = autoxresults.T_lap;

plot(autoxresults.V_track)