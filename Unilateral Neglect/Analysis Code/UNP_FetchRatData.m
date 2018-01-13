function [ data ] = UNP_FetchRatData( )

%POST RATS
%rat_list = {'UNP2', 'UNP5', 'UNP6', 'UNP7', 'UNP9', 'UNP16', 'UNP10', 'UNP17','UNP14'};
%vns_list = [0 0 0 0 0 0 0 0 0];
% rat_list = {'UNP9', 'UNP10', 'UNP16', 'UNP17'};
% vns_list = [0 0 0 0];
% stage_list = {'N5', 'N6'};
% data_path = 'Z:\Unilateral Neglect\Rats\';

%PRE RATS
% rat_list = {'UNP11', 'UNP12', 'UNP13', 'UNP15'};
% vns_list = [0 0 0 0];
% stage_list = {'N5', 'N6'};
% data_path = 'Z:\Unilateral Neglect\Rats\';

%PRE RATS - PSYCHOMETRIC
% rat_list = {'UNP15', 'UNP18', 'UNP20'};
% vns_list = [0 0 0];
% stage_list = {'N10'};
% data_path = 'Z:\Unilateral Neglect\Rats\';

%POST RATS - PSYCHOMETRIC
rat_list = {'UNP9', 'UNP10', 'UNP16', 'UNP17'};
vns_list = [0 0 0 0];
stage_list = {'N10'};
data_path = 'Z:\Unilateral Neglect\Rats\';

data = UNP_ReadRawData(rat_list, vns_list, stage_list, data_path);

end

