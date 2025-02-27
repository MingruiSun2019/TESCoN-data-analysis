function out = rmsSmoothing(data, windowLen, sampleRate)
    % windowLen: RMS window length length in s.
    % sampleRate: sampling rate in Hz
    windowLenInSample = windowLen * sampleRate;
    out = sqrt(movmean(data.^2, windowLenInSample));
end