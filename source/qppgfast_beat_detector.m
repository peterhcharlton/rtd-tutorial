function [peaks,onsets] = qppgfast_beat_detector(sig,fs)
% QPPGFAST_BEAT_DETECTOR  QPPGFAST PPG beat detector.
%   QPPGFAST_BEAT_DETECTOR detects beats in a photoplethysmogram (PPG) signal
%   using the fast version of the 'Adapted Onset Detector' beat detector
%   
%   # Inputs
%   
%   * sig : a vector of PPG values
%   * fs  : the sampling frequency of the PPG in Hz
%   
%   # Outputs
%   * peaks : indices of detected pulse peaks
%   * onsets : indices of detected pulse onsets
%   
%   # Reference
%   A. N. Vest et al., 'An open source benchmarked toolbox for cardiovascular waveform and interval analysis,' Physiological Measurement, vol. 39, no. 10, 2018. <https://doi.org/10.1088/1361-6579/aae021>
%   
%   # Author
%   * Several authors have contributed to the code (see below)
%   * Peter H. Charlton - did very little, just wrote this wrapper (which detects peaks given the onsets provided by the code)
%   
%   # Documentation
%   <https://ppg-beats.readthedocs.io/>
%   
%   # Version
%   0.1, and is still in development.
%   
%   # Source
%   qppg_fast.m, from the PhysioNet Cardiovascular Signal Toolbox (as of 4 May 2022) at: 
%   <https://github.com/cliffordlab/PhysioNet-Cardiovascular-Signal-Toolbox>. 
%   The toolbox is licensed under the BSD-3-Clause License.
%   
%   # Licence
%      Please see BSD 3-Clause License and GNU GPL Licence below

onsets = qppg_fast(sig,fs);

onsets = tidy_beats(onsets);

peaks = pulse_peaks_from_onsets(sig, onsets);

end

% The remainder of this function is a copy of qppg_fast.m, 
% from the PhysioNet Cardiovascular Signal Toolbox (as of 4 May 2022) at: 
% <https://github.com/cliffordlab/PhysioNet-Cardiovascular-Signal-Toolbox>. 
% The toolbox is licensed under the BSD-3-Clause License here:
% <https://github.com/cliffordlab/PhysioNet-Cardiovascular-Signal-Toolbox/blob/master/LICENSE>
%
% BSD 3-Clause License
% 
% Copyright (c) 2021, Clifford Lab
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
% 
% 1. Redistributions of source code must retain the above copyright notice, this
%    list of conditions and the following disclaimer.
% 
% 2. Redistributions in binary form must reproduce the above copyright notice,
%    this list of conditions and the following disclaimer in the documentation
%    and/or other materials provided with the distribution.
% 
% 3. Neither the name of the copyright holder nor the names of its
%    contributors may be used to endorse or promote products derived from
%    this software without specific prior written permission.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

function ppgOnsets = qppg_fast(data,fs,from,to)

