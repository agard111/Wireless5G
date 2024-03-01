M = 16;            % Modulation order
k = log2(M);       % Bits per symbol
numBits = 472;     % Bits to process
sps = 4;           % Samples per symbol (upsampling factor)

% Create RRC filter and set the RRC filter parameters.
filtlen = 10;      % Filter length in symbols
rolloff = 0.35;    % Filter rolloff factor
rrcFilter = rcosdesign(rolloff,filtlen,sps,'sqrt');
% Use the FVTool to display the RRC filter impulse response.
% fvtool(rrcFilter,'Analysis','Impulse')

% Start of ADC output
fromADC = readmatrix('outputADC.csv');

% Scale output of ADC to match the scaling of QAM demodulation scheme
rxScaledI = (fromADC(:,1) - mean(fromADC(:,1))) ./ std(fromADC(:,1));
rxScaledQ = (fromADC(:,2) - mean(fromADC(:,2))) ./ std(fromADC(:,2));

rxMod = complex(rxScaledI, rxScaledQ);

% Use the number of bits per symbol (k), the number of samples per symbol (sps), and the convertSNR function to convert
% the ratio of energy per bit to noise power spectral density (EbNo) to an SNR value for use by the AWGN function.
EbNo = 10;
snr = EbNo + 10*log10(k);

% Pass the filtered signal through an AWGN channel.
% rxSignal = awgn(txFiltSignal2,snr,'measured');

% Use the upfirdn function on the received signal to downsample and filter the signal.
% Each filtering operation delays the signal by half of the filter length in symbols, filtlen/2, 
% so the total delay from transmit and receive filtering equals the filter length, filtlen.
rxDemod = upfirdn(rxMod, rrcFilter, 1, sps);       % Downsample and filter
rxDemod = rxDemod(filtlen + 1:end - filtlen);      % Account for upsampled end bits

% Use the qamdemod function to demodulate the received filtered signal.
dataSymbolsOut = qamdemod(rxDemod,M);

% Convert the data back to bits
dataOut = int2bit(dataSymbolsOut,k);

% Plot constellation chart
scatterplot(rxDemod);

% Determine the number of errors and the associated BER by using the biterr function.
[numErrors,ber] = biterr(dataIn,dataOut);
fprintf(['\nFor an EbNo setting of %3.1f dB, ' ...
    'the bit error rate is %5.2e, based on %d errors.\n'], ...
    EbNo,ber,numErrors)