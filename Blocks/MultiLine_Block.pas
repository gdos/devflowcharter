{  
   Copyright (C) 2006 The devFlowcharter project.
   The initial author of this file is Michal Domagala.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
}



unit MultiLine_Block;

interface

uses
   Vcl.Controls, Vcl.StdCtrls, Vcl.Graphics, System.Classes, Vcl.ComCtrls, Base_Block,
   CommonInterfaces, StatementMemo, MemoEx;

type

   TMultiLineBlock = class(TBlock)
      public
         FStatements: TStatementMemo;
         function GetTextControl: TCustomEdit; override;
         function GetMemoEx: TMemoEx; override;
         procedure UpdateEditor(AEdit: TCustomEdit); override;
         function GenerateTree(AParentNode: TTreeNode): TTreeNode; override;
         function GenerateCode(ALines: TStringList; const ALangId: string; ADeep: integer; AFromLine: integer = LAST_LINE): integer; override;
      protected
         FErrLine: integer;
         constructor Create(ABranch: TBranch; ALeft, ATop, AWidth, AHeight: integer; AId: integer = ID_INVALID); overload; virtual;
         procedure Paint; override;
         procedure OnDblClickMemo(Sender: TObject);
         procedure MyOnCanResize(Sender: TObject; var NewWidth, NewHeight: Integer; var Resize: Boolean); override;
         procedure OnMouseDownMemo(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
         procedure OnKeyUpMemo(Sender: TObject; var Key: Word; Shift: TShiftState);
   end;

implementation

uses
{$IFDEF USE_CODEFOLDING}
   SynEditCodeFolding,
{$ENDIF}
   System.SysUtils, WinApi.Windows, System.Types, ApplicationCommon, CommonTypes, LangDefinition;

constructor TMultiLineBlock.Create(ABranch: TBranch; ALeft, ATop, AWidth, AHeight: integer; AId: integer = ID_INVALID);
begin

   inherited Create(ABranch, ALeft, ATop, AWidth, AHeight, AId);

   FStatements := TStatementMemo.Create(Self);
   FStatements.Parent := Self;
   FStatements.SetBounds(0, 0, AWidth, Height-31);
   FStatements.Font.Assign(Font);
   FStatements.OnDblClick := OnDblClickMemo;
   FStatements.OnMouseDown := OnMouseDownMemo;
   FStatements.OnKeyUp := OnKeyUpMemo;
   FStatements.OnChange := OnChangeMemo;
   FStatements.PopupMenu := Page.Form.pmEdits;
   if FStatements.CanFocus then
      FStatements.SetFocus;

   BottomPoint.X := AWidth div 2;
   BottomPoint.Y := Height - 31;
   IPoint.X := BottomPoint.X + 30;
   IPoint.Y := FStatements.Height + 10;
   BottomHook := BottomPoint.X;
   TopHook.X := BottomPoint.X;
   Constraints.MinWidth := 140;
   Constraints.MinHeight := 48;
   FStatement.Free;
   FStatement := nil;
   FErrLine := -1;
end;

procedure TMultiLineBlock.OnDblClickMemo(Sender: TObject);
begin
   FStatements.SelectAll;
end;

procedure TMultiLineBlock.Paint;
begin
   inherited;
   DrawArrow(BottomPoint.X, Height-31, BottomPoint.X, Height-1);
   DrawI;
end;

function TMultiLineBlock.GetTextControl: TCustomEdit;
begin
   result := FStatements;
end;

function TMultiLineBlock.GetMemoEx: TMemoEx;
begin
   result := FStatements;
end;

procedure TMultiLineBlock.MyOnCanResize(Sender: TObject; var NewWidth, NewHeight: Integer; var Resize: Boolean);
begin
   Resize := (NewWidth >= Constraints.MinWidth) and (NewHeight >= Constraints.MinHeight);
   if FHResize and Resize then
   begin
      BottomPoint.X := Width div 2;
      IPoint.X := BottomPoint.X + 30;
      TopHook.X := BottomPoint.X;
   end;
   if FVResize and Resize then
      IPoint.Y := FStatements.Height + 10;
end;

function TMultiLineBlock.GenerateCode(ALines: TStringList; const ALangId: string; ADeep: integer; AFromLine: integer = LAST_LINE): integer;
var
   tmpList: TStringList;
begin
   result := 0;
   if (fsStrikeOut in Font.Style) or (FStatements.Text = '') then
      exit;
   tmpList := TStringList.Create;
   try
      GenerateDefaultTemplate(tmpList, ALangId, ADeep);
      TInfra.InsertLinesIntoList(ALines, tmpList, AFromLine);
      result := tmpList.Count;
   finally
      tmpList.Free;
   end;
end;

procedure TMultiLineBlock.UpdateEditor(AEdit: TCustomEdit);
var
   chLine: TChangeLine;
   templateLines: TStringList;
   i, rowNum: integer;
{$IFDEF USE_CODEFOLDING}
   foldRegion: TFoldRegionItem;
   foldRanges: TSynEditFoldRanges;
{$ENDIF}
begin
   if PerformEditorUpdate then
   begin
      chLine := TInfra.GetChangeLine(Self, FStatements);
      if chLine.CodeRange.FirstRow <> ROW_NOT_FOUND then
      begin
         if GSettings.UpdateEditor and not SkipUpdateEditor then
         begin
            templateLines := TStringList.Create;
            try
               GenerateCode(templateLines, GInfra.CurrentLang.Name, TInfra.GetEditorForm.GetIndentLevel(chLine.CodeRange.FirstRow, chLine.CodeRange.Lines));
               if chLine.CodeRange.Lines <> nil then
               begin
                  rowNum := chLine.CodeRange.LastRow - chLine.CodeRange.FirstRow + 1;
                  chLine.CodeRange.Lines.BeginUpdate;
                  for i := 1 to rowNum do
                     chLine.CodeRange.Lines.Delete(chLine.CodeRange.FirstRow);
{$IFDEF USE_CODEFOLDING}
                  if chLine.CodeRange.FoldRange <> nil then
                  begin
                     if chLine.CodeRange.IsFolded then
                     begin
                        rowNum := templateLines.Count - rowNum;
                        chLine.CodeRange.FoldRange.Widen(rowNum);
                        for i := 0 to templateLines.Count-1 do
                           chLine.CodeRange.Lines.InsertObject(chLine.CodeRange.FirstRow, templateLines[i], templateLines.Objects[i]);
                     end
                     else
                     begin
                        foldRegion := chLine.CodeRange.FoldRange.FoldRegion;
                        TInfra.GetEditorForm.RemoveFoldRange(chLine.CodeRange.FoldRange);
                        for i := templateLines.Count-1 downto 0 do
                           chLine.CodeRange.Lines.InsertObject(chLine.CodeRange.FirstRow, templateLines[i], templateLines.Objects[i]);
                        TInfra.GetEditorForm.OnChangeEditor;
                        foldRanges := TInfra.GetEditorForm.FindFoldRangesInCodeRange(chLine.CodeRange, templateLines.Count);
                        try
                           if (foldRanges <> nil) and (foldRanges.Count > 0) and (foldRanges[0].FoldRegion = foldRegion) and not foldRanges[0].Collapsed then
                           begin
                              TInfra.GetEditorForm.memCodeEditor.Collapse(foldRanges[0]);
                              TInfra.GetEditorForm.memCodeEditor.Refresh;
                           end;
                        finally
                           foldRanges.Free;
                        end;
                     end;
                  end
                  else
{$ENDIF}
                  begin
                     for i := templateLines.Count-1 downto 0 do
                        chLine.CodeRange.Lines.InsertObject(chLine.CodeRange.FirstRow, templateLines[i], templateLines.Objects[i]);
                  end;
                  chLine.CodeRange.Lines.EndUpdate;
                  TInfra.GetEditorForm.OnChangeEditor;
               end;
            finally
               templateLines.Free;
            end;
         end;
         TInfra.GetEditorForm.SetCaretPos(chLine);
      end
      else
         TInfra.UpdateCodeEditor(Self);
   end;
end;

procedure TMultiLineBlock.OnMouseDownMemo(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
   if ssLeft in Shift then
      OnMouseDown(Sender, Button, Shift, X, Y);
   if Button = mbLeft then
      TInfra.GetEditorForm.SetCaretPos(TInfra.GetChangeLine(Self, FStatements));
end;

procedure TMultiLineBlock.OnKeyUpMemo(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
   if Key in [VK_UP, VK_DOWN, VK_LEFT, VK_RIGHT] then
      OnMouseDownMemo(Sender, mbLeft, Shift, 0, 0);
end;

function TMultiLineBlock.GenerateTree(AParentNode: TTreeNode): TTreeNode;
var
   errMsg, lLabel: string;
   i: integer;
begin
   result := AParentNode;
   errMsg := GetErrorMsg(FStatements);
   for i := 0 to FStatements.Lines.Count-1 do
   begin
      if not FStatements.Lines[i].Trim.IsEmpty then
      begin
         lLabel := FStatements.Lines[i];
         if i = FErrLine then
            lLabel := lLabel + errMsg;
         AParentNode.Owner.AddChildObject(AParentNode, lLabel, FStatements);
      end;
   end;
   if not errMsg.IsEmpty then
   begin
      AParentNode.MakeVisible;
      AParentNode.Expand(false);
   end;
end;

end.
