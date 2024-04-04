clear all

regenmult = 0.5;

Study.rs = concept_study(0,0,0,regenmult);
clearvars -except Study regenmult

Study.rh = concept_study(0,1,0,regenmult);
clearvars -except Study regenmult

Study.rhr = concept_study(0,1,1,regenmult);
clearvars -except Study regenmult

Study.ah = concept_study(1,1,0,regenmult);
clearvars -except Study regenmult

Study.ahr = concept_study(1,1,1,regenmult);
clearvars -except Study regenmult
%% points

points = [Study.rs.points_accel,Study.rh.points_accel,Study.rhr.points_accel,Study.ah.points_accel,Study.ahr.points_accel,100; ...
    Study.rs.points_skid,Study.rh.points_skid,Study.rhr.points_skid,Study.ah.points_skid,Study.ahr.points_skid,75; ...
    Study.rs.points_Autox,Study.rh.points_Autox,Study.rhr.points_Autox,Study.ah.points_Autox,Study.ahr.points_Autox,125; ...
    Study.rs.points_Eff,Study.rh.points_Eff,Study.rhr.points_Eff,Study.ah.points_Eff,Study.ahr.points_Eff,100; ...
    Study.rs.points_Enduro,Study.rh.points_Enduro,Study.rhr.points_Enduro,Study.ah.points_Enduro,Study.ahr.points_Enduro,275];

total = [Study.rs.points_total,Study.rh.points_total,Study.rhr.points_total,Study.ah.points_total,Study.ahr.points_total,675];

Accel = [Study.rs.accel,Study.rh.accel,Study.rhr.accel,Study.ah.accel,Study.ahr.accel,3.75];
Skid = [Study.rs.skid,Study.rh.skid,Study.rhr.skid,Study.ah.skid,Study.ahr.skid,4.925];
Autox = [Study.rs.Autox,Study.rh.Autox,Study.rhr.Autox,Study.ah.Autox,Study.ahr.Autox,78.81];
Eff = [Study.rs.Eff,Study.rh.Eff,Study.rhr.Eff,Study.ah.Eff,Study.ahr.Eff,4];
Enduro = [Study.rs.Enduro,Study.rh.Enduro,Study.rhr.Enduro,Study.ah.Enduro,Study.ahr.Enduro,1544.9];

pointsp = points;
pointsp(:,1) = [];
pointsp(:,end) = [];
pointsp = pointsp-points(:,1);

Accelp = (Accel(2:end-1)./Accel(1)-1).*100;
Skidp = (Skid(2:end-1)./Skid(1)-1).*100;
Autoxp = (Autox(2:end-1)./Autox(1)-1).*100;
Effp = (Eff(2:end-1)./Eff(1)-1).*100;
Endurop = (Enduro(2:end-1)./Enduro(1)-1).*100;
percent = [Accelp;Skidp;Autoxp;Effp;Endurop];
%% Plots

figure(1)
Events = categorical({'Acceleration','Skid Pad','Autocross','Efficiency','Endurance'});
Events = reordercats(Events,{'Acceleration','Skid Pad','Autocross','Efficiency','Endurance'});
bar(Events,points)
title('Vehicle Concept Points Comparison')
xlabel('Dynamic Events')
ylabel('Points')
grid('on')
legend({'RWD Single','RWD Hub','RWD Hub + Regen','AWD Hub','AWD Hub + Regen','Maximum Points'})

figure(3)
performance1 = tiledlayout(1,2);
x1 = nexttile(1);
bar(Events,percent)
title('Performance Comparison')
xlabel('Dynamic Events')
ylabel('Percentage')
grid('on')
legend({'RWD Hub','RWD Hub + Regen','AWD Hub','AWD Hub + Regen'})

x2 = nexttile(2);
bar(Events,pointsp);
title('Points Comparison')
xlabel('Dynamic Events')
ylabel('Points')
grid('on')
legend({'RWD Hub','RWD Hub + Regen','AWD Hub','AWD Hub + Regen'})

title(performance1,'Comparison to RWD Single Motor Concept')

figure(4)
vehicles = categorical({'RWD Single','RWD Hub','RWD Hub + Regen','AWD Hub','AWD Hub + Regen','2019 Best'});
vehicles = reordercats(vehicles,{'RWD Single','RWD Hub','RWD Hub + Regen','AWD Hub','AWD Hub + Regen','2019 Best'});
performance2 = tiledlayout(2,3);
ax1 = nexttile(1);
bar(vehicles,Accel)
ylim([min(Accel)/1.1,1.1*max(Accel)])
title('Acceleration')
ylabel('Time (s)')
grid('on')

ax2 = nexttile(2);
bar(vehicles,Skid);
ylim([min(Skid)/1.1,1.1*max(Skid)])
title('Skid Pad')
ylabel('Time (s)')
grid('on')

ax3 = nexttile(3);
bar(vehicles,Autox);
ylim([min(Autox)/1.1,1.1*max(Autox)])
title('Autocross')
ylabel('Time (s)')
grid('on')

ax4 = nexttile(4);
bar(vehicles,Eff);
ylim([min(Eff)/1.1,1.1*max(Eff)])
title('Efficiency')
ylabel('Energy Used (kWh)')
grid('on')

ax5 = nexttile(5);
bar(vehicles,Enduro);
ylim([min(Enduro)/1.1,1.1*max(Enduro)])
title('Endurance')
ylabel('Time (s)')
grid('on')

title(performance2,'Concpet Performance Comparison')

figure(2)
pointst = transpose(points);
bar(vehicles,pointst,'stacked');
legend({'Acceleration','Skid Pad','Autocross','Efficiency','Endurance'})
title('Concept Total Points Comparison')

%rwddelta = Study.rh.Eff-Study.rhr.Eff
%awddelta = Study.ah.Eff-Study.ahr.Eff

%% regen

multlist = linspace(0,1,11);
regenawd = [];
regenrwd = [];
timeawd = [];
timerwd = [];
for i = multlist
    regenawd = [regenawd,concept_study(1,1,1,i).Eff];
    regenrwd = [regenrwd,concept_study(0,1,1,i).Eff];
    timeawd = [timeawd,concept_study(1,1,1,i).Enduro];
    timerwd = [timerwd,concept_study(0,1,1,i).Enduro];
end
%% plot regen

rawd = (1-regenawd./regenawd(1))*100;
rrwd = (1-regenrwd./regenrwd(1))*100;
figure(5)
regen = tiledlayout(1,2);
bx1 = nexttile(1);
plot(multlist*50,regenawd,multlist*50,regenrwd)
xlabel('Maximum Regen (kW)')
ylabel('Net Energy Use (kWh)')
grid('on')
legend('AWD','RWD')
bx2 = nexttile (2);
plot(multlist*50,rawd,multlist*50,rrwd)
xlabel('Maximum Regen (kW)')
ylabel('Energy Recovered (%)')
grid('on')
legend('AWD','RWD')
title(regen,'Regen Driveline Comparison')