execute ibeblock
(
  fn varchar(100) comment 'FileName (write)',
  fn1 varchar(100) comment 'File Name (read)'
)
as
begin
  --fn = 'D:\FileReadWrite\WriteFile.txt'; -- This is the file path we are recording
  --fn1 = 'D:\FileReadWrite\ReadFile.txt'; -- This is the file path we read from
  dn = ibec_ExtractFileDir(fn);
  FL_EXEC = 0;
  LAST_ERROR = '';
  MY_TEXT = '';
  CREATE_FILE = 0;
  -- check Parameters
  if (fn is null or (fn = '')) then
  begin
    ibec_MessageDlg('Invalid file name!!', __mtWarning, __mbOk);
    exit;
  end
  if (dn is null or (dn = ''))then
  begin
    ibec_MessageDlg('Invalid directory!!!', __mtWarning, __mbOk);
    exit;
  end
  if (not ibec_FileExists(:fn1)) then
  begin
    ibec_MessageDlg('File ' || :fn1 || ' does not exist!!!', __mtWarning, __mbYes);
    exit;
  end
  try
    try
      --check for Directory Exist
      if (ibec_DirectoryExists(:dn)) then
        ibec_MessageDlg('Directory exist!', __mtInformation, __mbOk);
      else
      begin
        -- Create Directory
        if (ibec_MessageDlg('Directory ' || :dn || ' does not exist!! Do yo want to create it?', __mtConfirmation, __mbYes + __mbNo) <> __mrYes) then
        begin
          FL_EXEC = 1;
          exit;
        end
        else
          ibec_ForceDirectories(:dn);
          if (ibec_DirectoryExists(:dn)) then
            ibec_MessageDlg('I created Directory!, __mtInformation, __mbOk);
          else
            ibec_MessageDlg('I could not create the directory, the path is inaccessible!', __mtError, __mbOk);
      end
      -- check for File Exist
      if (ibec_FileExists(:fn)) then
      begin
        --ibec_MessageDlg('File exist!', __mtInformation, __mbOk);
        m = ibec_MessageDlg('The specified file ' || :fn || ' exist. Do yo want to reaplace it?', __mtConfirmation, __mbYes +__mbNo);
        if (m = __mrYes) then
        begin
          ibec_DeleteFile(:fn);
          f = ibec_fs_OpenFile(:fn, __fmCreate);
          CREATE_FILE = 1;
          ibec_Progress('Save file....');
          fs = ibec_fs_OpenFile(:fn1, __fmOpenRead);
          while (not ibec_fs_Eof(:fs)) do
          begin
            s = ibec_fs_Readln(:fs);
            MY_TEXT =  :MY_TEXT || :s || ibec_CRLF();
          end
          wf = ibec_fs_WriteString(f, :MY_TEXT);
          wf = :wf || ibec_fs_WriteString(f, 'Save all from old file successful!');
          if (wf > 0 or (wf is not null)) then
          begin
            ibec_MessageDlg('I created the file successful!', __mtInformation, __mbOK);
          end
          else
          begin
            ibec_MessageDlg('I was unable to create the file!', __mtError, __mbOK);
            exception GENERAL_DB_ERROR 'Error creating file';
            FL_EXEC = 1;
            exit;
          end
        end
      end
      else
      begin
        ibec_MessageDlg('File does not exist!', __mtWarning, __mbOk);
        if (ibec_MessageDlg('Do you want create it?', __mtInformation, __mbYes + __mbNo) <> __mrYes) then
        begin
          exit;
        end
        else
          f = ibec_fs_OpenFile(:fn, __fmCreate);
          CREATE_FILE = 1;
          ibec_Progress('Save file....');
          fs = ibec_fs_OpenFile(:fn1, __fmOpenRead);
          while (not ibec_fs_Eof(:fs)) do
          begin
            s = ibec_fs_Readln(:fs);
            MY_TEXT =  :MY_TEXT || s || ibec_CRLF();
          end
          wf = ibec_fs_WriteString(f, :MY_TEXT);
          wf = :wf || ibec_fs_WriteString(f, 'Save all from old file successful !');
          if (wf > 0 or (wf is not null)) then
            ibec_MessageDlg('I created the file successful!', __mtInformation, __mbOK);
      end
  except
    LAST_ERROR = ibec_err_Message();
    if(LAST_ERROR is null) then
      LAST_ERROR = 'unknown exception!!!';
  end
  finally
    ibec_fs_CloseFile(:f);
    ibec_fs_CloseFile(:fs);
    if (FL_EXEC = 1) then
      ibec_MessageDlg(LAST_ERROR, __mtError, __mbOk);
    if (CREATE_FILE = 1) then
    begin
      a = ibec_FileAttr(:fn); -- Type of attributes are: __fa*
      if (a = 32) then
        a = 'Archive';
      else if (a = 63) then
        a = 'Anything';
      else if (a = 16) then
        a = 'Directory';
      else if (a = 2) then
        a = 'Hidden';
      else if (a = 1) then
        a = 'Read only';
      else if (a = 4) then
        a = 'System file';
      else if (a = 8) then
        a = 'Is volume';
      else
        a = 'unknown type';
      dt = ibec_filedateTime(:fn);
      fsize = ibec_FileSize(:fn);
      ibec_MessageDlg(
                      'Result:' || ibec_CRLF() ||
                      'File name: ' || :fn || ibec_CRLF() ||
                      'File Type: ' || :a || ibec_CRLF() ||
                      'Last modified: ' || :dt || ibec_CRLF() ||
                      'File size: ' || :fsize || ' bytes' || ibec_CRLF(),
                        __mtInformation, __mbOk);
       if (ibec_MessageDlg('Do you want to open file?', __mtConfirmation, __mbYes + __mbNo) = __mrYes) then
         ibec_ShellExecute('open', fn, '', '', 1);
    end
  end
end