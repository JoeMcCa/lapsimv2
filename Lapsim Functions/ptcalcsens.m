function [Results] = ptcalcsens(Results)
% Used for calculating points in a parameter sensitivity study context.

%% Autocross
TmaxAx = 1.45 * min(78.81);%,Results.Autox);  %MMS Min 2019
if Results.Autox(1) == 0
    Results.points_Autox = 0 * Results.Autox;
else
    Results.points_Autox = (118.5) .* (((TmaxAx ./ Results.Autox) - 1) / 0.45) + 6.5;
end
%% Enduro
TminEn = min(1544.9);%,Results.Enduro); %MMS Min 2019
TmaxEn = 1.45 * TminEn;
if Results.Enduro(1) == 0
    Results.points_Enduro = 0 * Results.Enduro;
else
    Results.points_Enduro = (250) .* (((TmaxEn ./ Results.Enduro) - 1) / 0.45) + 25;
end
%% Skidpan
Tmin = min(4.925);%,Results.skid); %4.925 = MMS Min 2019
TmaxSk = 1.25 * Tmin; 
if Results.skid(1) == 0
    Results.points_skid = 0 * Results.skid;
else
    Results.points_skid = (71.5) .* (((TmaxSk ./ Results.skid) .^ 2 - 1) / 0.5625) + 3.5;
end
%% Acceleration
TmaxAc = 1.5 * min(3.75);%,Results.accel); %RMITE Min 2019
if Results.accel(1) == 0
    Results.points_accel = 0 * Results.accel;
else
    Results.points_accel = (95.5) .* (((TmaxAc ./ Results.accel) - 1) / 0.5) + 4.5;
end

%% Efficiency
CO2min = 0.65*min(4);%,Results.Eff); %UQR 4kwh min

EF = ((TminEn)./(Results.Enduro)) .* ((CO2min)./(0.65*Results.Eff));
EFmin = (1/1.45) * ((CO2min)/(60.06*0.22));
EFmax = 0.92;

Results.points_Eff = 100 * ((EFmin./EF) - 1) ./ ((EFmin./EFmax) - 1);

%% Total Scores
Results.points_total = Results.points_Eff + Results.points_accel + Results.points_skid + Results.points_Enduro + Results.points_Autox;

%% Scores
% Results.our_points_total = Results.our_points_Autox + Results.our_points_Enduro + Results.our_points_skid + Results.our_points_Eff + Results.our_points_accel
% Results.points_total = Results.points_Autox + Results.points_Enduro + Results.points_skid + Results.points_Eff + Results.points_accel
% score = [Results.points_total; Results.our_points_total];
% scoreboard = sort(score, 'descend');
% position = find(scoreboard==Results.our_points_total);
% 
% score_Autox = [Results.points_Autox; Results.our_points_Autox];
% scoreboard_Autox = sort(score_Autox, 'descend');
% position_Autox = find(scoreboard_Autox==Results.our_points_Autox);
% 
% score_Enduro = [Results.points_Enduro; Results.our_points_Enduro];
% scoreboard_Enduro = sort(score_Enduro, 'descend');
% position_Enduro = find(scoreboard_Enduro==Results.our_points_Enduro);
% 
% score_skid = [Results.points_skid; Results.our_points_skid];
% scoreboard_skid = sort(score_skid, 'descend');
% position_skid = find(scoreboard_skid==Results.our_points_skid);
% 
% score_Eff = [Results.points_Eff; Results.our_points_Eff];
% scoreboard_Eff = sort(score_Eff, 'descend');
% position_Eff = find(scoreboard_Eff==Results.our_points_Eff);
% 
% score_accel = [Results.points_accel; Results.our_points_accel];
% scoreboard_accel = sort(score_accel, 'descend');
% position_accel = find(scoreboard_accel==Results.our_points_accel);
% 
% position_all = [position_Autox, position_Enduro, position_skid, position_Eff, position_accel, position, position];
% scoreboard_nohead = [score_Autox, score_Enduro, score_skid, score_Eff, score_accel, score, scoreboard];
% teams = ["Teams"; "Team1"; "Team2"; "Team3"; "Team4"; "Team5"; "Team6"; "Team7"; "Team8"; "Team9"; "Team10"; "Our Team"; "Our Position"] 
% headers_scoreboard = ["Autocross", "Endurance", "Skidpan", "Efficiency", "Acceleration", "Total", "Total Ordered"];
% scoreboard_final = [headers_scoreboard; scoreboard_nohead; position_all]
% Results.scoreboard_present = [teams, scoreboard_final]
end

