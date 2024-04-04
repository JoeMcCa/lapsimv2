function [results] = autoxsim(vehicle,track,simsetup)
%UNTITLED2 Summary of this function goes here
%   Changed to function march 2021
%   refer to handler script - A.m for details on how to generate vehicle
%   structure and track struct

%% Redefine simsetup
dx = simsetup.dx;

%% Redefine vehicle struct
muXfitgg    =vehicle.muXfitgg;
muYfitgg    =vehicle.muYfitgg;
MuXsens     =vehicle.MuXsens;
MuYsens     =vehicle.MuYsens;

Car_mass    =vehicle.Car_mass;
Driver_mass =vehicle.Driver_mass;
m           =vehicle.m;
CGH         =vehicle.CGH;
rw          =vehicle.rw;
l           =vehicle.l;
t           =vehicle.t;
Pmax        =vehicle.Pmax;

ClA         =vehicle.ClA;
AeroBias    =vehicle.AeroBias;
CdA         =vehicle.CdA;
DragCentreHeight    =vehicle.DragCentreHeight;

Voltage     =vehicle.Voltage;
Irmsmax     =vehicle.Irmsmax;
Gearing     =vehicle.Gearing;
Rollingradius   =vehicle.Rollingradius;
rpmpervolt  =vehicle.rpmpervolt;

Vmaxvoltage     =vehicle.Vmaxvoltage;
Torquemaxlong   =vehicle.Torquemaxlong;

%% Redefine track struct

K_section = track.K_section;
L_section = track.L_section;
%POS = track.POS;

%% Generate GGV
[GGV latG VelocityRange PosGGV NegGGV] = GGVGenerator(vehicle);
%% Organise Track data:

