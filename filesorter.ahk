#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
;Activate case-sensetive string-comparisson
StringCaseSense, On
files_to_copy := []

Gui Add, Text, x20 y20, File extension:
Gui Add, Edit, x150 y20 w120 h21 Limit3 vDatei_endung
Gui Add, Button, x20 y50 w100 h21 gQuelle_waehlen, Source
Gui Add, Edit, x150 y50 w120 h21 vName_datei_quelle
Gui Add, Button, x20 y80 w100 h21 gZiel_waehlen, Target
Gui Add, Edit, x150 y80 w120 h21 vName_datei_ziel
Gui Add, Radio, x20 y110 vMovefiles Checked, Move files
Gui Add, Radio, x150 y110 vCopyfiles, Copy files
Gui Add, Checkbox, vOverwrite_existing_files x20 y144, Overwrite existing files
Gui Add, Button, x160 y140 w100 h21 gKopieren vKopierenButton, Start
Gui Add, Text, x20 y180, Status:
Gui Add, Edit, x60 y176 w210 h21 vKopierenStatus
Gui, Add, Progress, x20 y220 w260 h20 cBlue vMyProgress

Gui Show, w300 h260, File-Sorter
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


  ;Wir machen hier natürlich nur etwas, wenn die benötigten Variablen auch gefüllt sind.
  If (Datei_endung <> "") AND (Name_datei_ziel <> "") AND (Name_datei_quelle <> "") AND (Name_datei_ziel <> Name_datei_quelle)
  {
    IfExist, %Name_datei_quelle%
    {
      IfExist, %Name_datei_ziel%
      {
        ;Passende Dateien suchen!
        Loop %Name_datei_quelle%\*.*
        	{
            StringRight, current_file, A_LoopFileName, 3
            if current_file = %Datei_endung%
            {
              ArrayCount += 1
              files_to_copy[ArrayCount] :=  A_LoopFileName
              datei=%Name_datei_quelle%\%A_LoopFileName%
              FileGetSize, current_size, %datei%, K
              all_sizes += %current_size%
            }
          }

        ;Gibt es überhaupt Dateien?
        if ArrayCount >= 1
        {
          ;Fake ProgressBar-Set um bei mehrfacher Ausführung einen Neustart der ProgressBar zu haben
          GuiControl,, MyProgress, 10

          ;Berechnung angezeigte Dateigröße
          all_sizes_type = KB
          if all_sizes > 1024
          {
            all_sizes := all_sizes/1024
            all_sizes := Floor(all_sizes)
            all_sizes_type = MB
          }

          ;Berechnung ProgressBar-Loop-Dateigröße
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

          hochlaeufer := 1
          Loop % ArrayCount
          {
            datei := files_to_copy[A_Index]
            if Movefiles = 1
            {
              FileMove, %Name_datei_quelle%\%datei%, %Name_datei_ziel%, %Overwrite_existing_files%
              ErrorCount += ErrorLevel
            } else {
              FileCopy, %Name_datei_quelle%\%datei%, %Name_datei_ziel%, %Overwrite_existing_files%
              ErrorCount += ErrorLevel
            }
            GuiControl,, MyProgress, +%ProgressBarJump%
          }
          GuiControl, Enable, KopierenButton
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
