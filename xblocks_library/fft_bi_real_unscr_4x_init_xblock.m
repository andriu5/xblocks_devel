%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011 Suraj Gowda, Hong Chen, William Mallard                %
%                                                                             %
%   This program is free software; you can redistribute it and/or modify      %
%   it under the terms of the GNU General Public License as published by      %
%   the Free Software Foundation; either version 2 of the License, or         %
%   (at your option) any later version.                                       %
%                                                                             %
%   This program is distributed in the hope that it will be useful,           %
%   but WITHOUT ANY WARRANTY; without even the implied warranty of            %
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             %
%   GNU General Public License for more details.                              %
%                                                                             %
%   You should have received a copy of the GNU General Public License along   %
%   with this program; if not, write to the Free Software Foundation, Inc.,   %
%   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.               %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fft_bi_real_unscr_4x_init_xblock(blk, varargin)
%% Bug unfixed: 
%  when bram_map is set to 'on', error occur in reorder
%  subblocks; since the ROM map_latency can't be 0
%  This problem doesn't exist in fft_bi_real_unscr_2x_init_xblock
%  from casper library

% Initialize and configure a bi_real_unscr_4x block.
% Valid varnames:
% * FFTSize = Size of the FFT (2^FFTSize points).
% * n_bits = Data bitwidth.
% * add_latency = Latency of adders blocks.
% * conv_latency = Latency of cast blocks.
% * bram_latency = Latency of BRAM blocks.
% * bram_map = Store map in BRAM.
% * bram_delays = Implement delays in BRAM.
% * dsp48_adders = Use DSP48s for adders.


% Set default vararg values.
defaults = { ...
    'FFTSize', 3, ...
    'n_bits', 18, ...
    'add_latency', 2, ...
    'conv_latency', 1, ...
    'bram_latency', 2, ...
    'bram_map', 'off', ...
    'bram_delays', 'off', ...
    'dsp48_adders', 'on', ...
    'negate_dsp48e', 1, ...
};

% Retrieve values from mask fields.
FFTSize = get_var('FFTSize', 'defaults', defaults, varargin{:});
n_bits = get_var('n_bits', 'defaults', defaults, varargin{:});
add_latency = get_var('add_latency', 'defaults', defaults, varargin{:});
conv_latency = get_var('conv_latency', 'defaults', defaults, varargin{:});
bram_latency = get_var('bram_latency', 'defaults', defaults, varargin{:});
bram_map = get_var('bram_map', 'defaults', defaults, varargin{:});
bram_delays = get_var('bram_delays', 'defaults', defaults, varargin{:});
dsp48_adders = get_var('dsp48_adders', 'defaults', defaults, varargin{:});
negate_dsp48e = get_var('negate_dsp48e', 'defaults', defaults, varargin{:});

% Generate reorder maps.
map_even = bit_reverse(0:2^(FFTSize-1)-1, FFTSize-1);
map_odd = bit_reverse(2^(FFTSize-1)-1:-1:0, FFTSize-1);
map_out = 2^(FFTSize-1)-1:-1:0;

% Set mirror_spectrum latencies.
if strcmp(dsp48_adders, 'on'),
    ms_input_latency = 1;
    ms_negate_latency = 1;
else
    ms_input_latency = 0;
    ms_negate_latency = 0;
end

%
% Add inputs and outputs.
%

sync = xInport('sync');
even = xInport('even');
odd = xInport('odd');

sync_out = xOutport('sync_out');
pol1_out = xOutport('pol1_out');
pol2_out = xOutport('pol2_out');
pol3_out = xOutport('pol3_out');
pol4_out = xOutport('pol4_out');

%
% Draw wires.
%

en_even = xSignal;
en_odd = xSignal;

reorder_even_sync_out = xSignal;
reorder_even_valid = xSignal;
reorder_even_dout0 = xSignal;

reorder_odd_sync_out = xSignal;
reorder_odd_valid = xSignal;
reorder_odd_dout0 = xSignal;

Counter0_1 = xSignal;
Constant0_1 = xSignal;
Constant1_1 = xSignal;
Relational0_1 = xSignal;
Relational1_1 = xSignal;


Delay_1 = xSignal;

Mux0_1 = xSignal;
Mux1_1 = xSignal;
Mux2_1 = xSignal;
Mux3_1 = xSignal;

