%% overview

% this script plots ETAs aligned to any event you want, and compares them
% between two conditions of your choosing (high/low reward, t-1 left or 
% right, correct/incorrect, etc.) Should work with most lewieWorld_B2AFC
% expDefs

% 2018-11-20: LEW created (plotCRF_stimulusHistory.m)
% 2019-05-20: Changed name; modified to more easily change condition comparison
% and adapt to varied contrast conditions across subjects 
% 2019-07-02: moved to git repository 'toupee'; extracted cell type chooser
% to separate function call
% 2020-01-14 streamlining
% 2020-03-25 changed isMoving thresholding to be more precise

%% initialize experiment details

% expInfo = initExpInfo({{'LEW032'}},{{'2020-02-14',3,[3]}});
expInfo = initExpInfo('LEW031');

%% load data

[expInfo, neuralData, behavioralData] = processExperiment(expInfo, 'matched');
[neuralData] = alignResps(expInfo, neuralData, behavioralData);
[neuralData] = getSignificantActivity(expInfo, behavioralData, neuralData);
combinedNeuralData = combineNeuralData(expInfo, behavioralData, neuralData,'matched');

%% extract some variables to make this code still work 

alignedResps = combinedNeuralData.matched.eta.alignedResps;
eventWindow = combinedNeuralData.matched.eta.eventWindow;
bfcH = combinedNeuralData.matched.stats.bfcH;
labels = combinedNeuralData.matched.stats.labels;

%% choose which cells to plot

plotCells = find(bfcH(:,strcmp(labels,'leftMov')) > 0);
% plotCells = 1:size(alignedResps{1},3);

%% initialize some data values
trialBlocks = getTrialBlocks(expInfo);

%extract all contrast values used in the experiment(s)
contrasts = getUniqueContrasts(expInfo);

%set up trial conditions for hi-L and hi-R blocks
trialConditions{1} = initTrialConditions('highRewardSide','left','responseType','correct','movementTime','late');
trialConditions{2} = initTrialConditions('highRewardSide','right','responseType','correct','movementTime','late');

% filter out the longest RTs
% allRTs = eventTimes(7).daqTime - eventTimes(1).daqTime;
% shortRTs = find(allRTs <= 5);

%initialize response arrays
s1 = length(trialConditions);
s2 = length(alignedResps);
s3 = length(contrasts);

meanResp = zeros(length(contrasts),length(eventWindow),s1,s2);
semResp = zeros(length(contrasts),length(eventWindow),s1,s2);
upperCI = zeros(length(contrasts),length(eventWindow),s1,s2);
lowerCI = zeros(length(contrasts),length(eventWindow),s1,s2);

%% initialize some plot values

% set color for each contrast
allColors = [0 0 .5; 0 0 1; 0 .4 1; .6 .8 1; .75 .75 .75; .8 .45 .45; 1 0 0; .5 0 0; .25 0 0];


zeroIdx = find(contrasts == 0);
walkup = length(contrasts) - zeroIdx;
walkback = zeroIdx - 1;
zeroGray = find(allColors(:,1) == .75);
colors = allColors(zeroGray-walkback:zeroGray + walkup,:);

%initialize subplot titles
titles = {'stimOn' 'moveOn' 'rewardOn'};

%initialize figure shape & duration
m = 1;
max_m = length(plotCells);


%% cell-by-cell browser    

fig = figure(201);
hold on
set(fig,'Position',[114   400   1080   630])

while m <= max_m
    %clear subplots
    for s = 1:s1*s2
        subplot(s1,s2,s);
        cla;
    end
    k = plotCells(m);
     
    %for each ETA matrix
    for r = 1:length(alignedResps)
        
        %for each trial reward condition
        for tcon = 1:length(trialConditions)

            for c = 1:length(contrasts)
                % select trials based on high-reward side x contrast
                [~, condIdx] = selectCondition(expInfo, contrasts(c), behavioralData, trialConditions{tcon});
