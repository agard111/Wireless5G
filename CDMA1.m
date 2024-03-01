clear all;
clc;

M = 16;            % Modulation order
k = log2(M);       % Bits per symbol
numBits = 472;     % Bits to process
sps = 4;           % Samples per symbol (upsampling factor)

% Create RRC filter and set the RRC filter parameters.
filtlen = 10;      % Filter length in symbols
rolloff = 0.25;    % Filter rolloff factor
rrcFilter = rcosdesign(rolloff,filtlen,sps,'sqrt');
% Use the FVTool to display the RRC filter impulse response.
% fvtool(rrcFilter,'Analysis','Impulse')

% Use the randi function to generate random binary data. Set the rng function to its default state
% or any static seed value so that the example produces repeatable results.
rng shuffle;                     % Default random number generator
dataIn = randi([0 1],numBits,1); % Generate column vector of binary data

% Use the bit2dec function to convert k-tuple binary words into integer symbols.
r = reshape(dataIn,k,length(dataIn)/k)';
dataSymbolsIn = bin2dec(num2str(r));

% Apply 16-QAM modulation using the qammod function.
dataMod = qammod(dataSymbolsIn, M);
dataModReal = [real(dataMod) imag(dataMod)];

% Use the upfirdn function to upsample the signal by the oversampling factor and apply the RRC filter.
% The upfirdn function pads the upsampled signal with zeros at the end to flush the filter. Then, the function applies the filter.
txI = upfirdn(dataModReal(:,1),rrcFilter,sps,1);
txQ = upfirdn(dataModReal(:,2),rrcFilter,sps,1);

% Scale txI and txQ to have the correct amplitudes for input into the DAC
txScaledI = txI./(max(txI)-min(txI)) - min(txI./(max(txI)-min(txI)));
txScaledQ = txQ./(max(txQ)-min(txQ)) - min(txQ./(max(txQ)-min(txQ)));
toDAC = round([txScaledI txScaledQ] .* 255);
writematrix(toDAC, "toDAC.csv");

