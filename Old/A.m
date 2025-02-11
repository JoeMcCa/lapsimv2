
clear all

%% Sensitivity Study %%

sensitivity_study = 0;

if sensitivity_study == 1
    
    n_sens_params=7;
    
    sets = ones(n_sens_params,2*n_sens_params+1);
    for i = 1:n_sens_params
        sets(i,(i-1)*2+2) = 1.1;
        sets(i,(i-1)*2+3) = 0.9;
    end
          
    MuXsenslist = sets(1,:);
    MuYsenslist = sets(2,:);
    msens = sets(3,:);
    CGHsens = sets(4,:);
    Psens = sets(5,:);
    ClAsens = sets(6,:);
    CdAsens = sets(7,:);
    
    sens_input_list = {'+10% Longit Mu -10%',...
        '+10% Lat Mu -10%',...
        '+10% Mass -10%',...
        '+10% CGH -10%',...
        '+10% Power -10%',...
        '+10% ClA -10%',...
        '+10% CdA -10%'};
else
    n_sens_params = 1;
    
    MuXsenslist = 1;
    MuYsenslist = 1;
    msens = 1;
    CGHsens = 1;
    Psens = 1;
    ClAsens = 1;
    CdAsens = 1;
    
end

%%    

var = 30;%linspace(10,40,5);
var2 = 125;%linspace(100,250,5);

T_laps = [];

settinglist = [];
settinglist2 = [];
Energy_Used = []

for sensindex = 1:length(MuXsenslist)

for setting = var
    for setting2 = var2
        settinglist = [settinglist, setting];
        settinglist2 = [settinglist, setting2];

load wintonmap2018_processed.mat

%load vehicle_data.mat

%% Generate G-G-V Diagram

load ggvtyre.mat
vehicle.muXfitgg = muXfitgg;
vehicle.muYfitgg = muYfitgg;
vehicle.MuXsens = 1.07*MuXsenslist(sensindex);
vehicle.MuYsens = 1.07*MuYsenslist(sensindex);

vehicle.Car_mass = 170;
vehicle.Driver_mass = 65;
vehicle.m = (vehicle.Car_mass+vehicle.Driver_mass)*msens(sensindex); %kg
vehicle.CGH = 250*CGHsens(sensindex); %mm
vehicle.rw = 0.5; %proportion
vehicle.l = 1550; %mm
vehicle.t = 1100; %mm
vehicle.Pmax = setting;%30*Psens(sensindex); %kW

vehicle.ClA = 3*ClAsens(sensindex);
vehicle.AeroBias = 0.5;
vehicle.CdA = 0.8*CdAsens(sensindex);
vehicle.DragCentreHeight = 0; %mm

vehicle.Voltage = 326.7;
vehicle.Irmsmax = setting2;
vehicle.Gearing = 3;
vehicle.Rollingradius = 197; %mm
vehicle.rpmpervolt = 12;

vehicle.Vmaxvoltage = vehicle.Voltage*vehicle.rpmpervolt*(1/vehicle.Gearing)*(1/60)*2*pi()*vehicle.Rollingradius*(1/1000);
vehicle.Torquemaxlong = (vehicle.Irmsmax*0.82*vehicle.Gearing*(1000/vehicle.Rollingradius));

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

%% Solver Settings
dx = 0.25; %m

%% Generate GGV
tic
[GGV latG VelocityRange PosGGV NegGGV] = GGVGenerator(vehicle);
toc
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

tic

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
            %Velocity Known. Assumed no Longit Acceleration Capicity
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
                    PowerLimit = (Pmax*1000/(V_sectionpos{i}(j))-0.5*1.225*CdA*V_sectionpos{i}(j)^2)./m;
                    TorqueLimit = (Torquemaxlong-0.5*1.225*CdA*V_sectionpos{i}(j)^2)./m;
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
                AX_sectionneg{i}(j) = -1*min(NegGGV(V_sectionneg{i}(j),AY_sectionneg{i}(j)),0);
            end
        end       
    end
end

toc

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
    
    T_laps = [T_laps; T_lap];
    
%    Work_Track = Postrue_track.*AX_track.*m.*dx;
    
% figure(2)
% plot (X_track,AX_track)
% hold on
% 
% figure(3)
% plot (X_track,V_track)
% hold on
    Energy_Used = [Energy_Used 22*trapz(T_cumtrack,P_track)*2.7778e-7]
    end
end
end

% if sensitivity_study == 0
%     figure(4)
%     plot (var,T_laps,'o')
% end

if sensitivity_study == 1
    
    X = categorical(sens_input_list);
    X = reordercats(X,sens_input_list);
    Y = (T_laps(2:end)-T_laps(1))/(0.01*T_laps(1));
    
    bar(X,Y)
    ylabel('%change in lap time')
end


%1/ find Terminal Velocity 
%2/ Create Velocity linspace vector 
%3/ open loop through Velocity vector 
%4/ Create +ve longit vector:
    %4a/ call vehicle model solver function (that iterates until 'steady')
        %Use Pure Longit Mu values from muBfit from tyre model data EV / IC
        %maybe use inputted torque - speed graph. but also have option to
        %simple use vehicle power
    %4b/ Output steady acceleration into appended vector
%5/ Create -ve Longit Vector:
    %4a/ call vehicle model solver function (that iterates until 'steady')
        %Use Pure Longit Mu values from muBfit from tyre model data
    %4b/ Output steady acceleration into appended vector
%6/ This gives us the range of longit values the car can apply (for each
%velocity). Now we use this to create a grid of values between these limits
%to calculate combined cornering::
    %6a/ For each velocity find the min and max longit, simply from the
    %tractive data and the braking data 
    %6b/ Create a linspace of longitvalues from the braking limit to 0
    %longit and the tractive limit to 0 longit
    %6c/ Add a point into the longit vector that is very close to the limit
    %to ensure that power limit behaviour is captured appropriately
    %6d/ ensure that for each velocity there is the same number of longit
    %points
    %6e/ output a meshgrid of velocity and longit values
%7/ Now use the longit and velocity as inputs to the vehicle model again,
%this time in lateral mode (mode = 2) to find the max lat possible for each
%combination of velocity and longitudinal acceleration
    %7a/ Open iteration loop for velocity values
        %7b/ Open another iteration loop for longit vector indexes
            %7c/ Call vehicle model and output lateral acceleration
            
            