% This function is rewriten from wabp_pleth_new.c and wabp.c
% /* file wabp.c          Wei Zong       23 October 1998
%    			Last revised:   9 April 2010 (by G. Moody)
% -----------------------------------------------------------------------------
% wabp: beat detector for arterial blood presure (ABP) signal
% Copyright (C) 1998-2010 Wei Zong
% 
% This program is free software; you can redistribute it and/or modify it under
% the terms of the GNU General Public License as published by the Free Software
% Foundation; either version 2 of the License, or (at your option) any later
% version.
% 
% This program is distributed in the hope that it will be useful, but WITHOUT ANY
% WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
% PARTICULAR PURPOSE.  See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License along with
% this program; if not, write to the Free Software Foundation, Inc., 59 Temple
% Place - Suite 330, Boston, MA 02111-1307, USA.
% 
% You may contact the author by e-mail (wzong@mit.edu) or postal mail
% (MIT Room E25-505, Cambridge, MA 02139, USA).  For updates to this software,
% please visit PhysioNet (http://www.physionet.org/).
% ------------------------------------------------------------------------------
% 
% This program detects heart beats (pulse waveforms) in a continuous arterial
% blood pressure (ABP) signal.  This version of wabp works best with ABP signals
% sampled at 125 Hz, but it can analyze ABPs sampled at any frequency
% using on-the-fly resampling provided by the WFDB library.  'wabp' has been
% optimized for adult human  ABPs. For other ABPs, it may be necessary to
% experiment with the input sampling frequency and the time constants indicated
% below.
% 
% `wabp' can process records containing any number of signals, but it uses only
% one signal for ABP pulse detection (by default, the lowest-numbered signal
% labelled `ABP', `ART', or `BP';  this can be changed using the `-s' option, see
% below).
% 
% To compile this program under GNU/Linux, MacOS/X, MS-Windows, or Unix, use gcc:
%         gcc -o wabp wabp.c -lwfdb
% You must have installed the WFDB library, available at  
%         http://www.physionet.org/physiotools/wfdb.shtml
% gcc is standard with GNU/Linux and is available for other platforms from:
%         http://www.gnu.org/             (sources and Unix binaries)
%         http://fink.sourceforge.net     (Mac OS/X only)
%         http://www.cygwin.com/          (MS-Windows only)
%         
% For a usage summary, see the help text at the end of this file.  The input
% record may be in any of the formats readable by the WFDB library, and it may
% be anywhere in the WFDB path (in a local directory or on a remote web or ftp
% server).  The output of 'wabp' is an annotation file named RECORD.wabp (where
% RECORD is replaced by the name of the input record).  Within the output
% annotation file, the time of each NORMAL annotation marks an ABP pulse wave
% onset.
%
% 
%
% input :   data: PPG data
%           fs:   sampling frequency, default 125 Hz
%           from: begin point to analysis
%           to  : end point to analysis
% output:   ppgOnsets: onset position of PPG beats in samples
%
%
%
% CHANGE LOG (should be moved to GitHub as commit messages...)
%
% 03 Aug 2010:  by Qiao Li
%   1) sample() function sometimes get WFDB_INVALID_SAMPLE value even when data is good.
%   2) Changed to mysample(), using isigsettime() and getvec() instead, but slow!!!
%   3) Add a mysetbuf() function, read the data to a databuf first, then mysample()
%      get data from the buf. It's much more fast than before.
%
%
% 04 Jul 2011 by Qiao Li
%   1) Set eye-closing period for PPG 0.34s, slope width 0.17s
%   2) Remove physical units to ADC units transform //Tm = physadu((unsigned)sig, Tm);
%   3) Add maxmin_2_3_threshold to modify the logic of eye-closing in order to minimize
%      the double beats
%	4) Change t += EyeClosing; to t = tpq+EyeClosing;
%
%
% 19 Jul 2011 by Qiao Li
% 
%   1) add: (before reading data,at line 480)    
%      isigsettime(from);
%      dataL=from;
%      to read data from 'from' setting
% 	2) Changed: (after learning period, at line 544)
%      (void)sample(sig, tpq);
%      if (sample_valid() == 0) break;
%       to:
%      if (dataend) break;
%
% 18 Oct 2016 by Qiao Li
%   1) add: input parameter fs for different sampling frequency data
%	2) add: re-scale data to ~ +/- 2000
%   3) add: find valley from the original data around 0.25s of tpq
%
% 03 Mar 2017 by Adriana Vest
%   Changed name of function to qppg to avoid confusion with wabp
%	Previous name: wabp_pleth_new.m
%
% 12 Sep 2018 by Giulia Da Poian
%   Changed output variable name to ppgOnsets 
%
% 22 Dec 2018 by Giulia Da Poian
%   Start from the qppg.m code, replace use of global variables and use 
%   function arguments, rename the function qppg_fast
%
% 10 Feb 2022 by Peter H. Charlton
%   Made comments (indicated as 'PC:') to help understand how the code works, and made minor changes to formatting and code (which shouldn't influence performance):
%   - removed calculation of samplingInterval, spm and BUFLN2 (as these variables weren't used)

% PC: if no start and end point are specified, then analyse the entire signal.
if nargin<3
    from=1;
    to=length(data);
end

% PC: check that the signal and its sampling frequency are provided
if nargin<2
    error('Wrong Number of Input Arguments: Sampling Frequency is required')
end

% PC: Setup
ppgOnsets=[];
beat_n=1;

sps=fs; % Sampling Frequency

BUFLN = 4096;           % /* must be a power of 2, see slpsamp() */
EYE_CLS = 0.34;         % /* eye-closing period is set to 0.34 sec (340 ms) for PPG */ 
LPERIOD  = sps*8;       % /* learning period is the first LPERIOD samples */
SLPW = 0.17;            % /* Slope width (170ms) for PPG */                        
NDP = 2.5;              % /* adjust threshold if no pulse found in NDP seconds */
TmDEF = 5;              % /* minimum threshold value (default) */
Tm = TmDEF;