%                 condIdx = intersect(shortRTs, condIdx);
                
                %compute mean+sem responses
                meanResp(c,:,tcon,r) = nanmean(alignedResps{r}(condIdx,:,k),1);
                semResp(c,:,tcon,r) = nanstd(alignedResps{r}(condIdx,:,k))/sqrt(length(condIdx));
                upperCI(c,:,tcon,r) = meanResp(c,:,tcon,r) + semResp(c,:,tcon,r);
                lowerCI(c,:,tcon,r) = meanResp(c,:,tcon,r) - semResp(c,:,tcon,r);
    
                % plot responses
                figure(201);
                subplot(s1,s2,sub2ind([s2 s1],r,tcon));
                hold on;
                plotResp = plot(eventWindow,meanResp(c,:,tcon,r));
                plot1ci = fill([eventWindow';flipud(eventWindow')],[lowerCI(c,:,tcon,r)';flipud(upperCI(c,:,tcon,r)')],colors(c,:), 'LineStyle', 'none');
                alpha(0.2);
                set(plotResp, 'LineStyle', '-', 'LineWidth',1.5,'Color',colors(c,:));
                eventOn = line([0 0],[-1 15]);
                uistack(eventOn,'bottom');
                set(eventOn,'LineStyle', '--', 'LineWidth',1,'Marker','none','Color',[.5 .5 .5]);
                
                if tcon == 1
                    title(titles{r});
                end
                
                if r == 1
                    ylabel('z-scored spikes');
                end
                
                xlim([-.5 1.5]);
                box off
                xlabel('time (s)')
                hold on;
                                
            end
        
        end
        
    end
    
    for s = 1:s1*s2
        subplot(s1,s2,s);
        ylim([ min(reshape(lowerCI,[numel(lowerCI) 1]))*1.1 max(reshape(upperCI,[numel(upperCI) 1]))*1.1 ]);
        ax3 = gca;
        ax3.TickDir = 'out';
    end
    
    %press arrow keys to browse through cells
    was_a_key = waitforbuttonpress;
    if was_a_key && strcmp(get(fig, 'CurrentKey'), 'leftarrow')
      m = max(1, m - 1);
    elseif was_a_key && strcmp(get(fig, 'CurrentKey'), 'rightarrow')
      m = min(max_m, m + 1);
    end
    
end

%% population response

fig = figure(203);
hold on
set(fig,'Position',[114   400   1080   630])

figure(203);
for s = 1:s1*s2
    subplot(s1,s2,s);
    cla;
end

figure(303);
for s = 1:s3*s2
    subplot(s2,s3,s);
    cla;
end
    
%for each ETA matrix
for r = 1:length(alignedResps)

    %for each trial reward condition
    for tcon = 1:length(trialConditions)

        for c = 1:length(contrasts)
            % select trials based on high-reward side x contrast
            [~, condIdx] = selectCondition(expInfo, contrasts(c), behavioralData, trialConditions{tcon});
%             condIdx = intersect(shortRTs, condIdx);

            %compute mean+sem responses
            meanResp(c,:,tcon,r) = nanmean(squeeze(nanmean(alignedResps{r}(condIdx,:,plotCells),1))',1);
            semResp(c,:,tcon,r) = nanstd(squeeze(nanmean(alignedResps{r}(condIdx,:,plotCells),1))')/sqrt(length(plotCells));
            upperCI(c,:,tcon,r) = meanResp(c,:,tcon,r) + semResp(c,:,tcon,r);
            lowerCI(c,:,tcon,r) = meanResp(c,:,tcon,r) - semResp(c,:,tcon,r);
            
            % plot responses
            figure(203);
            subplot(s1,s2,sub2ind([s2 s1],r,tcon));
            hold on;
            plotResp = plot(eventWindow,meanResp(c,:,tcon,r));
            plot1ci = fill([eventWindow';flipud(eventWindow')],[lowerCI(c,:,tcon,r)';flipud(upperCI(c,:,tcon,r)')],colors(c,:), 'LineStyle', 'none');
            alpha(0.2);
            set(plotResp, 'LineStyle', '-', 'LineWidth',1.5,'Color',colors(c,:));
            eventOn = line([0 0],[-1 15]);
            uistack(eventOn,'bottom');
            set(eventOn,'LineStyle', '--', 'LineWidth',1,'Marker','none','Color',[.5 .5 .5]);
            
            if tcon == 1
                title(titles{r});
            end
                
            if r == 1
                ylabel('z-scored spikes');
            end

            xlim([-.5 1.5]);
            box off
            xlabel('time (s)')
            hold on;
            
            % plot responses
            figure(303);
            subplot(s2,s3,sub2ind([s3 s2],c,r));
            hold on;
            plotResp = plot(eventWindow,meanResp(c,:,tcon,r));
            plot1ci = fill([eventWindow';flipud(eventWindow')],[lowerCI(c,:,tcon,r)';flipud(upperCI(c,:,tcon,r)')],colors(c,:), 'LineStyle', 'none');
            alpha(0.2);
            if tcon == 1
                set(plotResp, 'LineStyle', '-', 'LineWidth',1.5,'Color',colors(c,:));
            else
                set(plotResp, 'LineStyle', '--', 'LineWidth',1.5,'Color',colors(c,:));
            end
            eventOn = line([0 0],[-1 15]);
            uistack(eventOn,'bottom');
            set(eventOn,'LineStyle', '--', 'LineWidth',1,'Marker','none','Color',[.5 .5 .5]);

            if tcon == 1
                title(titles{r});
            end

            if c == 1
                ylabel('z-scored spikes');
            end

            xlim([-.5 1.5]);
            box off
            if r == 3
                xlabel('time (s)')
            end
            hold on;

        end
        
    end
        
