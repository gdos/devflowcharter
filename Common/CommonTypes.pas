{  
   Copyright (C) 2011 The devFlowcharter project.
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



unit CommonTypes;

interface

uses
{$IFDEF USE_CODEFOLDING}
   SynEditCodeFolding,
{$ENDIF}
   System.Classes, Generics.Defaults, SynEditTypes;

type

   TCustomCursor = (crNormal, crIfElse, crFor, crRepeat, crWhile, crInstr, crMultiInstr,
                    crIf, crFuncCall, crInput, crOutput, crCase, crReturn, crText, crFolder);

   TErrorType = (errNone, errDeclare, errIO, errValidate, errConvert, errSyntax, errPrinter, errCompile, errImport, errGeneral);

   TBlockType = (blUnknown, blInstr, blMultiInstr, blInput, blOutput, blFuncCall,
                 blWhile, blRepeat, blIf, blIfElse, blFor, blCase, blMain, blComment,
                 blReturn, blText, blFolder);

   TDataTypeKind = (tpInt, tpReal, tpString, tpBool, tpRecord, tpEnum, tpArray, tpPtr, tpOther);

   TUserDataTypeKind = (dtInt, dtRecord, dtArray, dtReal, dtOther, dtEnum);

   TParserMode = (prsNone, prsCondition, prsAssign, prsInput, prsOutput, prsFor, prsFuncCall,
                 prsCase, prsCaseValue, prsReturn, prsVarSize);

   TArrowPosition = (arrMiddle, arrEnd);

   TColorShape = (shpNone, shpEllipse, shpParallel, shpDiamond, shpRectangle, shpRoadSign, shpRoutine, shpFolder);

   TCodeRange = record
      FirstRow,
      LastRow: integer;
      IsFolded: boolean;
      Lines: TStrings;
{$IFDEF USE_CODEFOLDING}
      FoldRange: TSynEditFoldRange;
{$ENDIF}
   end;

   PNativeDataType = ^TNativeDataType;
   TNativeDataType = record
      Name: string;
      Kind: TDataTypeKind;
      OrigType: PNativeDataType;
   end;

   TErrWarnCount = record
      ErrorCount,
      WarningCount: integer;
   end;

   TChangeLine = record
      Text: string;
      Row,
      Col: integer;
      EditCaretXY: TBufferCoord;
      CodeRange: TCodeRange;
   end;

   PTypesSet = ^TTypesSet;
   TTypesSet = set of 0..255;

   TComponentComparer = class(TComparer<TComponent>)
      FCompareType: integer;
      constructor Create(ACompareType: integer);
      function Compare(const L, R: TComponent): integer; override;
   end;



implementation

uses
   System.SysUtils, CommonInterfaces;

constructor TComponentComparer.Create(ACompareType: integer);
begin
   inherited Create;
   FCompareType := ACompareType;
end;

function TComponentComparer.Compare(const L, R: TComponent): integer;
var
   compareObj: IGenericComparable;
begin
   result := -1;
   if Supports(L, IGenericComparable, compareObj) then
      result := compareObj.GetCompareValue(FCompareType);
   if Supports(R, IGenericComparable, compareObj) then
      result := result - compareObj.GetCompareValue(FCompareType);
end;

end.