% PC: Reset any PPG values below 32,768 to either the previous value of the PPG (if available) or the mean value
INVALID_DATA=-32768;
if data(1)<=INVALID_DATA+10
    data(1)=mean(data);
end
inv=find(data<=INVALID_DATA+10);
for i=1:length(inv)
    data(inv(i))=data(inv(i)-1);
end

% re-scale data to ~ +/- 2000
if length(data)<5*60*sps
    data=(data-min(data))./(max(data)-min(data)).*4000-2000;
else
% PC: re-scale the PPG data using median averages of the min and max values, rather than the min and max for the whole signal.
% find max/min every 5 minute for re-scaling data
    n=1;
    for i=1:5*60*sps:length(data)
        max_data(n)=max(data(i:min(i+5*60*sps-1,length(data))));
        min_data(n)=min(data(i:min(i+5*60*sps-1,length(data))));
        n=n+1;
    end
    data=(data-median(min_data))./(median(max_data)-median(min_data)).*4000-2000;
end

% PC: specify constants
EyeClosing = round(sps * EYE_CLS);   % /* set eye-closing period */
ExpectPeriod = round(sps * NDP);	  % /* maximum expected RR interval */
SLPwindow = round(sps * SLPW);       % /* slope window size */
timer=0;

% PC: Setup variables
ebuf(1:BUFLN)=0;
lbuf=ebuf;
if from>BUFLN
    tt_2=from-BUFLN;
else
    tt_2=0;
end
aet=0;

t1=8*sps;
t1 = t1+from;
T0 = 0;
n=0;
% cycle through the first 8 seconds of the signal
for t = from:t1
   [temp,ebuf,lbuf,tt_2, aet] = slpsamp(t,data,BUFLN,ebuf,lbuf,tt_2, aet,SLPwindow);
    if temp > INVALID_DATA+10
        T0 = T0+temp;
        n=n+1;
    end
end
T0 = T0/n; % T0=T0/(t1-from);
Ta = 3 * T0;

learning=1;

