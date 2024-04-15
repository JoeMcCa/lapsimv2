function [time] = accelsim(vehicle,simsetup)
% Version 1.0 - Validated Model
%   Detailed explanation goes here
%% Event definition
s_finish = 75;
s_0 = -0.3;
dt = 0.001;

if nargin == 2
    if(isfield(simsetup,'debugmode') == 1)
        debugmode = simsetup.debugmode;
    else
        debugmode = 0;
    end
else
    debugmode = 0;
end

%% 


% mu = 1.5;
% m_driver = 65;
% m_vehicle = 176;
m = vehicle.m;
% rwbias = 0.5;
Rolling_radius = vehicle.Rollingradius;
Gearing = vehicle.Gearing;
Voltage_max = vehicle.Voltage;
irms_max = vehicle.Irmsmax;
Power = 60;
rpmpervolt = vehicle.rpmpervolt;
Pack_resistence = vehicle.Pack_R;
Torque = irms_max*vehicle.motorconst*Gearing;
% ClA = 3.5;
CdA = vehicle.CdA;
% Aerobias = 0.5;
% COG_height = 250;
% wheelbase = 1550;
% awd = 0;

s = s_0;
v = 0;
a = 0;
t = 0;

a_trac = [];
a_torque = [];
a_power = [];
a_drag = [];

while s(end) < s_finish
    Drag = CdA*1.2041*v(end)^2/2;
    F_power = Power*1000/v(end);
    [AX,AY,V] = VehicleModel(v(end),a(end),1,vehicle);  
    %current = (-Voltage_max+sqrt(Voltage_max^2-4*Pack_resistence*(a(end)*m+Drag)*v(end)))/(-2*Pack_resistence);
    voltage = Voltage_max;%-current*Pack_resistence;
    v_max_voltage = rpmpervolt*voltage/60/Gearing*2*pi()*Rolling_radius/1000;
    Imax = (-Voltage_max+sqrt(Voltage_max^2-4*Pack_resistence*((v_max_voltage-v(end))/dt*m+Drag)*v(end)))/(-2*Pack_resistence);
    Vmax = Voltage_max-Imax*Pack_resistence;
    Pmax =Imax*Vmax;
    
    F_torque = vehicle.Torquemaxlong;
    
    F_acceleration = min([AX*m,F_torque,F_power]);
    
    a_new = ((F_acceleration)-Drag)/m;
    v_new = v(end)+a_new*dt;
    s_new = s(end)+v_new*dt;
        
    
    if s(end) > 0
        t_new = t(end)+dt;
        t = [t,t_new];
        a_trac = [a_trac,AX];
        a_torque = [a_torque,F_torque/m];
        a_power = [a_power,F_power/m];
        a_drag = [a_drag,-Drag/m];
        
    end
    s = [s,s_new];
    v = [v,v_new];
    a = [a,a_new];
end
L = length(t);
s = s(end-L+1:end);
v = v(end-L+1:end);
a = a(end-L+1:end);




time = t(end);

%% Plots

if (debugmode == 1)
    figure
    tiledlayout(3,1)
    ax1 = nexttile;
    plot(ax1,t,a)
    ylabel(ax1,'m/s^2')
    grid('on')
    ax2 = nexttile;
    plot(ax2,t,v)
    ylabel(ax2,'m/s')
    grid('on')
    ax3 = nexttile;
    plot(ax3,t,s)
    ylabel(ax3,'m')
    xlabel(ax3,'time (s)')
    grid('on')

    figure
    t = t(2:end);
    a = a(2:end);
    plot(t,a_trac,t,a_torque,t,a_power,t,a_drag,t,a)
    title('RWD Single')
    ylim([min(a_drag),1.25*max([a_trac,a_torque])])
    xlabel('time (s)')
    ylabel('acceleration (m/s^2)')
    grid('on')
    legend({'Traction limit','Torque limit','Power limit','Drag','Vehicle acceleration'})
end