%Delete First and Last sections. (All must be bounded by Corner Apexii
K_section(1) = [];
K_section(end) = [];
L_section(1) = [];
L_section(end) = [];

vel = linspace(1,VelocityRange(end),50);
rad = [];
for v = vel
    
    r = (v.^2)./latG(v);
    rad = [rad r];
end
rad2vel = fit(transpose(rad),transpose(vel),'smoothingspline');

%% Prepare Track Segments for solver

for i = 1:size(K_section,2)
    Ktrack = K_section{i};
    Ltrack = L_section{i};
    Ltrack = Ltrack - Ltrack(1);
    
    Trackspline = fit(Ltrack,Ktrack,'smoothingspline');
    
    ApexRadiusIn{i} = 1/Trackspline(0);
    V0in{i} = rad2vel(ApexRadiusIn{i});
    ApexRadiusOut{i} = 1/Trackspline(Ltrack(end));
    V0out{i} = rad2vel(ApexRadiusOut{i});
    
    Lmax = dx*round((1/dx)*Ltrack(end)); % Round to nearest multiple of dx
    
    Xarray = linspace(0,Lmax,(Lmax/dx+1));
    
    Ltrack = Lmax/Ltrack(end)*Ltrack; %Scale L vector for the section to the rounded Lmax
    
    KLSpline = spline(Ltrack,Ktrack);
    
    Kxarray = ppval(KLSpline,Xarray); %Use spline to interpolate points that line up with the new X spacing
    
    K_section{i} = Kxarray;
    X_section{i} = Xarray;
    
end
%% Initialise Loops

imax = size(K_section,2);

%% Start positive acceleration loop
for i = 1:imax
    
    jmax = size(K_section{i},2);
    
    V_sectionpos{i} = zeros(size(K_section{i},2),1);
    AX_sectionpos{i} = zeros(size(K_section{i},2),1);
    AY_sectionpos{i} = zeros(size(K_section{i},2),1);
    P_sectionpos{i} = zeros(size(K_section{i},2),1);
    
    if i > 1
        V_sectionpos{i}(1) = min(V0in{i},V_sectionpos{i-1}(end));
    else
        V_sectionpos{i}(1) = V0in{i};
    end
    
    for j = 1:jmax
        if j == 1
            %Velocity Known @ apex. Assumed no Longit Acceleration Capicity
            AX_sectionpos{i}(j)=0;
            AY_sectionpos{i}(j) = V_sectionpos{i}(j).^2*K_section{i}(j); % Recalculate Lateral G
                        
        else
            V_sectionpos{i}(j) = sqrt(V_sectionpos{i}(j-1)^2+2*AX_sectionpos{i}(j-1)*dx); %Assumed Constant acceleration over distance
            AY_sectionpos{i}(j) = V_sectionpos{i}(j).^2*K_section{i}(j);
            
            if AY_sectionpos{i}(j) > latG(V_sectionpos{i}(j));
                AX_sectionpos{i}(j) = 0;
            else
                if V_sectionpos{i}(j) <= Vmaxvoltage
                    TractionLimit = (max(PosGGV(V_sectionpos{i}(j),AY_sectionpos{i}(j)),0));
                    PowerLimit = (Pmax*1000/(V_sectionpos{i}(j))-0.5*1.225*CdA*V_sectionpos{i}(j)^2)./(m);
                    TorqueLimit = (Torquemaxlong-0.5*1.225*CdA*V_sectionpos{i}(j)^2)./(m);
                    MINARRAY = [TractionLimit,PowerLimit,TorqueLimit];
                    P_sectionpos{i}(j) = (min(MINARRAY)*m+0.5*1.225*CdA*V_sectionpos{i}(j)^2)*V_sectionpos{i}(j);
                    AX_sectionpos{i}(j) = min(MINARRAY);
                else
                    AX_sectionpos{i}(j) = 0;
                end
            end
        end
    end 
end

%% Negative acceleration loop (braking)
for i = 1:imax
    i = imax+1-i; %Invert loop drection - rework later
    jmax = size(K_section{i},2);
    
    V_sectionneg{i} = zeros(size(K_section{i},2),1);
    AX_sectionneg{i} = zeros(size(K_section{i},2),1);
    AY_sectionneg{i} = zeros(size(K_section{i},2),1);
    Omega_sectionneg{i} = zeros(size(K_section{i},2),1);
    P_sectionneg{i} = zeros(size(K_section{i},2),1);
    
    if i < imax
        V_sectionneg{i}(jmax) = min(V0out{i},V_sectionneg{i+1}(1));
    else
        V_sectionneg{i}(jmax) = V0out{i};
    end
    
    for j = 1:jmax
        
        j = jmax+1-j; % invert direction of loop through space
        
        if j == jmax
            %Velocity Known. Assumed no Longit Acceleration Capicity
            AX_sectionneg{i}(j)=0;
            AY_sectionneg{i}(j) = V_sectionneg{i}(j).^2*K_section{i}(j); % Recalculate Lateral G
                        
        else
            
            V_sectionneg{i}(j) = sqrt(V_sectionneg{i}(j+1)^2+2*AX_sectionneg{i}(j+1)*dx); %Assumed Constant acceleration over distance
            AY_sectionneg{i}(j) = V_sectionneg{i}(j)^2*K_section{i}(j);
            
            if AY_sectionneg{i}(j) > latG(V_sectionneg{i}(j));
                AX_sectionneg{i}(j) = 0;
            else
                TractionLimit = -1*min(NegGGV(V_sectionneg{i}(j),AY_sectionneg{i}(j)),0);
                PowerLimit = (vehicle.regenmax*1000/(V_sectionneg{i}(j))-0.5*1.225*CdA*V_sectionneg{i}(j)^2)./m;
                TorqueLimit = (Torquemaxlong-0.5*1.225*CdA*V_sectionneg{i}(j)^2)./m;
                MINARRAY = [TractionLimit,PowerLimit,TorqueLimit];
                P_sectionneg{i}(j) = -vehicle.regen*(min(MINARRAY)*m+0.5*1.225*CdA*V_sectionneg{i}(j)^2)*V_sectionneg{i}(j);
                AX_sectionneg{i}(j) = -1*min(NegGGV(V_sectionneg{i}(j),AY_sectionneg{i}(j)),0);
            end
        end       
    end
end

%% Combination Loop
V_track = [];
X_track = [];
AX_track = [];
AY_track = [];
P_track = [];
K_track = [];
Postrue_track = [];

for i = 1:imax
    
    % Non cumulating combinations :^)
    
    postrue = V_sectionpos{i}<V_sectionneg{i};
    negtrue = ~postrue;
    
    V_section{i} = V_sectionpos{i}.*postrue+V_sectionneg{i}.*negtrue;
        V_track = [V_track;V_section{i}(2:end,:)];
    
    AX_section{i} = AX_sectionpos{i}.*postrue-AX_sectionneg{i}.*negtrue;
        AX_track = [AX_track;AX_section{i}(2:end,:)];
    
    AY_section{i} = AY_sectionpos{i}.*postrue+AY_sectionneg{i}.*negtrue;
        AY_track = [AY_track;AY_section{i}(2:end,:)];
        
    P_section{i} = P_sectionpos{i}.*postrue+P_sectionneg{i}.*negtrue;
        P_track = [P_track;P_section{i}(2:end,:)];
        
        K_track = [K_track;K_section{i}(2:end)'];
        
    Postrue_track = [Postrue_track; postrue];
        
    % Cumulating combinations :^)
    if i > 1
        X_track  = [X_track;(X_section{i}(:,2:end)'+X_track(end))];
    else
        X_track  = [X_track; X_section{i}(:,2:end)'];
    end
end

    T_track = dx./V_track;
    T_cumtrack = cumtrapz(T_track);
    T_lap = T_cumtrack(end);

    
    %% Define results struct

    results.laptime = T_lap;
    results.Energy_Used = 22*trapz(T_cumtrack,P_track)*2.7778e-7; %Kw.H
    %22 is number of enduro laps, 2.77e-7 is conversion from W.s to Kw.H

    %results for validation / visualisation of results
    results.T_lap = T_lap;
    results.AX_track = AX_track;
    results.AY_track = AY_track;
    results.V_track = V_track;
    results.P_track = P_track;
    results.K_track = K_track;
    results.L_track = X_track;
    
    results.T_track = T_track;
    results.I_track = (vehicle.Voltage-sqrt(vehicle.Voltage.^2 - 4*0.3*results.P_track))/(2*0.3);
    results.Accu_E_Loss = trapz(T_cumtrack,(vehicle.Pack_R*results.I_track.^2));
    

end