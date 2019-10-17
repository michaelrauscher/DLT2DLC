%%function to convert a DLT xypts csv into a labeled dataset for use with
%%Deeplabcut. Config is the full path to the DLC project config file, vid
%%is a path to the labeled video in question, csv is the DLT xypts file,
%%and pts is (optionally) a vector for which DLT points are to be included
%%in the training data. For instance if the DLC config file specifies two
%%bodyparts "LeftWing" and "RightWing" and the DLT csv tracks five
%%points, of which these are the 4th and 2nd respectively, one could
%%specify "pts" as [4 2];
function DLT2DLC(config,vid,csv,pts)
%get the working directory for the config file
dlcdir = fileparts(config);
dlcdir = [dlcdir filesep];

%load config file into one big character vector
fid = fopen(config);
cflin = fread(fid,'*char')';
fclose(fid);
%find the linebreaks
newlines = strfind(cflin,newline);

%find the "scorer" line in the config file
scorelinestartix = strfind(cflin,'scorer');
scorelineendix=find(newlines>scorelinestartix,1);
scorelineendix = newlines(scorelineendix)-1;
scorer = strsplit(cflin(scorelinestartix:scorelineendix),':');
scorer = strtrim(scorer{end});

%find the "bodyparts" section of the config file
bpartstartix = strfind(cflin,'bodyparts');
bpartendix = strfind(cflin,'start:');
partslabels = {};
pnl = newlines(newlines>bpartstartix & newlines<bpartendix);
%go through line by line and get each body part
for i = 1:length(pnl)-1
    ix=pnl(i):pnl(i+1);
    part = strtrim(cflin(ix));
    %skip blank or misformatted lines
    if ~contains(part,'-');continue;end
    part = strsplit(part,'-');
    part = strtrim(part{end});
    partslabels = [partslabels {part}];
end

%get the output directory name from the video filename
[~,basevidname,~]= fileparts(vid); 
basevidname = ['labeled-data' filesep basevidname];
%initialize the video reader object(will use later)
v = VideoReader(vid);

%load the DLT csv file
xy = csvread(csv,1);
%use all points if no pts specified
if nargin<4
    pts = size(xy,2)/2;
    pts = 1:pts;
end
%get leading zeros for the saved image filenames to match DLC conventions
leadingzeros = ['%0' num2str(floor(log10(length(xy)))+1) 'd'];

%find only rows with at least one labeled point
labeledix = find(~all(isnan(xy(:,1:2:end)),2));
%break up matrix of xy pts into individual x and y to recombine later
x = xy(labeledix,1:2:end);
y = xy(labeledix,2:2:end);
%reorder acording to specified points
x = x(:,pts);
y = y(:,pts);
%reverse coordinate system of the y data
y = v.Height-y;

%make the scorer line of the DLC CSV file
outcell = [{'scorer'}, repmat({'MJR'},1,length(pts)*2)];

%make and append the bodyparts line of the DLC CSV file
partstr = {'bodyparts'};
for i = 1:length(partslabels)
    partstr = [partstr {partslabels(i) partslabels(i)}];
end
outcell = [outcell;partstr];
%make and append the coordinates line of the DLC CSV file
outcell = [outcell; [{'coords'}, repmat([{'x'},{'y'}],1,length(pts))]];

%create the output directory
mkdir([dlcdir basevidname])
%create the output images and save the filenames into outfns so we can put
%them into the DLC CSV file
outfns = {};
for i = 1:length(labeledix)
    outfn = fullfile(basevidname,['img' num2str(labeledix(i)-1,leadingzeros) '.png']);
    outfns{end+1} = outfn;
    outfn = [dlcdir outfn];
    img = read(v,labeledix(i));
    imwrite(img, outfn);
end
outfns = outfns';

%recombine the xy matrix
outxy = {};
for i = 1:length(pts)
    outxy = [outxy cellstr(num2str(x(:,i))) cellstr(num2str(y(:,i)))];
end
%replace any NaN cells with empty strings
outxy = strrep(outxy,'NaN','');

%combine the whole table for output
outcell = [outcell; [outfns outxy]];
%write the DLC CSV table
outcsvname = [dlcdir fullfile(basevidname,['CollectedData_' scorer '.csv'])];
writetable(cell2table(outcell),outcsvname,'WriteVariableNames',0)

disp('Labeled dataset created. Run "deeplabcut.convertcsv2h5([config_path])" to complete the conversion');
end