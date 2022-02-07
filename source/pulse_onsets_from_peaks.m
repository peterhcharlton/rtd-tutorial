function onsets = pulse_onsets_from_peaks(sig, peaks)
% PULSE_ONSETS_FROM_PEAKS  Identifies pulse onsets.
%   PULSE_ONSETS_FROM_PEAKS detects pulse onsets in a photoplethysmogram 
%   (PPG) signal from the locations of the pulse peaks
%   
%   # Inputs
%   
%   * sig : a vector of PPG values
%   * peaks : indices of detected pulse peaks
%   
%   # Outputs
%   * onsets : indices of detected pulse onsets
%   
%   # Author
%   Peter H. Charlton, University of Cambridge, February 2022
%   
%   # Documentation
%   <https://ppg-beats.readthedocs.io/>
%   
%   # Version
%   0.1, and is still in development.
%   
%   # Licence
%      This file is part of PPG-beats.
%      PPG-beats is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
%      PPG-beats is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
%      You should have received a copy of the GNU General Public License along with PPG-beats. If not, see <https://www.gnu.org/licenses/>.

onsets = nan(length(peaks)-1,1);
for wave_no = 1 : length(peaks)-1
    [~, temp] = min(sig(peaks(wave_no):peaks(wave_no+1)));
    onsets(wave_no) = temp + peaks(wave_no) - 1;
end

end