end

figure(203);    
for s = 1:s1*s2
    subplot(s1,s2,s);
    ylim([ min(reshape(lowerCI,[numel(lowerCI) 1]))*1.1 max(reshape(upperCI,[numel(upperCI) 1]))*1.1 ]);
    ax3 = gca;
    ax3.TickDir = 'out';
end

figure(303);    
for s = 1:s3*s2
    subplot(s2,s3,s);
    ylim([ min(reshape(lowerCI,[numel(lowerCI) 1]))*1.1 max(reshape(upperCI,[numel(upperCI) 1]))*1.1 ]);
    ax3 = gca;
    ax3.TickDir = 'out';
end

%% block-by-block response

for t = 1:length(trialBlocks)
    if trialBlocks{t,2} == 1
        blockConditions{t} = initTrialConditions('highRewardSide','right','responseType','correct','movementTime','late','whichTrials',trialBlocks{t,1});
    elseif trialBlocks{t,2} == -1
        blockConditions{t} = initTrialConditions('highRewardSide','left','responseType','correct','movementTime','late','whichTrials',trialBlocks{t,1});
    end
end

figure(304);
for s = 1:s3*s2
    subplot(s2,s3,s);
    cla;
end
    
%for each ETA matrix
for r = 1:length(alignedResps)

    %for each trial reward condition
    for tcon = 1:length(blockConditions)

        for c = 1:length(contrasts)
            % select trials based on high-reward side x contrast
            [~, condIdx] = selectCondition(expInfo, contrasts(c), behavioralData, blockConditions{tcon});
%             condIdx = intersect(shortRTs, condIdx);

            %compute mean+sem responses
            meanResp(c,:,tcon,r) = nanmean(squeeze(nanmean(alignedResps{r}(condIdx,:,plotCells),1))',1);
            semResp(c,:,tcon,r) = nanstd(squeeze(nanmean(alignedResps{r}(condIdx,:,plotCells),1))')/sqrt(length(plotCells));
            upperCI(c,:,tcon,r) = meanResp(c,:,tcon,r) + semResp(c,:,tcon,r);
            lowerCI(c,:,tcon,r) = meanResp(c,:,tcon,r) - semResp(c,:,tcon,r);
            
            % plot responses
            figure(304);
            subplot(s2,s3,sub2ind([s3 s2],c,r));
            hold on;
            plotResp = plot(eventWindow,meanResp(c,:,tcon,r));
            plot1ci = fill([eventWindow';flipud(eventWindow')],[lowerCI(c,:,tcon,r)';flipud(upperCI(c,:,tcon,r)')],colors(c,:), 'LineStyle', 'none');
            alpha(0.2);
            if strcmp(blockConditions{tcon}.highRewardSide,'left') == 1
                set(plotResp, 'LineStyle', '-', 'LineWidth',1.5,'Color',colors(c,:));
            else
                set(plotResp, 'LineStyle', '--', 'LineWidth',1.5,'Color',colors(c,:));
            end
            eventOn = line([0 0],[-1 15]);
            uistack(eventOn,'bottom');
            set(eventOn,'LineStyle', '--', 'LineWidth',1,'Marker','none','Color',[.5 .5 .5]);

            if tcon == 1
                title(titles{r});
            end

            if c == 1
                ylabel('z-scored spikes');
            end

            xlim([-.5 1.5]);
            box off
            if r == 3
                xlabel('time (s)')
            end
            hold on;

        end
        
    end
        
end

figure(304);    
for s = 1:s3*s2
    subplot(s2,s3,s);
    ylim([ min(reshape(lowerCI,[numel(lowerCI) 1]))*1.1 max(reshape(upperCI,[numel(upperCI) 1]))*1.1 ]);
    ax3 = gca;
    ax3.TickDir = 'out';
end