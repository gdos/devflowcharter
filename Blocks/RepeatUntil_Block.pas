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



unit RepeatUntil_Block;

interface

uses
   Vcl.Graphics, System.Types, Base_Block, CommonInterfaces;

type

   TRepeatUntilBlock = class(TGroupBlock)
      private
         FLeftLabel, FRightLabel: string;
      public
         constructor Create(ABranch: TBranch); overload;
         constructor Create(ABranch: TBranch; ALeft, ATop, AWidth, AHeight, b_hook, p1X, p1Y: integer; AId: integer = ID_INVALID); overload;
         function Clone(ABranch: TBranch): TBlock; override;
         function GetDescTemplate(const ALangId: string): string; override;
      protected
         procedure Paint; override;
         procedure SetWidth(AMinX: integer); override;
         function GetDiamondTop: TPoint; override;
   end;

implementation

uses
   System.Classes, System.SysUtils, System.StrUtils, ApplicationCommon,
   CommonTypes, LangDefinition;

constructor TRepeatUntilBlock.Create(ABranch: TBranch; ALeft, ATop, AWidth, AHeight, b_hook, p1X, p1Y: integer; AId: integer = ID_INVALID);
begin

   FType := blRepeat;

   inherited Create(ABranch, ALeft, ATop, AWidth, AHeight, Point(p1X, p1Y), AId);

   FInitParms.Width := 240;
   FInitParms.Height := 111;
   FInitParms.BottomHook := 120;
   FInitParms.BranchPoint.X := 120;
   FInitParms.BottomPoint.X := 229;
   FInitParms.P2X := 0;
   FInitParms.HeightAffix := 82;

   if GInfra.CurrentLang.RepeatUntilAsDoWhile then
   begin
      FLeftLabel := FTrueLabel;
      FRightLabel := FFalseLabel;
   end
   else
   begin
      FLeftLabel := FFalseLabel;
      FRightLabel := FTrueLabel;
   end;
   BottomPoint.X := Width - 11;
   BottomPoint.Y := Height - 50;
   TopHook.Y := 0;
   BottomHook := b_hook;
   TopHook.X := p1X;
   Constraints.MinWidth := FInitParms.Width;
   Constraints.MinHeight := FInitParms.Height;
   FStatement.Alignment := taCenter;
   PutTextControls;
end;

function TRepeatUntilBlock.Clone(ABranch: TBranch): TBlock;
begin
   result := TRepeatUntilBlock.Create(ABranch, Left, Top, Width, Height, BottomHook, Branch.Hook.X, Branch.Hook.Y);
   result.CloneFrom(Self);
end;

constructor TRepeatUntilBlock.Create(ABranch: TBranch);
begin
   Create(ABranch, 0, 0, 240, 111, 120, 120, 29);
end;

procedure TRepeatUntilBlock.Paint;
var
   dLeft, dRight, dBottom: PPoint;
begin
   inherited;
   if Expanded then
   begin
      IPoint.X := BottomHook + 40;
      IPoint.Y := Height - 25;
      dLeft := @FDiamond[D_LEFT];
      dRight := @FDiamond[D_RIGHT];
      dBottom := @FDiamond[D_BOTTOM];
      BottomPoint.Y := dRight.Y;

      Canvas.PenPos := dLeft^;
      Canvas.LineTo(5, dLeft.Y);
      DrawArrowTo(5, 0, arrMiddle);
      Canvas.LineTo(Branch.Hook.X, TopHook.Y);
      DrawArrowTo(Branch.Hook);

      DrawTextLabel(dLeft.X, dLeft.Y-5, FLeftLabel, true, true);
      DrawTextLabel(dRight.X, dRight.Y-5, FRightLabel, false, true);
      DrawBlockLabel(dBottom.X-30, dBottom.Y-10, GInfra.CurrentLang.LabelRepeat, true);
      Canvas.PenPos := dRight^;
      Canvas.LineTo(BottomPoint.X, dRight.Y);
      DrawArrowTo(BottomPoint.X, Height-1);
   end;
   DrawI;
end;

function TRepeatUntilBlock.GetDescTemplate(const ALangId: string): string;
var
   lang: TLangDefinition;
begin
   result := '';
   lang := GInfra.GetLangDefinition(ALangId);
   if lang <> nil then
      result := lang.RepeatUntilDescTemplate;
end;

procedure TRepeatUntilBlock.SetWidth(AMinX: integer);
begin
   if AMinX < BottomHook + 121 then
      Width := BottomHook + 121
   else
      Width := AMinX;
   BottomPoint.X := Width - 11;
end;

function TRepeatUntilBlock.GetDiamondTop: TPoint;
begin
   result := Point(BottomHook, Height-81);
end;

end.