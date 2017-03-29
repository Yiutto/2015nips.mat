%% Parse HTML
% This script parses 'accepted_papers.html' 

%% Extract List of Papers
% chop off the top and bottom of the page that contain no useful info

pattern = '<div><div><h3>NIPS 2015 Accepted Papers</h3><p><br></p>';    % start of the list
cur = strfind(html,pattern);                                            % find its starting index
html(1:cur+length(pattern)) = [];                                       % delete unwanted text
pattern = '<!--END BLOCK CONTENT-->';                                   % end of the list
cur = strfind(html,pattern);                                            % find its starting index
html(cur:end) = [];                                                     % delete unwanted text

%% Extract List Item
% all the entries are listed with the same starting tags, so you can use
% the those tags to separate them

pattern = '<i><span class="larger-font">';                              % start of list item 
cur = strfind(html,pattern);                                            % find its starting indices
entries = cell(length(cur),1);                                          % set up accumulator
titles = cell(length(cur),1);                                           % set up accumulator
for i = 1:length(cur)-1                                                 % loop over starting indices
        entries{i} = html(cur(i):cur(i+1)-1);                           % extract list item
end
entries{end} = html(cur(length(cur)):end);                              % last list item

%% Separate Titles and Names
% get red of the unwanted start tags, and then split the entry into title
% and names by the tags that follows the title. 

entries = regexprep(entries,pattern,'');                                % delete unwanted start tags
pattern = '</span></i><br><b>';                                         % unwanted ending tags
cur = strfind(entries,pattern);                                         % find its starting indices
for i = 1:length(titles)                                                % loop over starting indices
    titles{i} = entries{i}(1:cur{i}-1);                                 % extract title
    pattern = regexptranslate('escape', titles{i});                     % use escaped title as pattern
    entries{i} = regexprep(entries{i},pattern,'');                      % delete title and keep names
end

%% Delete Unwanted HTML Tags
% do more clean-up

pattern = '</span></i><br><b>\n';                                       % unwanted html tags + LF char
entries = regexprep(entries,pattern,'');                                % delete unwanted html tags
pattern = '</b><br><br>';                                               % unwanted html tags
entries = regexprep(entries,pattern,'');                                % delete unwanted html tags
pattern = '</b><span><strong>';                                         % unwanted html tags
entries = regexprep(entries,pattern,'');                                % delete unwanted html tags
pattern = '</strong></span><b>';                                        % unwanted html tags
entries = regexprep(entries,pattern,';');                               % replace unwatend html tag
entries = regexprep(entries,'&amp;','&');                               % replace encoded character
entries = regexprep(entries,char(160),'');                              % delete unwanted character
entries = regexprep(entries,char(194),'');                              % delete unwanted character
pattern = '</div><p>';                                                  % unwanted ending tags
cur = strfind(entries{end},pattern);                                    % find its starting indices
entries{end}(cur:end) = [];                                             % delete unwanted ending tags

%% Keep Track of Coauthors
% names are separated by semicolons, and each entry has variable number of
% coauthors. Let's keep the count of coauthors by giving coauthors the same
% entry id.

entries = regexp(entries,';','split');                                  % split names by semicolon
num_coauthors = cellfun(@length, entries);                              % number of coauthors
entry_ids = zeros(sum(num_coauthors),1);                                % set up accumulator
last_row = 0;                                                           % set up counter
for i = 1:length(num_coauthors)                                         % loop over number of coauthors
    start_row = last_row + 1;                                           % start with the next row below the last
    last_row = last_row + num_coauthors(i);                             % set last row to number of coauthors 
    entry_ids(start_row:last_row) = i;                                  % add the entry id
end

%% Separate Names and Organizations
% each name is followed by organization the named author is affiliated
% with. The name and organization is separated by comma. 
% Some entries only list organizations but authors, and some authors don't
% have organization. Deal with some of those irregularities

