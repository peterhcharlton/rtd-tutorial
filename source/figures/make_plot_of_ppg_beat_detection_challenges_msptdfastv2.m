function make_plot_of_ppg_beat_detection_challenges_msptdfastv2

% load data
subj_no = 7;
raw_data_path = '/Users/petercharlton/Documents/Data/WESAD/conv_data/wesad_all_activities_data.mat';
load(raw_data_path);

% identify challenges
lims = [-inf, 0, 10, 20, 30, inf];
challenges = {};
for chall_no = 1 : length(lims)-1
    challenges{chall_no} = ['SNR: ', num2str(lims(chall_no)), ' to ', num2str(lims(chall_no+1)) ' dB'];
end

% Obtain beats for this challenge
load_beats = 0;
if load_beats
    % Load PPG beats
    % - Identify path of detected PPG beats for this subject
    subj_no_txt = num2str(subj_no, '%04.f');
    temp = strfind(raw_data_path, '/');
    temp2 = strfind(raw_data_path, '_');
    ppg_beats_path = [raw_data_path(1:temp(end)), 'proc_data_', raw_data_path(temp(end)+1:temp2(end)-1), filesep, subj_no_txt, '_ppg_beats'];
    load(ppg_beats_path);
    ecg_beats_aligned_path = [raw_data_path(1:temp(end)), 'proc_data_', raw_data_path(temp(end)+1:temp2(end)-1), filesep, subj_no_txt, '_ecg_beats_aligned'];
    load(ecg_beats_aligned_path);
else
    % Identify beats
    [~, ~, ppg_beats_inds.MSPTD] = detect_ppg_beats(data(subj_no).ppg, 'MSPTDfastv2');     % detect beats in PPG
    %[ppg_beats_inds.qppgfast, ~, ~] = detect_ppg_beats(data(subj_no).ppg, 'qppgfast');     % detect beats in PPG
    [ecg_beats_inds, qual] = detect_ecg_beats(data(subj_no).ecg.v, data(subj_no).ecg.fs);           % detect beats in ECG and assess quality of beat detection
    ecg_exc_log = ~qual;
    options = struct;
    [ecg_beats_a_inds.MSPTD, ecg_exc_a_log, lag_ecg_samps] = align_ppg_ecg_beats(ppg_beats_inds.MSPTD, ecg_beats_inds, data(subj_no).ppg.fs, data(subj_no).ecg.fs, options, ecg_exc_log);

end

% extract required ECG and PPG data for this challenge
overall_rel_data.ecg = data(subj_no).ecg;
overall_rel_data.ecg.t = [0:length(overall_rel_data.ecg.v)-1]./overall_rel_data.ecg.fs;
%possible_els = find(ecg_exc_a_log==0);
%overall_rel_data.start_time = possible_els(start_el)/data(subj_no).ecg.fs;
overall_rel_data.ppg = data(subj_no).ppg;
overall_rel_data.ppg.t = [0:length(overall_rel_data.ppg.v)-1]./overall_rel_data.ppg.fs;
overall_rel_data.ppg_beats_MSPTD = ppg_beats_inds.MSPTD;
%overall_rel_data.ppg_beats_qppg = ppg_beats_inds.qppgfast;
overall_rel_data.ecg_beats = ecg_beats_a_inds.MSPTD;

% make subplot for each challenge
for challenge_no = 1 : length(challenges)
    
    % assess SNR and find start time
    options.quality_metrics = 'snr';
    [qual, onsets, win_start_els, win_end_els] = assess_ppg_quality(overall_rel_data.ppg.v, overall_rel_data.ppg.fs, options);
    qual_int = interp1(onsets, qual.snr, 1:length(overall_rel_data.ppg.v));
    ecg_exc_a_log_int = interp1(overall_rel_data.ecg.t, ecg_exc_a_log, overall_rel_data.ppg.t);
    possible_els = find(qual_int>lims(challenge_no) & qual_int<lims(challenge_no+1) & ecg_exc_a_log_int==0);
    start_time(challenge_no) = possible_els(4000)/overall_rel_data.ppg.fs;
    
end
clear data

% - setup plot
close all
figure('Position', [20,20,1162,930])
ftsize = 17;
lwidth = 1.5;