hilbert_0_1 = xSignal;
hilbert_0_2 = xSignal;

hilbert_1_1 = xSignal;
hilbert_1_2 = xSignal;

sync_delay_1 = xSignal;

reorder_out_sync = xSignal;
reorder_out_valid = xSignal;
reorder_out_dout0 = xSignal;
reorder_out_dout1 = xSignal;
reorder_out_dout2 = xSignal;
reorder_out_dout3 = xSignal;


sig1 = xSignal;
sig2 = xSignal;
en_out = xSignal;


delay_ms_inputs = {sync_delay_1, sig1, reorder_out_dout0, sig2, reorder_out_dout1, hilbert_1_1, reorder_out_dout2, hilbert_1_2, reorder_out_dout3};
mirror_spectrum_inputs = {};
%
% Add reorder blocks.
%

xBlock( struct('name',  'en_even', 'source',  'Constant'), ...
{    'Position', [15 210 45 230], ...
    'ShowName', 'off', ...
    'arith_type', 'Boolean', ...
    'const', 1, ...
    'n_bits', 1, ...
    'bin_pt', 0, ...
    'explicit_period', 'on', ...
    'period', 1}, ... 	
    {}, {en_even});

xBlock( struct('name',  'reorder_even', 'source',  str2func('reorder_init_xblock')),  ...
{    [blk, '/reorder_even'], ...
    'map', map_even, ...
    'n_inputs', 1, ...
    'bram_latency', bram_latency,...
    'map_latency', 0, ...
    'double_buffer', 0, ...
    'bram_map', bram_map}, ... 	
    {sync, en_even, even}, {reorder_even_sync_out, reorder_even_valid, reorder_even_dout0});

xBlock( struct('name',  'en_odd', 'source',  'xbsIndex_r4/Constant'),  ...
{    'Position', [15 335 45 355], ...
    'arith_type', 'Boolean', ...
    'const', 1, ...
    'n_bits', 1, ...
    'bin_pt', 0, ...
    'explicit_period', 'on', ...
    'period', 1}, ... 	
    {}, {en_odd});

xBlock( struct('name',  'reorder_odd', 'source',  str2func('reorder_init_xblock')),  ...
	{[blk, '/reorder_odd'], 'map', map_odd, 'n_inputs', 1, ...
    'bram_latency', bram_latency, 'map_latency', 0, 'double_buffer', 0, ...
    'bram_map', bram_map}, ... 	
    {sync, en_odd, odd}, {reorder_odd_sync_out, reorder_odd_valid, reorder_odd_dout0});

%
% Add mux control logic.
%

xBlock( struct('name',  'Counter0', 'source',  'xbsIndex_r4/Counter'),  ...
{    'Position', [215 85 260 105], ...
    'cnt_type', 'Free Running', ...
    'cnt_to', inf, ...
    'operation', 'Up', ...
    'start_count', 0, ...
    'cnt_by_val', 1, ...
    'arith_type', 'Unsigned', ...
    'n_bits', FFTSize, ...
    'bin_pt', 0, ...
    'load_pin', 'off', ...
    'rst', 'on', ...
    'en', 'off', ...
    'explicit_period', 'on', ...
    'period', 1, ...
    'use_behavioral_HDL', 'off', ...
    'implementation', 'Fabric'}, ... 	
    {reorder_even_sync_out}, { Counter0_1 });

xBlock( struct('name',  'Constant0', 'source',  'xbsIndex_r4/Constant'),  ...
{    'Position', [225 25 255 45], ...
    'arith_type', 'Unsigned', ...
    'const', 2^(FFTSize-1)-conv_latency, ...
    'n_bits', FFTSize, ...
    'bin_pt', 0, ...
    'explicit_period', 'on', ...
    'period', 1}, ... 	
    {}, {Constant0_1});

xBlock( struct('name',  'Relational0', 'source',  'xbsIndex_r4/Relational'),  ...
{    'Position', [300 20 350 70], ...
    'ShowName', 'off', ...
    'mode', 'a=b', ...
    'en', 'off', ...
    'latency', conv_latency}, ... 	
    {Constant0_1, Counter0_1}, {Relational0_1});

if conv_latency > 0
	const1_val = 2^FFTSize-conv_latency;
else
	const1_val = 0;