%    /* Main loop */
t = from;
while t <= to
    
    if (learning) 
        if (t > from + LPERIOD) 
    		learning = 0;
        	T1 = T0;
            t = from;	% /* start over */
        else
            T1 = 2*T0;
        end
    end
            
	[temp,ebuf,lbuf,tt_2, aet] = slpsamp(t,data,BUFLN,ebuf,lbuf,tt_2, aet,SLPwindow);
    
    if (temp > T1)    % /* found a possible ABP pulse near t */ 
	    timer = 0; 
            % /* used for counting the time after previous ABP pulse */
	    maxd = temp;
        mind = maxd;
        tmax=t;
        for (tt = t + 1: t + EyeClosing-1)
            [temp2 ,ebuf,lbuf,tt_2, aet] = slpsamp(tt,data,BUFLN,ebuf,lbuf,tt_2, aet,SLPwindow);
            if temp2 > maxd
                maxd=temp2;
                tmax=tt;
            end
        end
        if (maxd == temp)
            t=t+1;
            continue;
        end
        
        for tt = tmax :-1: (t - EyeClosing / 2 +1)
            [temp2 ,ebuf,lbuf,tt_2, aet] = slpsamp(tt,data,BUFLN,ebuf,lbuf,tt_2, aet,SLPwindow);
            if temp2< mind
                mind=temp2;
            end
        end
        if maxd>mind+10
            onset=(maxd-mind)/100+2;
            tpq=t-round(0.04*fs);
            maxmin_2_3_threshold=(maxd-mind)*2.0/3;
            for tt=tmax:-1:t-EyeClosing/2+1
                [temp2, ebuf,lbuf,tt_2, aet] = slpsamp(tt,data,BUFLN,ebuf,lbuf,tt_2, aet,SLPwindow);
                if temp2<maxmin_2_3_threshold
                    break;
                end
            end
            for tt=tt:-1:t - EyeClosing / 2 + round(0.024*fs)
                [temp2 ,ebuf,lbuf,tt_2, aet] = slpsamp(tt,data,BUFLN,ebuf,lbuf,tt_2, aet,SLPwindow);
                [temp3 ,ebuf,lbuf,tt_2, aet] = slpsamp(tt-round(0.024*fs),data,BUFLN,ebuf,lbuf,tt_2, aet,SLPwindow);
                if temp2-temp3<onset
                    tpq=tt-round(0.016*fs);
                    break;
                end
            end
            
            % find valley from the original data around 0.25s of tpq 
            valley_v = round(tpq);
            for valley_i=round(max(2,tpq-round(0.20*fs))):round(min(tpq+round(0.05*fs),length(data)-1))
                
                % If vally is too low, it cannot serve as an index, so move to the next time.
                if valley_v <= 0
                    t = t + 1;
                    continue;
                end
                
                if data(valley_v)>data(valley_i) && data(valley_i)<=data(valley_i-1) && data(valley_i)<=data(valley_i+1)
                    valley_v=valley_i;
                end
            end
            
            
            if (~learning) 
                
                % If we are looking for the first peak
                if beat_n == 1
                    
                    % If the proposed peak index > 0
                    if round(valley_v) > 0
                        ppgOnsets(beat_n) = round(valley_v);
                        beat_n = beat_n + 1;
                    end
                else
                    % Check if rounded valley_v is greater than the prior beat index
                    if round(valley_v) > ppgOnsets(beat_n-1)
                        ppgOnsets(beat_n) = round(valley_v);
                        beat_n = beat_n + 1;
                    end
                end
            end
        

            % /* Adjust thresholds */
            Ta = Ta + (maxd - Ta)/10;
            T1 = Ta / 3;

            % /* Lock out further detections during the eye-closing period */
            t = tpq+EyeClosing;
        end
    else
        if (~learning) 
	    % /* Once past the learning period, decrease threshold if no pulse
	    %   was detected recently. */
            timer = timer+1;
            if (timer > ExpectPeriod && Ta > Tm) 
                Ta=Ta-1;
                T1 = Ta / 3;
            end
        end
    end
    
    t=t+1;
    
end

% Discard first beat because algorithm always finds first minimum value, so trace-back logic
% will find a fir

end


function [beat1,ebuf,lbuf,tt_2, aet] = slpsamp(t,data,BUFLN,ebuf,lbuf,tt_2, aet,SLPwindow) 

% PC: Inputs:
%      - tt_2 - 
%      - SLPwindow - number of PPG samples in slope window

while (t > tt_2)
    prevVal=0;
    
    if (tt_2>0) && (tt_2-1>0) && (tt_2<length(data)) && (tt_2-1<length(data))
        val2=data(tt_2 - 1);
        val1=data(tt_2);
    else
        val2=prevVal;
        val1=val2;
    end
    prevVal=val2;
    dy =  val1-val2;
    if (dy < 0)
        dy = 0;
    end
    tt_2=tt_2+1;
    M=round(mod(tt_2,(BUFLN-1))+1);
    et=dy;
    ebuf(M)=et;
    %         M2=round(mod(tt_2-SLPwindow,(BUFLN-1))+1);
    %         aet=aet+et-ebuf(M2);
    aet=0;
    for i=0:SLPwindow-1
        p=M-i;
        if p<=0
            p=p+BUFLN;
        end
        aet=aet+ebuf(p);
    end
    lbuf(M) = aet;
    
end
M3=round(mod(t,(BUFLN-1))+1);
beat1=lbuf(M3);

end