namesorgs = regexp([entries{:}]',',','split','once');                   % split names and orgs by comma
namesorgs = cellfun(@strtrim,namesorgs,'UniformOutput',false);          % remove extra white space
has2cols = cellfun(@length, namesorgs) == 2;                            % do all rows have 2 cols?
names = cell(size(namesorgs));                                          % set up accumulator
orgs = cell(size(namesorgs));                                           % set up accumulator
orgs(has2cols) = cellfun(@(x) x{2}, namesorgs(has2cols), ...            % the second col contains org
 'UniformOutput',false);
orgs(~has2cols) = cellfun(@(x) x{1}, namesorgs(~has2cols), ...          % first col contains org if only 1 col
    'UniformOutput',false);
names(has2cols) = cellfun(@(x) x{1}, namesorgs(has2cols), ...           % the first col contains name
    'UniformOutput',false);
names(~has2cols) = {'UNK'};                                             % remove orgs from names
names = regexprep(names, '\s{2,}',' ');                                 % remove extra white space
hasstar = strfind(names, '*');                                          % some names have stars
hasstar = ~cellfun(@isempty, hasstar);                                  % create a new indicator variable
names = regexprep(names,'*','');                                        % remove stars
orgs = strrep(orgs,'"','');                                             % remove double quotes
orgs = strrep(orgs,'The ','');                                          % remove 'The'
orgs = strrep(orgs,'Dr.','UC Irvine');                                  % replace salutation
orgs = strrep(orgs,'.','');                                             % remove period
orgs = strrep(orgs,',',' ');                                            % remove comma
orgs = strrep(orgs,'  ',' ');                                           % remove dboule space
orgs = regexprep(orgs,'^University of','U');                            % shorten 'University'
orgs = categorical(orgs);                                               % convert to categorical
cats = categories(orgs);                                                % get categories

%% Normalize Org Names
% standarddize the organization names. This is a manual process. 

orgs = mergecats(orgs,cats([47,1,118]));                                % EPFL
orgs = mergecats(orgs,cats(3:5));                                       % Adobe
orgs = mergecats(orgs,cats([234,6]));                                   % Alberta
orgs = mergecats(orgs,cats([10,9]));                                    % Australian
orgs = mergecats(orgs,cats([13,197]));                                  % BU
orgs = mergecats(orgs,cats([18,24,25]));                                % CMU
orgs = mergecats(orgs,cats([22,23,243,361]));                           % Cambridge
orgs = mergecats(orgs,cats(27:29));                                     % Chalmers
orgs = mergecats(orgs,cats([32:33,245]));                               % Columbia
orgs = mergecats(orgs,cats(34:35));                                     % Cornell
orgs = mergecats(orgs,cats(36:39));                                     % Courant
orgs = mergecats(orgs,cats(42:44));                                     % Duke
orgs = mergecats(orgs,cats([45,17,46,51,52,60,68,119]));                % ENS
orgs = mergecats(orgs,cats(48:50));                                     % ETH
orgs = mergecats(orgs,cats(56:58));                                     % Facebook
orgs = mergecats(orgs,cats(61:63));                                     % Gatsby
orgs = mergecats(orgs,cats([66,64,65,67]));                             % Georgia
orgs = mergecats(orgs,cats([69,40,70:72,359]));                         % Google
orgs = mergecats(orgs,cats([75,81]));                                   % HKUST
orgs = mergecats(orgs,cats(76:78));                                     % Harvard
orgs = mergecats(orgs,cats(83:87));                                     % IBM
orgs = mergecats(orgs,cats([90,91,99]));                                % IIT
orgs = mergecats(orgs,cats([92:96,100,177]));                           % INRIA
orgs = mergecats(orgs,cats([97,105]));                                  % IST Austria
orgs = mergecats(orgs,cats(108:109));                                   % Johannes
orgs = mergecats(orgs,cats(110:111));                                   % Johns Hopkins
orgs = mergecats(orgs,cats(115:116));                                   % KU Leuven
orgs = mergecats(orgs,cats([120:123,137,138,153]));                     % MIT
orgs = mergecats(orgs,cats([144,124,132,133,145:151]));                 % Microsoft
orgs = mergecats(orgs,cats([125:130,139:141]));                         % MPI
orgs = mergecats(orgs,cats([131,152]));                                 % MRN
orgs = mergecats(orgs,cats([142:143,259]));                             % McGill
orgs = mergecats(orgs,cats([157,168]));                                 % NTT
orgs = mergecats(orgs,cats([160,167]));                                 % NYU
orgs = mergecats(orgs,cats([173:174,267]));                             % Oxford
orgs = mergecats(orgs,cats([175,181]));                                 % POSTECH
orgs = mergecats(orgs,cats([180,363]));                                 % Polytechnique Montreal
orgs = mergecats(orgs,cats(182:185));                                   % Princeton
orgs = mergecats(orgs,cats([191,189,192]));                             % RPI
orgs = mergecats(orgs,cats([195,194,196]));                             % Rutgers
orgs = mergecats(orgs,cats(198:199));                                   % Saarland
orgs = mergecats(orgs,cats([208:211,362]));                             % Stanford
orgs = mergecats(orgs,cats([215,214]));                                 % Syracuse
orgs = mergecats(orgs,cats([216,225,229,231]));                         % TTI Chicago
orgs = mergecats(orgs,cats(223:224));                                   % Technion
orgs = mergecats(orgs,cats([226:228,102,232]));                         % Telecom ParisTech
orgs = mergecats(orgs,cats([296,238]));                                 % UBC
orgs = mergecats(orgs,cats([297,239,298]));                             % UC Berkeley
orgs = mergecats(orgs,cats(240:241));                                   % UC Davis
orgs = mergecats(orgs,cats([307,242,301,324]));                         % UCSD
orgs = mergecats(orgs,cats([308,253]));                                 % UIUC
orgs = mergecats(orgs,cats([255,254]));                                 % UIC
orgs = mergecats(orgs,cats([309,260:262,325]));                         % U Michigan
orgs = mergecats(orgs,cats([263,264,312]));                             % U Minnesota
orgs = mergecats(orgs,cats([265,327:329,336]));                         % U Montreal
orgs = mergecats(orgs,cats([314,268]));                                 % UPenn
orgs = mergecats(orgs,cats(272:273));                                   % U Southampton
orgs = mergecats(orgs,cats([319,275:276]));                             % UTS
orgs = mergecats(orgs,cats([278:280,316:318,320,339]));                 % U Texas
orgs = mergecats(orgs,cats([283,16,285,321]));                          % U Tuebingen
orgs = mergecats(orgs,cats([287,288,333,342]));                         % U Washington
orgs = mergecats(orgs,cats([289:293,322:323,350]));                     % U Wisconsin
orgs = mergecats(orgs,cats([299,303]));                                 % UC Irvine
orgs = mergecats(orgs,cats([304,331,332]));                             % UCL
orgs = mergecats(orgs,cats([310,311]));                                 % UNC Chapel Hill
orgs = mergecats(orgs,cats(343:346));                                   % Washington Univ in St Louis
orgs = mergecats(orgs,cats(347:349));                                   % Weizmann Institute
orgs = mergecats(orgs,cats([355,353,354]));                             % Yahoo!
orgs = mergecats(orgs,cats(356:357));                                   % Yale
orgs = renamecats(orgs,cats{31},'CSM');                                 % rename category
orgs = renamecats(orgs,cats{90},'IIT');                                 % rename category
orgs = renamecats(orgs,cats{125},'MPI');                                % rename category
orgs = renamecats(orgs,cats{180},'Polytechnique Montreal');             % rename category
orgs = renamecats(orgs,cats{240},'UC Davis');                           % rename category
orgs = renamecats(orgs,cats{255},'UIC');                                % rename category
orgs = renamecats(orgs,cats{295},'U Aveiro');                           % rename category
orgs = renamecats(orgs,cats{334},'U Paris Dauphine');                   % rename category
orgs = renamecats(orgs,cats{335},'UPMC');                               % rename category
orgs = renamecats(orgs,cats{337},'U Saint-Etienne');                    % rename category
orgs = renamecats(orgs,cats{343},'WUSTL');                              % Washington Univ in St Louis
orgs = reordercats(orgs);                                               % reorder categories
cats = categories(orgs);                                                % get categories

%% Fill Missing by Prev Coauthor's Org
% When an author doesn't have affiliation, let's assume that it is the same
% as the author listed before. 

missingOrgIdx = find(isundefined(orgs));                                % get missing idx 
prevIdx = missingOrgIdx - 1;                                            % get prev idx
prevOrgs = orgs(prevIdx);                                               % get prev org
isCoauthors = (entry_ids(missingOrgIdx) - entry_ids(prevIdx) == 0);     % are they coauhtors?
orgs(missingOrgIdx(isCoauthors)) = prevOrgs(isCoauthors);               % use prev org if so

%% Fill Missing by Next Coauthor's Org
% When an author still doesn't have affiliation, let's assume that it is 
% the same as the author listed after.

missingOrgIdx = find(isundefined(orgs));                                % get missing idx 
nextIdx = missingOrgIdx + 1;                                            % get next idx
nextOrgs = orgs(nextIdx);                                               % get next org
isCoauthors = (entry_ids(missingOrgIdx) - entry_ids(nextIdx) == 0);     % are they coauhtors?
orgs(missingOrgIdx(isCoauthors)) = nextOrgs(isCoauthors);               % use next org if so

%% Fill Missing by First Coauthor's Org
% When an author still doesn't have affiliation, let's assume that it is 
% the same as the first author listed.

missingOrgIdx = find(isundefined(orgs));                                % get missing idx 
coauthorIdx = find(ismember(entry_ids,entry_ids(missingOrgIdx)));       % get coauthor idx
for i = 1:length(missingOrgIdx)                                         % loop over missing idx
    orgs(missingOrgIdx(i)) = orgs(coauthorIdx(...                       % get org of coauthor
        find(coauthorIdx < missingOrgIdx(i),1)));                       % listed first
end

%% Merge Data by Full Name
% Let's find auhor IDs by comparing names

T1 = table(names,'VariableNames',{'Name'});                             % convert to table
T2 = Authors;                                                           % make a working copy
[tmp,idx,~] = innerjoin(T1,T2);                                         % find common data
T1.ID = zeros(height(T1),1);                                            % add ID col to T1
T1.ID(idx) = tmp.ID;                                                    % populate common IDs

%% Split Name into First and Last
% We couldn't match everybody, so let's split names into first and last
% names.

firstlast = cellfun(@strsplit,T1.Name,'UniformOutput', false);          % split names
len = cellfun(@length, firstlast);                                      % get length
isNotName = len < 2;                                                    % not names
T1.FirstName = cellfun(@(x) x{1}, firstlast,'UniformOutput', false);    % add first names
T1.LastName = cellfun(@(x) x{end}, firstlast,'UniformOutput', false);   % add last names
T1.FirstName(isNotName) = {''};                                         % drop non names
T1.LastName(isNotName) = {''};                                          % drop non names
firstlast = cellfun(@strsplit,T2.Name,'UniformOutput', false);          % split names
T2.FirstName = cellfun(@(x) x{1}, firstlast,'UniformOutput', false);    % add first names
T2.LastName = cellfun(@(x) x{end}, firstlast,'UniformOutput', false);   % add last names

%% Merge Data by Last Name
% Now let's match the unmatched names by last name. 

missingIdx = find(T1.ID == 0 & ~isNotName);                             % get missing indices
missingNames = T1.LastName(missingIdx);                                 % get missing names
matchedIdx = cell(length(missingNames),1);                              % set up accumulator
for i = 1:length(missingNames)                                          % loop over missing names
    matchedIdx{i} = find(strcmpi(T2.LastName,missingNames(i)));         % find matches
    if length(matchedIdx{i}) == 1                                       % if match is unique
        T1.ID(missingIdx(i)) = T2.ID(matchedIdx{i}(1));                 % update the ID
    end
end
missingIdx(cellfun(@length,matchedIdx) == 1) = [];                      % remove mmatched
matchedIdx(cellfun(@length,matchedIdx) == 1) = [];                      % remove matched

%% Merge Data by First Name
% Now let's match the unmatched names by first name. 

missingNames = T1.FirstName(missingIdx);                                % get missing names
matchedFirstIdx = cell(length(missingNames),1);                         % set up accumulator
for i = 1:length(missingNames)                                          % loop over missing names
    matchedFirstIdx{i} = matchedIdx{i}(...                              % among last name matches
        strcmpi(T2.FirstName(matchedIdx{i}),missingNames{i}));          % find first name matches
    if length(matchedFirstIdx{i}) == 1                                  % if match is unique
       T1.ID(missingIdx(i)) = T2.ID(matchedFirstIdx{i}(1));             % update the ID
    end
end
missingIdx(cellfun(@length,matchedFirstIdx) == 1) = [];                 % remove mmatched

%% Merge Data by Last Name as Substring
% Now let's match the unmatched names by last name as substring to deal
% with hyphenated names or middle names. 

unmatchedIdx = find(~ismember(T2.ID,T1.ID(T1.ID ~= 0)));                % get unmatched indices
unmatchedNames = T2.Name(unmatchedIdx);                                 % get unmatched names
missingNames = T1.LastName(missingIdx);                                 % get missing names
matchedSubstrIdx = cell(length(missingNames),1);                        % set up accumulator
for i = 1:length(missingNames)                                          % loop over missing names
    matchedSubstrIdx {i} = unmatchedIdx(~cellfun(@isempty, ...          % among unmatched names 
        strfind(unmatchedNames,missingNames{i})));                      % find last names as substring
    if length(matchedSubstrIdx{i}) == 1                                 % if match is unique
        T1.ID(missingIdx(i)) = T2.ID(matchedSubstrIdx{i}(1));           % update the ID
    end
end
missingIdx(cellfun(@length,matchedSubstrIdx) == 1) = [];                % remove mmatched

%% Merge Data by First Name as Substring
% Now let's match the unmatched names by first name as substring to deal
% with hyphenated names or middle names. 

unmatchedIdx = find(~ismember(T2.ID,T1.ID(T1.ID ~= 0)));                % get unmatched indices
unmatchedNames = T2.Name(unmatchedIdx);                                 % get unmatched names
missingNames = T1.FirstName(missingIdx);                                % get missing names

matchedSubstrIdx = cell(length(missingNames),1);                        % set up accumulator
for i = 1:length(missingNames)                                          % loop over missing names
    matchedSubstrIdx {i} = unmatchedIdx(~cellfun(@isempty, ...          % among unmatched names
        strfind(unmatchedNames,missingNames{i})));                      % find first name as substring
    if length(matchedSubstrIdx{i}) == 1                                 % if match is unique
        T1.ID(missingIdx(i)) = T2.ID(matchedSubstrIdx{i}(1));           % update the ID
    end
end
missingIdx(cellfun(@length,matchedSubstrIdx) == 1) = [];                % remove mmatched

%% Merge Data Manually
% There are a few more unmatched names. Let's match them manually. 

unmatchedIdx = find(~ismember(T2.ID,T1.ID(T1.ID ~= 0)));                % get unmatched indices
unmatchedNames = T2.Name(unmatchedIdx);                                 % get unmatched names
missingNames = T1.Name(missingIdx);                                     % get missing names
T1.ID(missingIdx(1)) = T2.ID(unmatchedIdx(17));                         % manual match
T1.ID(missingIdx(2)) = T2.ID(unmatchedIdx(10));                         % manual match
T1.ID(missingIdx(3)) = T2.ID(unmatchedIdx(10));                         % manual match
T1.ID(missingIdx(4)) = T2.ID(unmatchedIdx(26));                         % manual match
T1.ID(missingIdx(5)) = T2.ID(unmatchedIdx(5));                          % manual match

%% Fill Remaining Unmatched with Fake ID
%  There are names that are not in the database provided. Give them fake
%  IDs.

missingIdx = find(T1.ID == 0);                                          % get missing indices
minIdx = min(T1.ID(T1.ID ~= 0));                                        % get lowest index
for i = 1:length(missingIdx)                                            % loop over missing indices
    if i < minIdx
        T1.ID(missingIdx(i)) = i;
    end
end

%% Merge Data by Paper Title
% Let's find paper IDs by comparing titles

T3 = table(titles,'VariableNames',{'Title'});                           % convert to table
T4 = Papers;                                                            % make a working copy
[tmp,idx,~] = innerjoin(T3,T4);                                         % find common data
T3.ID = zeros(height(T3),1);                                            % add ID col to T3
T3.ID(idx) = tmp.ID;                                                    % populate common IDs

%% Merge Data by the First Word in Titles
% We couldn't match every title, so let's try it with the first word in the
% title

split_titles = cellfun(@strsplit,T3.Title,'UniformOutput',false);       % split titles
missingIdx = find(T3.ID == 0);                                          % get missing indices
missingTitles = split_titles(missingIdx);                               % get missing titles
unmatchedIdx = find(~ismember(T4.ID,T3.ID(T3.ID ~= 0)));                % get unmatched indices
unmatchedTitles = T4.Title(unmatchedIdx);                               % get unmatched titles
matchedIdx = cell(length(missingTitles),1);                             % set up accumulator
for i = 1:length(missingTitles)                                         % loop over missing titles
    startIdx = strfind(unmatchedTitles,missingTitles{i}{1});            % get starting indices of substring
    startIdx(cellfun(@length,startIdx) > 1) = {0};                      % if multiple matches, ignore
    startIdx(cellfun(@isempty,startIdx)) = {0};                         % if no match, ignore
    matchedIdx{i} = unmatchedIdx(cell2mat(startIdx) == 1);              % use if it starts with 1
    if length(matchedIdx{i}) == 1                                       % if match is unique
        T3.ID(missingIdx(i)) = T4.ID(matchedIdx{i});                    % update the ID
    end
end

%% Merge Data by the First Two Words in Titles
% How about the first two words in the title

missingIdx(cellfun(@length, matchedIdx) == 1) = [];                     % remove mmatched
missingTitles = split_titles(missingIdx);                               % get missing titles
unmatchedIdx = find(~ismember(T4.ID,T3.ID(T3.ID ~= 0)));                % get unmatched indices
unmatchedTitles = T4.Title(unmatchedIdx);                               % get unmatched titles
matchedIdx = cell(length(missingTitles),1);                             % set up accumulator
for i = 1:length(missingTitles)                                         % loop over missing titles
    pattern = strjoin(missingTitles{i}(1:2));                           % use first two words
    startIdx = strfind(unmatchedTitles, pattern);                       % get starting indices of substring
    startIdx(cellfun(@length,startIdx) > 1) = {0};                      % if multiple matches, ignore
    startIdx(cellfun(@isempty,startIdx)) = {0};                         % if no match, ignore
    matchedIdx{i} = unmatchedIdx(cell2mat(startIdx)>= 1);               % use if it starts 1 or later
    if length(matchedIdx{i}) == 1                                       % if match is unique
        T3.ID(missingIdx(i)) = T4.ID(matchedIdx{i});                    % update the ID
    end
end

%% Merge Data By Overlap of Words in Titles
% We still have some titles unmatched. Let's match by overlap of multiple
% words

stopwords = {'a','an','and','for','in','of','on','to','via','with'};    % stopwords
missingIdx(cellfun(@length, matchedIdx) == 1) = [];                     % remove mmatched
missingTitles = split_titles(missingIdx);                               % get missing titles
unmatchedIdx = find(~ismember(T4.ID,T3.ID(T3.ID ~= 0)));                % get unmatched indices
unmatchedTitles = ...                                                   % get unmatched titles
    cellfun(@strsplit,T4.Title(unmatchedIdx),'UniformOutput',false);    % split titles
matchedIdx = zeros(length(missingTitles),1);                            % set up accumulator
for i = 1:length(missingTitles)                                         % loop over missing titles
    cur = lower(missingTitles{i});                                      % current missing title
    cur(ismember(cur,stopwords)) = [];                                  % remove stopwords
    max_match = zeros(1,2);                                             % initialize counter
    for j = 1:length(unmatchedTitles)                                   % loop over unmatched titles
        overlap = sum(ismember(lower(unmatchedTitles{j}),cur));         % get overlap of words
        if overlap > max_match(2);                                      % if more words overlap
            max_match(1) = j;                                           % get the current index
            max_match(2) = overlap;                                     % update the max
        end
    end
    if max_match(1) ~= 0                                                % if overlap found
        matchedIdx(i) = unmatchedIdx(max_match(1));                     % use the index as match
    end
end
[uniq_matchedIdx,ia,ib] = unique(matchedIdx);                           % get unique matched idices
count = accumarray(ib,1);                                               % get count of indices
uniq_matchedIdx(count > 1 | uniq_matchedIdx == 0) = [];                 % remove if more than 1 or none
matchedIdx(~ismember(matchedIdx,uniq_matchedIdx)) = 0;                  % remove from matched idx as well
T3.ID(missingIdx(matchedIdx ~=0)) = T4.ID(matchedIdx(matchedIdx ~=0));  % update the IDs

%% Merge Data Manually
% Apparently some papers have completely different titles - so let's match
% them manually

missingIdx = find(T3.ID == 0);                                          % get missing indices
missingTitles = titles(missingIdx);                                     % get missing titles
unmatchedIdx = find(~ismember(T4.ID,T3.ID(T3.ID ~= 0)));                % get unmatched indices
unmatchedTitles = T4.Title(unmatchedIdx);                               % get unmatched titles
matchedIdx = zeros(length(missingTitles),1);                            % set up accumulator
matchedIdx(1) = unmatchedIdx(8);                                        % manual match
matchedIdx(2) = unmatchedIdx(2);                                        % manual match
matchedIdx(3) = unmatchedIdx(1);                                        % manual match
matchedIdx(4) = unmatchedIdx(4);                                        % manual match
matchedIdx(5) = unmatchedIdx(3);                                        % manual match
matchedIdx(6) = unmatchedIdx(9);                                        % manual match
matchedIdx(7) = unmatchedIdx(7);                                        % manual match
matchedIdx(8) = unmatchedIdx(5);                                        % manual match
matchedIdx(9) = unmatchedIdx(6);                                        % manual match
T3.ID(missingIdx) = T4.ID(matchedIdx);                                  % update the IDs

%% Clean Up
% Now let's put everything together as a table

AcceptedPapers = T1(:,1:2);                                             % keep author name and id
AcceptedPapers.Star = hasstar;                                          % add star indicator
AcceptedPapers.Org = orgs;                                              % add org
AcceptedPapers.PaperID = T3.ID(entry_ids);                              % add paper id
AcceptedPapers.Title = titles(entry_ids);                               % add title

clearvars -except AcceptedPapers Authors PaperAuthors Papers            % clear unwanted vars
