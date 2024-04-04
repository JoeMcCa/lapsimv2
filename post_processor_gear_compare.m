% Post Processor for comparing two discrete gear ratios:
clc
clear all

Results18 = load('Voltage_Power_Sweep_18intyre.mat');
Results20 = load('Voltage_Power_Sweep_20intyre.mat');

vargrid = Results20.Results.sweep.vargrid;
var2grid = Results20.Results.sweep.var2grid;

Results.Autox = Results18.Results.Autox - Results20.Results.Autox;

Results.autox_times_mesh = reshape(Results.Autox,10,10);

contourf(vargrid,var2grid,Results.autox_times_mesh,'showtext','on')
ylabel('Power Setting [kW]')
xlabel('Pack SOC Voltage [V]')
colormap("turbo")
colorbar
legend('Lap time delta | Positive: 18" faster | negative: 20" faster')
title('Lap Time Delta Between 18" and 20" Tyre Diameter')

figure
surf(vargrid,var2grid,Results.autox_times_mesh)
ylabel('Power Setting [kW]')
xlabel('Pack SOC Voltage [V]')
zlabel('Lap time delta [s] | Positive: 18" faster | negative: 20" faster')
colormap("turbo")
colorbar
legend('Lap time delta | Positive: 18" faster | negative: 20" faster')
title('Lap Time Delta Between 18" and 20" Tyre Diameter')