function [GGVfit,latGfit,Velocitylist,posGGV,negGGV] = GGVGenerator(vehicle)
% GGV Diagram Generation Tool
% Joe McCarrison
% Started 23.04.19

%% Redefine vehicle struct
%vehicle params were changed from global shitty variables to structs passed
%from function to function in march 2021.

m = vehicle.m;
CGH = vehicle.CGH;
rw = vehicle.rw; 
l = vehicle.l;
t = vehicle.t;
ClA = vehicle.ClA;
AeroBias = vehicle.AeroBias;
CdA = vehicle.CdA;
DragCentreHeight =vehicle.DragCentreHeight;
muXfitgg = vehicle.muXfitgg;
muYfitgg = vehicle.muYfitgg; 
MuXsens = vehicle.MuXsens;
MuYsens = vehicle.MuYsens;

%% Find Terminal Velocity

%if tractivesource == 1 % Internal Combustion Accurate
%Power curve modifier, with various constants to sweep through
%elseif tractivesource == 2 % Electric Vehicle Accurate
%Inputs incl: Pack Voltage, Peak DC Current, RMS Current,
%else % Simple Power approximation
%Vterminal = (Power/(0.5*CdA*drs*1.225))^(1/3);
%end

%% Open Velocity Vector Loop
Vmax = 40;
Vcounts = 40;
Velocitylist = linspace(1,Vmax,Vcounts); %linspace(1,Vterminal,30);

AYlist = [];
AXlist = [];

Data = [];

for mode = 1:2
    for V = Velocitylist

        [AX,AY,V] = VehicleModel(V,0,mode,vehicle);%Velocity,Longitudinal Acceleration, mode
        
        TData = [AX,AY,V];
        Data = [Data; TData];
        
    end
end

% figure(8)
% plot(Data(:,1),Data(:,3),'.')
% xlabel('Longitudi Acceleration [m/s/s]')
% ylabel('Velocity [m/s]')


%% Pure Lateral
AYlistLAT = [];

for i = 1:Vcounts
    V = Velocitylist(i);
    
    AXinput = 0;
    
    mode = 3;
    
    [AX,AY,V] = VehicleModel(V,AXinput,mode,vehicle);
    
    AYlistLAT = [AYlistLAT; AY];
end

AXlistLAT = zeros(Vcounts,1);
VlistLAT = Velocitylist;
LATGGVData = [AXlistLAT,AYlistLAT,transpose(Velocitylist)];

latGfit = fit(transpose(Velocitylist),AYlistLAT,'smoothingspline');

%% Combined data

CombinedCounts = 10;

for i = 1:Vcounts
    V = Velocitylist(i);
    AXlowerlim = Data(Vcounts+i,1);
    AXupperlim = Data(i,1);
    
    AXlist = linspace(AXlowerlim,AXupperlim,CombinedCounts);
    AXlist(1) = [];
    AXlist(end) = [];
    
    mode = 3;
    
    for AXinput = AXlist
        [AX,AY,V] = VehicleModel(V,AXinput,mode,vehicle);
        
        TData = [AX,AY,V];
        Data = [Data; TData];
    end
end

% figure(3)
% scatter3(Data(:,1)/9.81,Data(:,2)/9.81,Data(:,3),[],Data(:,3))
% colormap(winter)
% xlabel('X - Longitudinal')
% ylabel('Y - Lateral')
% zlabel('Z - Velocity')
% ylim([0 3])
% grid on
% % 
% figure(2)
% scatter(Data(:,1)/9.81,Data(:,2)/9.81,[],Data(:,3))
% colormap(winter)
% xlabel('X - Longitudinal')
% ylabel('Y - Lateral')
% zlabel('Z - Velocity')
% ylim([0 3])
% grid on

%% Fit Surface to Data

Axlist = Data(:,1);
Aylist = Data(:,2);
Vlist = Data(:,3);

GGVfit = fit([Axlist Vlist], Aylist ,'linearinterp'); %

% figure(1)
% plot (GGVfit)
% hold on
% scatter3(Axlist,Vlist,Aylist,'r','filled')
% title('FULL GGV DIAGRAM')
% grid on
% ylabel('V - Velocity')
% xlabel('Ax - Longitudinal Acceleration Limit')
% zlabel('Ay - Lateral Acceleration Limit')
% zlim([0 max(Aylist)])
%% Fing Split points so that Pos/Neg GGV does not curl over itself
YatXmax = [];
for V = Velocitylist
    VelBin = Data(:,3)==V;
    
    VelData = Data(VelBin,:);
    
    maximum = max(max(VelData(:,2)));
    [ind,temp]=find(VelData==maximum);
    YatXmax = [YatXmax VelData(ind,1)];
end
%% Create Positive GGV Diagram
Datapos = [];
for i = 1:Vcounts
    YatXmaxV = YatXmax(i);
    
    DataVbin = Data(:,3)==Velocitylist(i);
    DataV = Data(DataVbin,:);
    
    DataVYbin = DataV(:,1)>=YatXmaxV;
    DataVY = DataV(DataVYbin,:);
    Datapos = [Datapos;DataVY];
end

%Datapos = [Datapos; LATGGVData];
posGGV = fit([Datapos(:,3) Datapos(:,2)], Datapos(:,1) ,'linearinterp');

% figure(7)
% plot (posGGV)
% hold on
% scatter3(Datapos(:,3),Datapos(:,2),Datapos(:,1),'r','filled')
% title('Positive Longitudinal Quadrant')
% zlim([min(Datapos(:,1)) max(Datapos(:,1))])
% xlabel('V - Velocity')
% ylabel('Ay - Lateral Acceleration Limit')
% zlabel('Ax - Longitudinal Acceleration Limit')


%% Create Negative GGV Diagram
Dataneg = [];
for i = 1:Vcounts
    YatXmaxV = YatXmax(i);
    
    DataVbin = Data(:,3)==Velocitylist(i);
    DataV = Data(DataVbin,:);
    
    DataVYbin = DataV(:,1)<=YatXmaxV;
    DataVY = DataV(DataVYbin,:);
    Dataneg = [Dataneg;DataVY];
end

%Dataneg = [Dataneg; LATGGVData];
negGGV = fit([Dataneg(:,3) Dataneg(:,2)], Dataneg(:,1) ,'linearinterp');

% figure(6)
% plot  (negGGV)
% hold on
% scatter3(Dataneg(:,3),Dataneg(:,2),Dataneg(:,1),'r','filled')
% title('Negative Longitudinal Quadrant')
% zlim([min(Dataneg(:,1)) max(Dataneg(:,1))])
% xlabel('V - Velocity')
% ylabel('Ay - Lateral Acceleration Limit')
% zlabel('Ax - Longitudinal Acceleration Limit')

%end