end
xBlock( struct('name',  'Constant1', 'source',  'xbsIndex_r4/Constant'),  ...
{    'Position', [225 25 255 45], ...
    'ShowName', 'off', ...
    'arith_type', 'Unsigned', ...
    'const', const1_val, ...
    'n_bits', FFTSize, ...
    'bin_pt', 0, ...
    'explicit_period', 'on', ...
    'period', 1}, ... 	
    {}, {Constant1_1});

xBlock( struct('name',  'Relational1', 'source',  'xbsIndex_r4/Relational'),  ...
{    'Position', [300 20 350 70], ...
    'ShowName', 'off', ...
    'mode', 'a=b', ...
    'en', 'off', ...
    'latency', conv_latency}, ... 	
    {Constant1_1, Counter0_1}, {Relational1_1});


xBlock( struct('name',  'Delay', 'source',  'Delay'),  ...
{    'Position', [225 360 255 380], ...
    'latency', 1, ...
    'reg_retiming', 'off'}, ... 	
    {reorder_odd_dout0}, {Delay_1});

%
% Add mux blocks.
%

xBlock( struct('name',  'Mux0', 'source',  'Mux'),  ...
{    'Position', [475 150 500 216], ...
    'inputs', 2, ...
    'en', 'off', ...
    'latency', 1, ...
    'Precision', 'Full'}, ... 	
    {Relational0_1, reorder_even_dout0, Delay_1}, { Mux0_1 });

xBlock( struct('name',  'Mux1', 'source',  'Mux'),  ...
{    'Position', [475 250 500 316], ...
    'inputs', 2, ...
    'en', 'off', ...
    'latency', 1, ...
    'Precision', 'Full'}, ... 	
    {Relational1_1, Delay_1, reorder_even_dout0}, {Mux1_1});

xBlock( struct('name',  'Mux2', 'source',  'Mux'),  ...
{    'Position', [475 350 500 416], ...
    'inputs', 2, ...
    'en', 'off', ...
    'latency', 1, ...
    'Precision', 'Full'}, ... 	
    {Relational1_1, reorder_even_dout0, Delay_1}, {Mux2_1});

xBlock( struct('name',  'Mux3', 'source',  'Mux'),  ...
{    'Position', [475 450 500 516], ...
    'inputs', 2, ...
    'en', 'off', ...
    'latency', 1, ...
    'Precision', 'Full'}, ... 	
    {Relational0_1, Delay_1, reorder_even_dout0}, {Mux3_1});

%
% Add sync_delay block.
%

sync_delay = 2^(FFTSize-1) + add_latency + conv_latency + 1;

% If the sync delay requires more than four slices,
% then implement it as a counter.
%
% 1 FF + 3 * (SRL16 + FF) ---> 1 + 3 * (16 + 1) = 52

if (sync_delay > 52)
    sync_delay_name = 'sync_delay_ctr';
    xBlock( struct('name',  sync_delay_name, 'source',  str2func('sync_delay_init_xblock')),  ...
{       [blk,'/',sync_delay_name], ...
        sync_delay}, ... 	
    {reorder_even_sync_out}, {sync_delay_1});
else
    sync_delay_name = 'sync_delay_srl';
    xBlock( struct('name',  sync_delay_name, 'source',  str2func('delay_srl_init_xblock')),  ...
{        [blk, '/', sync_delay_name], ...
        sync_delay}, ... 	
    {reorder_even_sync_out}, {sync_delay_1});
end

%
% Add hilbert blocks.
%

if strcmp(dsp48_adders, 'on'),
    hilbert_name = 'hilbert_dsp48e';
    xBlock( struct('name',  [hilbert_name, '0'], 'source',  str2func('hilbert_dsp48e_init_xblock')),  ...
    {       [blk,'/',hilbert_name, '0'], ...
         n_bits, ...
         conv_latency}, ... 	
     {Mux0_1, Mux1_1}, {hilbert_0_1, hilbert_0_2});
    xBlock( struct('name',  [hilbert_name, '1'], 'source',   str2func('hilbert_dsp48e_init_xblock')),  ...
    {        [blk,'/',hilbert_name, '1'], ...
       n_bits, ...
       conv_latency}, ... 	
    {Mux2_1, Mux3_1}, {hilbert_1_1, hilbert_1_2});
