#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
;Activate case-sensetive string-comparisson
StringCaseSense, Off
files_to_copy := []

Gui Add, Text, x20 y20, File extension:
Gui Add, Edit, x150 y20 w120 h21 Limit3 vDatei_endung
Gui Add, Button, x20 y50 w100 h21 gQuelle_waehlen, Source
Gui Add, Edit, x150 y50 w120 h21 vName_datei_quelle
Gui Add, Button, x20 y80 w100 h21 gZiel_waehlen, Target
Gui Add, Edit, x150 y80 w120 h21 vName_datei_ziel
Gui Add, Radio, x20 y110 vMovefiles Checked, Move files
Gui Add, Radio, x150 y110 vCopyfiles, Copy files
Gui Add, Checkbox, vDoFileTimeMatch x20 y144, Only files created before
Gui Add, Edit, x160 y140 w74 h21 vFileTimeMatch, YYYYMMDD
Gui Add, Checkbox, vOverwrite_existing_files x20 y174, Overwrite existing files
Gui Add, Button, x160 y170 w100 h21 gKopieren vKopierenButton, Start
Gui, Add, GroupBox, x20 y200 w260 h200, Status
Gui Add, Text, x22 y220, Status:
Gui Add, Edit, x60 y216 w210 h21 vKopierenStatus
Gui, Add, Progress, x22 y250 w256 h20 cBlue vMyProgress
Gui, Add, ListView, x22 y280 r6 w256 vFileList, File|

Gui Show, w300 h410, File-Sorter
Return

GuiEscape:
GuiClose:
    ExitApp

Quelle_waehlen:
{
  FileSelectFolder, Name_datei_quelle
  GuiControl,, Name_datei_quelle, %Name_datei_quelle%
  Return
}

Ziel_waehlen:
{
  FileSelectFolder, Name_datei_ziel
  GuiControl,, Name_datei_ziel, %Name_datei_ziel%
  Return
}

Kopieren:
{
  GuiControlGet, Datei_endung
  GuiControlGet, Name_datei_quelle
  GuiControlGet, Name_datei_ziel
  GuiControlGet, Overwrite_existing_files
  GuiControlGet, Copyfiles
  GuiControlGet, Movefiles
  GuiControlGet, DoFileTimeMatch
  GuiControlGet, FileTimeMatch

  ;Checking if variables are set, otherwise there's nothing to do
  If (Datei_endung <> "") AND (Name_datei_ziel <> "") AND (Name_datei_quelle <> "") AND (Name_datei_ziel <> Name_datei_quelle)
  {
    IfExist, %Name_datei_quelle%
    {
      IfExist, %Name_datei_ziel%
      {
        ;fake FileTimeMatch
        if DoFileTimeMatch = 0
        {
          filetimetocompare = 99991231235959
        } else {
          filetimetocompare = %FileTimeMatch%235959
        }
        
        ;List matching files
        Loop %Name_datei_quelle%\*.*
        	{
            StringRight, current_file, A_LoopFileName, 3
            if current_file = %Datei_endung%
            {
              datei=%Name_datei_quelle%\%A_LoopFileName%
              FileGetTime, filetime, %datei%, C
              if filetime < %filetimetocompare%
              {
                ArrayCount += 1
                files_to_copy[ArrayCount] :=  A_LoopFileName
                FileGetSize, current_size, %datei%, K
                all_sizes += %current_size%
              }
            }
          }

        ;Are there matching files?
        if ArrayCount >= 1
        {
          ;Fake progress-activity to enable multiple runs
          GuiControl,, MyProgress, 1

          ;calculate displayed file sizes
          all_sizes_type = KB
          if all_sizes > 1024
          {
            all_sizes := all_sizes/1024
            all_sizes := Floor(all_sizes)
            all_sizes_type = MB
          }

          if all_sizes > 1024
          {
            all_sizes := all_sizes/1024
            all_sizes := Round(all_sizes,2)
            all_sizes_type = GB
          }
          ;calculating single progressbar-jump
          ProgressBarJump := Floor(260/ArrayCount)

          if Movefiles = 1
          {
            doing = Moving
            done = Moved
          } else {
            doing = Copying
            done = Copied
          }

          GuiControl, Disable, KopierenButton
          KopierenStatusValue = %doing% %ArrayCount% files (%all_sizes% %all_sizes_type%)...
          GuiControl,, KopierenStatus, %KopierenStatusValue%

          hochlaeufer := 0
          Loop % ArrayCount
          {
            datei := files_to_copy[A_Index]
            LV_Add("", datei)
            LV_Modify(hochlaeufer, "Vis")
            if Movefiles = 1
            {
              FileMove, %Name_datei_quelle%\%datei%, %Name_datei_ziel%, %Overwrite_existing_files%
              ErrorCount += ErrorLevel
            } else {
              FileCopy, %Name_datei_quelle%\%datei%, %Name_datei_ziel%, %Overwrite_existing_files%
              ErrorCount += ErrorLevel
            }
            GuiControl,, MyProgress, +%ProgressBarJump%
            hochlaeufer += 1
          }
          GuiControl, Enable, KopierenButton

          ;No ErrorLevel when overwriting is enabled
          If ErrorCount <> 0
          {
            error_msg = %ErrorCount% with problems!
          }
          KopierenStatusValue = %done% %ArrayCount% files (%all_sizes% %all_sizes_type%)! %error_msg%
          GuiControl,, KopierenStatus, %KopierenStatusValue%
          ArrayCount =
          error_msg =
          ErrorCount =
          Return

        } else {
          MsgBox, No matching files found!!
        }
      }
  }
  } else {
    MsgBox, 32, File Sorter, Insufficient information!
    Return
  }
}
