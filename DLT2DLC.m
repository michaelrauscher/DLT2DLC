%%function to convert a DLT xypts csv into a labeled dataset for use with
%%Deeplabcut. Config is the full path to the DLC project config file, vid
%%is a path to the labeled video in question, csv is the DLT xypts file,
%%and pts is (optionally) a vector for which DLT points are to be included
%%in the training data. For instance if the DLC config file specifies two
%%bodyparts "LeftAntenna" and "RightAntenna" and the DLT csv tracks five
%%points, of which these are the 4th and 2nd respectively, one could
%%specify "pts" as [4 2];
function DLT2DLC(config,vid,csv,pts)
dlcdir = fileparts(config);
dlcdir = [dlcdir filesep];

fid = fopen(config);
cflin = fread(fid,'*char')';
fclose(fid);
newlines = strfind(cflin,newline);

scorelinestartix = strfind(cflin,'scorer');
scorelineendix=find(newlines>scorelinestartix,1);
scorelineendix = newlines(scorelineendix)-1;
scorer = strsplit(cflin(scorelinestartix:scorelineendix),':');
scorer = strtrim(scorer{end});

bpartstartix = strfind(cflin,'bodyparts');
bpartendix = strfind(cflin,'start:');
partslabels = {};
pnl = newlines(newlines>bpartstartix & newlines<bpartendix);
for i = 1:length(pnl)-1
    ix=pnl(i):pnl(i+1);
    part = strtrim(cflin(ix));
    if ~contains(part,'-');continue;end
    part = strsplit(part,'-');
    part = strtrim(part{end});
    partslabels = [partslabels {part}];
end

[~,basevidname,~]= fileparts(vid); 
basevidname = ['labeled-data' filesep basevidname];
v = VideoReader(vid);

xy = csvread(csv,1);
if nargin<4
    pts = size(xy,2)/2;
    pts = 1:pts;
end
leadingzeros = ['%0' num2str(floor(log10(length(xy)))+1) 'd'];
labeledix = find(~all(isnan(xy(:,1:2:end)),2));
x = xy(labeledix,1:2:end);
y = xy(labeledix,2:2:end);
x = x(:,pts);
y = y(:,pts);
y = v.Height-y;

partstr = {'bodyparts'};
for i = 1:length(partslabels)
    partstr = [partstr {partslabels(i) partslabels(i)}];
end

outcell = [{'scorer'}, repmat({'MJR'},1,length(pts)*2)];
outcell = [outcell;partstr];
outcell = [outcell; [{'coords'}, repmat([{'x'},{'y'}],1,length(pts))]];

mkdir([dlcdir basevidname])
outfns = {};
for i = 1:length(labeledix)
    outfn = fullfile(basevidname,['img' num2str(labeledix(i)-1,leadingzeros) '.png']);
    outfns{end+1} = outfn;
    outfn = [dlcdir outfn];
    img = read(v,labeledix(i));
    imwrite(img, outfn);
end
outfns = outfns';

outxy = {};
for i = 1:length(pts)
    outxy = [outxy cellstr(num2str(x(:,i))) cellstr(num2str(y(:,i)))];
end
outxy = strrep(outxy,'NaN','');
outcell = [outcell; [outfns outxy]];
outcsvname = [dlcdir fullfile(basevidname,['CollectedData_' scorer '.csv'])];
writetable(cell2table(outcell),outcsvname,'WriteVariableNames',0)

disp('Labeled dataset created. Run "deeplabcut.convertcsv2h5([config_path])" to complete the conversion');
end