clc
clear all
load('Power_Mass_Sweep.mat')

%%


%% ACCU DETAILS:
vehicle.cellmass    = 0.047;
vehicle.cellIR      = 0.03;
vehicle.cellE       = 0.0108*.75;
vehicle.cellV       = 4.2;%V
vehicle.accuV       = vehicle.cellV * Results.sweep.accumassgrid./vehicle.cellmass;
vehicle.accuE       = vehicle.cellE * Results.sweep.accumassgrid./vehicle.cellmass;
vehicle.accuIR      = vehicle.cellIR * Results.sweep.accumassgrid./vehicle.cellmass;

TempLimit = 40;

for i = 1:size(Results.P_lap,2)
    T_cumtrack = cumtrapz(Results.T_lap{i});
    
    Results.I_track = (vehicle.accuV(i)-sqrt(vehicle.accuV(i).^2 - 4*vehicle.accuIR(i)*Results.P_lap{i}))/(2*vehicle.accuIR(i));
    Results.Accu_E_Loss(i) = trapz(T_cumtrack,(vehicle.accuIR(i)*Results.I_track.^2));
end

Results.accu_Trise = 20 * Results.Accu_E_Loss ./( 1350 * Results.sweep.accumassgrid(:)');%

%%
Ztemp = real(reshape(Results.accu_Trise,size(Results.sweep.accumassgrid)));
Zenergy = real(reshape(Results.Eff,size(Results.sweep.accumassgrid)))
Zpts = reshape(Results.points_Enduro + Results.points_Eff,size(Results.sweep.accumassgrid));
Zpts_autox_Accel = reshape(Results.points_accel + Results.points_Autox + Results.points_skid,size(Results.sweep.accumassgrid));

TempLimPower_mass = [];
ELimPower_mass = [];
Pts_mass = [];
LimPower_mass = [];
for i = 1:length(Results.sweep.accumass)
    Tempspline = spline(Ztemp(:,i),Results.sweep.power);
    Espline = spline(Zenergy(:,i),Results.sweep.power);
    Ptspline = spline(Results.sweep.power,Zpts(:,i));
    
    TempLimPower = min(50,ppval(Tempspline,TempLimit));
    ELimPower = min(50,ppval(Espline,vehicle.accuE(1,i)));
    LimPower = min(TempLimPower,ELimPower);
    Pts = ppval(Ptspline,min(TempLimPower,ELimPower));
    
    Pts = Pts + max(Zpts_autox_Accel(:,i))
    
    TempLimPower_mass = [TempLimPower_mass, TempLimPower];
    ELimPower_mass = [ELimPower_mass, ELimPower];
    Pts_mass = [Pts_mass, Pts];
    LimPower_mass = [LimPower_mass, LimPower];
end

%% Triple Plot

% figure(1)
% subplot (2,2,1)
% contourf(Results.sweep.accumassgrid,Results.sweep.powergrid,Ztemp,'ShowText','on')
% xlabel('Accu Cell Mass [kg]')
% ylabel('Power Setting [Kw]')
% title('Enduro Temp rise [°C]')
% grid on
% 
% subplot (2,2,3:4)
% 
% contourf(Results.sweep.accumassgrid,Results.sweep.powergrid,Zpts,'ShowText','on')
% xlabel('Accu Cell Mass [kg]')
% ylabel('Power Setting [Kw]')
% title('Enduro & Efficiency Points')
% grid on
% 
% subplot (2,2,2)
% 
% contourf(Results.sweep.accumassgrid,Results.sweep.powergrid,Zenergy,'ShowText','on')
% xlabel('Accu Cell Mass [kg]')
% ylabel('Power Setting [Kw]')
% title('Enduro Energy Usage [KwH]')
% grid on
% 
figure(2)
contour(Results.sweep.accumassgrid,Results.sweep.powergrid,Zenergy,'b','ShowText','on')
hold on
contour(Results.sweep.accumassgrid,Results.sweep.powergrid,Ztemp,'r','ShowText','on')
plot(Results.sweep.accumass,TempLimPower_mass,'LineWidth',3)
plot(Results.sweep.accumass,ELimPower_mass,'LineWidth',3)
xlabel('Vmax Setting (km/h)')
ylabel('Power Setting [Kw]')
title('Enduro Temp rise [°C] overlayed with Enduro Energy Usage')
legend('Energy Usage Contours [KwH]','Temp Rise Contours [°C]')
grid on

figure(3)
plot(Results.sweep.accumass,Pts_mass)
hold on
xlabel('Accu Cell Mass [kg]')
ylabel('Potential Dynamic Points')
title('Total Potential Dynamic Points vs Accumulator Cell Mass')
