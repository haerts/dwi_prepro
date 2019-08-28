%% Find scaling factor for DWI intensity normalisation using mtnormalise
% Created: 22/08/2017 

%% Prep
load('/home/hannelore/Documents/ANALYSES/BTC_prepro/subjects/RFavg_init.mat');

folder='/home/hannelore/Documents/ANALYSES/BTC_prepro/subjects/postop/';
cd(folder);
sublist=dir('*'); 
sublist=sublist(3:31,:);
m=length(sublist);


%% Read in initial response functions 
for index=1:m
    subname=sublist(index).name;
    disp(['Processing ' subname '...']);

    subfolder=([folder subname '/dwi/']);
	cd(subfolder);
    
    response{1,index} = textread([subfolder '/wm_init.txt']);   
    response{1,index} = response{1,index}(:,1);   	
    response{2,index} = textread([subfolder '/gm_init.txt']);   		
    response{3,index} = textread([subfolder '/csf_init.txt']);  
end


%% For all tissue types, get average RF per shell
B = [];
for i = 1:size(response,1)
    b_all = cat(2,response{i,:});
	B = cat( 1, B, mean( b_all ./ repmat(b_avg(:,i),1,m) ) );
end


%% Obtain factoring parameter
fact = mean(B,1);


%% Write factoring parameter to dwi folder
for index=1:m
    subname=sublist(index).name;
    disp(['Processing ' subname '...']);
    subfolder=([folder subname '/dwi/']);
	cd(subfolder);
	a = fact(index);    
	save([subfolder '/init_fact.txt'],'a','-ascii');
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Read in final response functions
for index=1:m
    subname=sublist(index).name;
    disp(['Processing ' subname '...']);

    subfolder=([folder subname '/dwi/']);
	cd(subfolder);
    
    response2{1,index} = textread([subfolder '/wm.txt']);   
    response2{1,index} = response2{1,index}(:,1);   	
    response2{2,index} = textread([subfolder '/gm.txt']);   		
    response2{3,index} = textread([subfolder '/csf.txt']);  
end