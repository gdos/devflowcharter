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



unit Explorer_Form;

interface

uses
   Vcl.Controls, Vcl.StdCtrls, Vcl.Menus, Vcl.ComCtrls, System.Classes, System.Types,
   OmniXML, Base_Form, CommonTypes, CommonInterfaces;

type
  TExplorerForm = class(TBaseForm)
    tvExplorer: TTreeView;
    lblErrors: TLabel;
    lblWarnings: TLabel;
    PopupMenu: TPopupMenu;
    miExpand: TMenuItem;
    miCollapse: TMenuItem;
    miRefresh: TMenuItem;
    miNextError: TMenuItem;
    miPrevError: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    miRemove: TMenuItem;
    chkAutoNav: TCheckBox;
    procedure FormShow(Sender: TObject);
    procedure tvExplorerChange(Sender: TObject; Node: TTreeNode);
    procedure miExpandClick(Sender: TObject);
    procedure PopupMenuPopup(Sender: TObject);
    procedure miRefreshClick(Sender: TObject);
    procedure miNextErrorClick(Sender: TObject);
    procedure tvExplorerCustomDrawItem(Sender: TCustomTreeView;
      Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure miRemoveClick(Sender: TObject);
    procedure Localize(AList: TStringList); override;
    procedure ResetForm; override;
    procedure FormCreate(Sender: TObject);
    procedure chkAutoNavClick(Sender: TObject);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  private
    { Private declarations }
    FErrWarnCount: TErrWarnCount;
    function GetFocusable(ANode: TTreeNode): IFocusable;

  public
    { Public declarations }
    procedure ExportSettingsToXMLTag(ATag: IXMLElement); override;
    procedure ImportSettingsFromXMLTag(ATag: IXMLElement); override;
  end;

var
  ExplorerForm: TExplorerForm;

implementation
{$R *.dfm}

uses
   Vcl.Graphics, Vcl.Forms, System.SysUtils, System.UITypes, ApplicationCommon,
   Case_Block, Base_Block, XMLProcessor;

procedure TExplorerForm.FormShow(Sender: TObject);
begin
    if GProject <> nil then
    begin
       FErrWarnCount := GProject.CountErrWarn;
       if FErrWarnCount.ErrorCount > 0 then
          lblErrors.Font.Color := NOK_COLOR
       else
          lblErrors.Font.Color := OK_COLOR;
       lblErrors.Caption := i18Manager.GetFormattedString('lblErrors', [FErrWarnCount.ErrorCount]);
       lblWarnings.Caption := i18Manager.GetFormattedString('lblWarnings', [FErrWarnCount.WarningCount]);
       with tvExplorer do
       begin
          Items.BeginUpdate;
          Items.Clear;
          Selected := Items.AddChild(nil, i18Manager.GetFormattedString('RootNodeText', [GProject.Name]));
          GProject.GenerateTree(Selected);
          Items.EndUpdate;
       end;
    end;
end;

procedure TExplorerForm.ResetForm;
begin
   Width := 498;
   Height := 574;
   FErrWarnCount.ErrorCount := 0;
   FErrWarnCount.WarningCount := 0;
   tvExplorer.Items.Clear;
   inherited ResetForm;
end;

function TExplorerForm.GetFocusable(ANode: TTreeNode): IFocusable;
var
   winControl: TWinControl;
begin
   result := nil;
   if (ANode <> nil) and TInfra.IsValid(ANode.Data) then
   begin
      winControl := ANode.Data;
      if TObject(winControl) is TWinControl then
         Supports(winControl, IFocusable, result);
   end;
end;

procedure TExplorerForm.Localize(AList: TStringList);
begin
   if tvExplorer.CanFocus then
      miRefresh.Click;
   inherited Localize(AList);
end;

procedure TExplorerForm.tvExplorerChange(Sender: TObject; Node: TTreeNode);
var
   focusable: IFocusable;
   focusInfo: TFocusInfo;
begin
   if chkAutoNav.Checked then
   begin
      focusable := GetFocusable(Node);
      if (focusable <> nil) and focusable.CanBeFocused then
      begin
         TInfra.InitFocusInfo(focusInfo);
         focusInfo.ActiveControl := tvExplorer;
         focusable.RetrieveFocus(focusInfo);
         GProject.RepaintFlowcharts;
      end;
   end;
end;

procedure TExplorerForm.miExpandClick(Sender: TObject);
begin
   if tvExplorer.Selected <> nil then
   begin
      tvExplorer.Items.BeginUpdate;
      if Sender = miExpand then
         tvExplorer.Selected.Expand(true)
      else if Sender = miCollapse then
         tvExplorer.Selected.Collapse(true);
      tvExplorer.Items.EndUpdate;
   end;
end;

procedure TExplorerForm.PopupMenuPopup(Sender: TObject);
var
   focusable: IFocusable;
begin
   miExpand.Enabled    := false;
   miCollapse.Enabled  := false;
   miNextError.Enabled := false;
   miPrevError.Enabled := false;
   miRemove.Enabled    := false;
   if tvExplorer.Selected <> nil then
   begin
      miNextError.Enabled := (FErrWarnCount.ErrorCount > 0) or (FErrWarnCount.WarningCount > 0);
      miPrevError.Enabled := miNextError.Enabled;
      miExpand.Enabled := tvExplorer.Selected.HasChildren;
      miCollapse.Enabled := miExpand.Enabled;
      focusable := GetFocusable(tvExplorer.Selected);
      miRemove.Enabled := (focusable <> nil) and focusable.CanBeRemoved;
   end;
end;

procedure TExplorerForm.miRefreshClick(Sender: TObject);
begin
   tvExplorer.Enabled := false;
   FormShow(Self);
   tvExplorer.Enabled := true;
end;

procedure TExplorerForm.miNextErrorClick(Sender: TObject);
var
   i, c, last: integer;
   focusable: IFocusable;
begin
   if tvExplorer.Selected <> nil then
   begin
      if Sender = miNextError then
      begin
         c := 1;
         last := tvExplorer.Items.Count;
      end
      else
      begin
         c := -1;
         last := -1;
      end;
      i := tvExplorer.Selected.AbsoluteIndex + c;
      while i <> last do
      begin
         focusable := GetFocusable(tvExplorer.Items[i]);
         if (focusable <> nil) and TInfra.IsNOkColor(focusable.GetFocusColor) then
         begin
            if not tvExplorer.Items[i].IsVisible then
               tvExplorer.Items[i].MakeVisible;
            tvExplorer.Selected := tvExplorer.Items[i];
            break;
         end;
         i := i + c;
      end;
   end;
end;

procedure TExplorerForm.tvExplorerCustomDrawItem(Sender: TCustomTreeView;
  Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
var
   nodeRect: TRect;
   focusable: IFocusable;
   lColor, lColor2: TColor;
   x, y: integer;
   lFont: TFont;
begin
   x := 0;
   y := 0;
   lFont := Sender.Canvas.Font;
   lColor := OK_COLOR;
   if cdsSelected in State then
   begin
      Sender.Canvas.Brush.Style := bsClear;
      x := 2;
      y := 1;
   end;
   focusable := GetFocusable(Node);
   if focusable <> nil then
   begin
      lColor2 := focusable.GetFocusColor;
      if TInfra.IsNOkColor(lColor2) or (lColor2 = TEXT_COLOR) then
         lColor := lColor2;
      if focusable.IsBoldDesc then
         lFont.Style := lFont.Style + [fsBold];
   end;
   lFont.Color := lColor;
   nodeRect := Node.DisplayRect(True);
   Sender.Canvas.TextOut(nodeRect.Left+x, nodeRect.Top+y, Node.Text);
   DefaultDraw := true;
end;

procedure TExplorerForm.miRemoveClick(Sender: TObject);

 function RemoveData(const ANode: TTreeNode): boolean;
 var
    winControl: TWinControl;
    caseBlock: TCaseBlock;
    branch: TBranch;
    focusable: IFocusable;
 begin
    result := false;
    if ANode <> nil then
    begin
       winControl := ANode.Data;
       if not (TInfra.IsValid(winControl) or (TObject(winControl) is TWinControl)) then
          exit;
       if (winControl.Parent is TCaseBlock) and (winControl <> TCaseBlock(winControl.Parent).GetTextControl) then
       begin
          caseBlock := TCaseBlock(winControl.Parent);
          branch := caseBlock.GetBranchByControl(winControl);
          if branch <> nil then
          begin
             caseBlock.RemoveBranch(branch);
             result := true;
          end;
       end
       else
       begin
          focusable := GetFocusable(ANode);
          if (focusable <> nil) and focusable.CanBeRemoved then
          begin
             focusable.Remove;
             result := true;
          end;
       end;
    end;
 end;
 
begin
   if RemoveData(tvExplorer.Selected) then
   begin
      tvExplorer.Items.BeginUpdate;
      tvExplorer.Selected.Delete;
      tvExplorer.Items.EndUpdate;
   end;
end;

procedure TExplorerForm.ExportSettingsToXMLTag(ATag: IXMLElement);
begin
   if Visible then
   begin
      ATag.SetAttribute('tree_win_show', 'true');
      ATag.SetAttribute('tree_win_x', Left.ToString);
      ATag.SetAttribute('tree_win_y', Top.ToString);
      ATag.SetAttribute('tree_win_w', Width.ToString);
      ATag.SetAttribute('tree_win_h', Height.ToString);
      ATag.SetAttribute('tree_top_y', tvExplorer.TopItem.AbsoluteIndex.ToString);
      if WindowState = wsMinimized then
         ATag.SetAttribute('tree_win_min', 'true');
   end;
end;

procedure TExplorerForm.ImportSettingsFromXMLTag(ATag: IXMLElement);
var
   rect: TRect;
   topY: integer;
begin
   if TXMLProcessor.GetBoolFromAttr(ATag, 'tree_win_show') and GInfra.CurrentLang.EnabledExplorer then
   begin
      rect.Left := StrToIntDef(ATag.GetAttribute('tree_win_x'), 50);
      rect.Top := StrToIntDef(ATag.GetAttribute('tree_win_y'), 50);
      rect.Right := StrToIntDef(ATag.GetAttribute('tree_win_w'), 498);
      rect.Bottom := StrToIntDef(ATag.GetAttribute('tree_win_h'), 574);
      Position := poDesigned;
      SetBounds(rect.Left, rect.Top, rect.Right, rect.Bottom);
      if TXMLProcessor.GetBoolFromAttr(ATag, 'tree_win_min') then
         WindowState := wsMinimized;
      Show;
      topY := StrToIntDef(ATag.GetAttribute('tree_top_y'), -2);
      if (topY >= 0) and (topY < tvExplorer.Items.Count) then
         tvExplorer.TopItem := tvExplorer.Items[topY];
   end;
end;

procedure TExplorerForm.FormMouseWheel(Sender: TObject; Shift: TShiftState;
   WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
   if (ssCtrl in Shift) and (tvExplorer.Selected <> nil) then
   begin
      if WheelDelta < 0 then
         tvExplorer.Selected := tvExplorer.Selected.GetNextVisible
      else
         tvExplorer.Selected := tvExplorer.Selected.GetPrevVisible;
   end;
end;

procedure TExplorerForm.FormCreate(Sender: TObject);
begin
   chkAutoNav.Checked := GSettings.ExplorerAutoNav;
end;

procedure TExplorerForm.chkAutoNavClick(Sender: TObject);
begin
   GSettings.ExplorerAutoNav := chkAutoNav.Checked;
end;

end.

