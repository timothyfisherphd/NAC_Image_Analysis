function saveEditor(filename)
% function saveEditor(filename):
% This function creates a .m file named "filename". When running this .m
% file all .m files open in the editor at creation of the file will be
% opened and others clossed.
    %% define some symbols
    NL = char(13); % new line character
    SC = char(39); % matlab string character (')
    %% add dir to file name if ness
    if size(findstr(filename,':'))==0
        filename = [pwd '\' filename];
    end
    %% check valid extentions
        dotPos = strfind(filename,'.');
        if ~isempty(dotPos)
            if ~strcmp(filename(dotPos+1:end),'m')
                filename = [filename(1:dotPos) 'm'];
            end
        else
            filename = [filename '.m'];
        end
    %% find current m-files in editor
    OpenFiles = com.mathworks.mde.desk.MLDesktop.getInstance.getWindowRegistry.getClosers.toArray.cell;
    OpenFiles = cellfun(@(c)c.getTitle.char,OpenFiles,'un',0);
    C = cell(1, numel(OpenFiles));
    %% make text
    mfile = ['% File created on ' datestr(now,'dd/mm/yyyy HH:MM:SS') ', by saveEditor.m' NL...
             NL...
             '% close all other m-files' NL...
             'Editor = com.mathworks.mlservices.MLEditorServices;' NL...
             'Editor.getEditorApplication.close;' NL...
             '% load m-files' NL];
    for i = 1:length(C)
        mfile = [mfile...
         'try '...
         'open(' SC char(OpenFiles(i)) SC ');'...
         'catch e;'...
         'disp(e.message);'...
         'end' NL];
    end
    mfile = [mfile...
     'try '...
     'open(' SC filename SC ');'...
     'catch e;'...
     'disp(e.message);'...
     'end' NL];
    %% write to m-file
        % open or create
        fid = fopen(filename,'w+');
        fwrite(fid,mfile);
        fclose(fid);
        % open created file
        open(filename)
end