else
    hilbert_name = 'hilbert';
    xBlock( struct('name',  [hilbert_name, '0'], 'source',  str2func('hilbert_init_xblock')),  ...
{        [blk,'/',hilbert_name, '0'], ...
        n_bits, ...
        add_latency, ...
        conv_latency}, ... 	
     {Mux0_1, Mux1_1}, {hilbert_0_1, hilbert_0_2});
    xBlock( struct('name',  [hilbert_name, '1'], 'source',  str2func('hilbert_init_xblock')),  ...
{        [blk,'/',hilbert_name, '1'], ...
        n_bits, ...
        add_latency, ...
        conv_latency}, ... 	
    {Mux2_1, Mux3_1}, {hilbert_1_1, hilbert_1_2});
end

%
% Add delay blocks.
%

if strcmp(bram_delays, 'on'),
    delay_name = 'delay_bram';
    xBlock( struct('name',  [delay_name, '0'], 'source',  str2func('delay_bram_init_xblock')),  ...
    {  [blk,'/',delay_name,'0'], ...
       'latency', ...
       2^(FFTSize-1), ...
       'bram_latency', ...
       bram_latency, ...
       'use_dsp48', ...
       'off'}, ... 	
    {hilbert_0_1}, {sig1});
    xBlock( struct('name',  [delay_name, '1'], 'source',  str2func('delay_bram_init_xblock')),  ...
    {   [blk,'/',delay_name,'1'], ...
        'latency', ...
        2^(FFTSize-1), ...
        'bram_latency', ...
        bram_latency, ...
        'use_dsp48', ...
        'off'}, ... 	
    {hilbert_0_2}, {sig2});
else
    delay_name = 'delay_srl';
    xBlock( struct('name',  [delay_name, '0'], 'source',  str2func('delay_srl_init_xblock')),  ...
    {   [blk,'/',delay_name,'0'], ...
        2^(FFTSize-1)}, ... 	
    {hilbert_0_1}, {sig1});
    xBlock( struct('name',  [delay_name, '1'], 'source',  str2func('delay_srl_init_xblock')),  ...
    {   [blk,'/',delay_name,'1'], ...
        2^(FFTSize-1)}, ... 	
    {hilbert_0_2}, {sig2});
end

%
% Add mux reorder and mirror_spectrum blocks.
%

xBlock( struct('name',  'reorder_out', 'source',  str2func('reorder_init_xblock')),  ...
{    [blk,'/reorder_out'], ...
    'map', map_out, ...
    'n_inputs', 4, ...
    'bram_latency', bram_latency, ...
    'map_latency', 0, ...
    'double_buffer', 0, ...
    'bram_map', bram_map}, ... 	
    {sync_delay_1, en_out, sig1, sig2, hilbert_1_1, hilbert_1_2}, ...
    {reorder_out_sync, reorder_out_valid, reorder_out_dout0, reorder_out_dout1, reorder_out_dout2, reorder_out_dout3});

xBlock( struct('name',  'en_out', 'source',  'xbsIndex_r4/Constant'),  ...
{    'Position', [650 330 680 350], ...
    'ShowName', 'off', ...
    'arith_type', 'Boolean', ...
    'const', 1, ...
    'n_bits', 1, ...
    'bin_pt', 0, ...
    'explicit_period', 'on', ...
    'period', 1}, ... 	
    {}, {en_out});


for i = 0:8,
    name = ['delay_ms', num2str(i+1)];
    delay_ms_out = xSignal;
    xBlock( struct('name',  name, 'source',  'Delay'),  ...
    {        'Position', [950 23+i*25 1000 37+i*25], ...
        'latency', ms_input_latency}, ... 	
    { delay_ms_inputs{i+1} }, { delay_ms_out });
    mirror_spectrum_inputs{i+1} = delay_ms_out;
end

xBlock( struct('name',  'mirror_spectrum', 'source', str2func('mirror_spectrum_init_xblock')),  ...
	{[blk,'/mirror_spectrum'], ...
	'FFTSize', FFTSize, 'n_bits', n_bits, 'bram_latency', bram_latency, ...
	'negate_latency', ms_negate_latency, 'negate_dsp48e', negate_dsp48e}, ... 	
    mirror_spectrum_inputs, {sync_out, pol1_out, pol2_out, pol3_out, pol4_out});

end