% - make a subplot for each challenge
for challenge_no = 1 : length(challenges)
    curr_challenge = challenges{challenge_no};
    
    % setup title
    txt = curr_challenge;
    txt = strrep(txt, '-Inf to ', '<');
    txt = strrep(txt, ' to Inf', '+');
    
    %% Process data for plot
    
    % - select a 10-second window
    durn = 10; % duration in seconds
    end_time = start_time(challenge_no) + durn;
    rel_els = find(overall_rel_data.ppg.t >= start_time(challenge_no) & overall_rel_data.ppg.t <= end_time);
    rel_ppg.fs = overall_rel_data.ppg.fs;
    rel_ppg.v = overall_rel_data.ppg.v(rel_els);
    rel_ppg.t = [0:length(rel_ppg.v)-1]./rel_ppg.fs;
    rel_ppg.MSPTD = overall_rel_data.ppg_beats_MSPTD(overall_rel_data.ppg_beats_MSPTD>= rel_els(1) & overall_rel_data.ppg_beats_MSPTD<= rel_els(end)) - rel_els(1)+1;
    %rel_ppg.qppg = overall_rel_data.ppg_beats_qppg(overall_rel_data.ppg_beats_qppg>= rel_els(1) & overall_rel_data.ppg_beats_qppg<= rel_els(end)) - rel_els(1)+1;
    rel_ecg = overall_rel_data.ecg;
    rel_els = find(rel_ecg.t >= start_time(challenge_no) & rel_ecg.t <= end_time);
    rel_ecg.beats = overall_rel_data.ecg_beats(overall_rel_data.ecg_beats>= rel_els(1) & overall_rel_data.ecg_beats<= rel_els(end)) - rel_els(1)+1;
    
    % - normalise PPG signal to lie between 0 and 1
    rel_ppg.v = (rel_ppg.v-min(rel_ppg.v))./range(rel_ppg.v);

    %% Make plot
    %subplot(length(challenges),1, challenge_no)
    if length(challenges) == 4
        subplot('Position', [0.08,0.06+0.24*(length(challenges)-challenge_no), 0.89, 0.18])
    else
        curr_y_number = 3 - challenge_no;
        if curr_y_number < 0
            curr_y_number = curr_y_number+3;
        end
        if challenge_no < 4
            subplot('Position', [0.08,0.06+0.31*(curr_y_number), 0.40, 0.23])
        else
            subplot('Position', [0.59,0.06+0.31*(curr_y_number), 0.40, 0.23])
        end
    end
    
    % - plot ECG beats
    for beat_no = 1 : length(rel_ecg.beats)
        h = plot(ones(2,1)*rel_ecg.t(rel_ecg.beats(beat_no)), [-0.1,0.23], '--', 'Color', 0.2*ones(1,3), 'LineWidth', lwidth);
        hold on
    end
    
    % - plot PPG signal
    plot(rel_ppg.t, rel_ppg.v, 'b', 'LineWidth', lwidth), hold on

    % - plot PPG beats
    beat_detectors = {'MSPTD'}; %, 'qppg'};
    mk_styles = {'or','+k'};
    mk_sizes = [16,12];
    for beat_detector_no = 1:length(beat_detectors)
        curr_beat_detector = beat_detectors{beat_detector_no};
        eval(['rel_ppg_beats_inds = rel_ppg.' curr_beat_detector ';']);
        h(beat_detector_no+1) = plot(rel_ppg.t(rel_ppg_beats_inds), rel_ppg.v(rel_ppg_beats_inds), mk_styles{beat_detector_no}, 'LineWidth', lwidth, 'MarkerSize', mk_sizes(beat_detector_no));
    end
    
    % - Label axes
    ylabel('PPG (au)', 'FontSize', ftsize)
    if curr_y_number ==0 || challenge_no == 5
        xlabel('Time (s)', 'FontSize', ftsize)
    end
    
    % - tidy up plot
    xlim([0 durn])
    ylim([-0.1, 1.1])
    xticks = 0:2:durn;
    set(gca, 'FontSize', ftsize, 'XTick', xticks, 'YTick', [], 'XGrid', 'on')
    box off
    
    % - add title
    if length(challenges) == 4
        x_val = .44;
    else
        if challenge_no < 4
            x_val = 0.2;
        elseif challenge_no >=4
            x_val = 0.75;
        end
    end
    dim = [x_val 0.22+0.31*(curr_y_number) .1 .1];
    annotation('textbox',dim,'String',txt,'FitBoxToText','on', 'FontSize', ftsize, 'LineStyle', 'none');

    % legend
    if challenge_no == 1
        leg_txt = {'ECG beats', 'MSPTDfastv2 beat detector'}; %, 'qppg beat detector'}
        legend(h, leg_txt, 'Position', [0.525,0.98,0.01,0.01], 'Orientation', 'horizontal', 'FontSize', ftsize)
    end

end

% save figure
filepath = '/Users/petercharlton/Library/CloudStorage/GoogleDrive-peterhcharlton@gmail.com/My Drive/Work/Images/PPG beat detection/ppg_beat_detection_challenges_msptdfastv2';
save_fig(filepath)

end

function save_fig(filepath)

print(gcf, filepath, '-depsc')
fid = fopen([filepath, '.txt'], 'w');
fprintf(fid, ['Created using ' mfilename, ', ', date]);
fclose(fid);

end