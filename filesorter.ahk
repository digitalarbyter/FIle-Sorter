#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
;Activate case-sensetive string-comparisson
StringCaseSense, On
files_to_copy := []

Gui Add, Text, x20 y20, Datei-Endung:
Gui Add, Edit, x150 y20 w120 h21 Limit3 vDatei_endung
Gui Add, Button, x20 y50 w100 h21 gQuelle_waehlen, Quelle waehlen
Gui Add, Edit, x150 y50 w120 h21 vName_datei_quelle
Gui Add, Button, x20 y80 w100 h21 gZiel_waehlen, Ziel waehlen
Gui Add, Edit, x150 y80 w120 h21 vName_datei_ziel
Gui Add, Checkbox, vOverwrite_existing_files x20 y114, Overwrite existing files
Gui Add, Button, x160 y110 w100 h21 gKopieren vKopierenButton, Dateien kopieren
Gui Add, Text, x20 y150, Status:
Gui Add, Edit, x90 y150 w150 h21 vKopierenStatus

Gui Show, w300 h190, File-Sorter
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
            }
          }

        ;Gibt es überhaupt Dateien?
        if ArrayCount >= 1
        {
          GuiControl, Disable, KopierenButton
          KopierenStatusValue = Kopiere %ArrayCount% Dateien...
          GuiControl,, KopierenStatus, %KopierenStatusValue%

          hochlaeufer := 1
          Loop % ArrayCount
          {
            datei := files_to_copy[A_Index]
            FileMove, %Name_datei_quelle%\%datei%, %Name_datei_ziel%, %Overwrite_existing_files%
          }
          GuiControl, Enable, KopierenButton
          KopierenStatusValue = Es wurden %ArrayCount% Dateien kopiert!
          GuiControl,, KopierenStatus, %KopierenStatusValue%
          ArrayCount =
          Return

        } else {
          MsgBox, Es wurden keine passenden Dateien gefunden!
        }
      }
  }
  } else {
    MsgBox, 32, File Sorter, Unvollstaendige Angaben!
    Return
  }
}
