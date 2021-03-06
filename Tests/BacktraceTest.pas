{******************************************************************************}
{                                                                              }
{            Copyright (c) 2014 Jan Rames                                      }
{                                                                              }
{******************************************************************************}
{                                                                              }
{            This Source Code Form is subject to the terms of the              }
{                                                                              }
{                       Mozilla Public License, v. 2.0.                        }
{                                                                              }
{            If a copy of the MPL was not distributed with this file,          }
{            You can obtain one at http://mozilla.org/MPL/2.0/.                }
{                                                                              }
{******************************************************************************}

unit BacktraceTest;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls;

type
  TTestForm = class(TForm)
    Panel: TPanel;
    cmdTest: TButton;
    cmdException: TButton;
    procedure cmdTestClick(Sender: TObject);
    procedure cmdExceptionClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  TestForm: TTestForm;

implementation

uses
	System.IOUtils,
	Posix.Proc,
	Posix.Backtrace,
	Posix.ExceptionUtil;

{$R *.fmx}

procedure SomeFunc2(a : Integer);
var s	: string;
{$IFDEF CPUARM}
	D	: array[0..128] of Pointer;
	i	: Integer;
{$ENDIF}
	ProcList : TPosixProcEntryList;
	St	: TStrings;
begin
	s:='Ha';
{$IFDEF CPUARM}
	i:=StackWalk(@D, 128);
	ProcList:=TPosixProcEntryList.Create;
	ProcList.LoadFromCurrentProcess;
	s:=ProcList.ConvertStackTrace(@D, 0, i);
	st:=TStringList.Create;
	st.Text:=s;
	st.SaveToFile(TPath.Combine(TPath.GetSharedDocumentsPath, 'trace.txt'));
	st.Clear;
	LoadProcMaps(st);
	st.SaveToFile(TPath.Combine(TPath.GetSharedDocumentsPath, 'maps.txt'));
	MessageDlg(s, TMsgDlgType.mtInformation, [TMsgDlgBtn.mbOK], 0);
{$ENDIF}
{$IFDEF MSWINDOWS}
	ProcList:=TPosixProcEntryList.Create;
	try
		St:=TStringList.Create;
		try
			//We have some test vectors generated by this application, but note
			//that binary versions may not match
			St.LoadFromFile('..\..\..\..\Tests\maps.txt');
			ProcList.LoadFromStrings(St);
			ProcList.GetStackLine(0);
			ProcList.GetStackLine($400B52E9);
			ProcList.GetStackLine($75A48AC6);
		finally
			St.Free;
        end;
	finally
		ProcList.Free;
	end;
{$ENDIF}
end;


procedure SomeFunc1(a : Integer);
begin
	SomeFunc2(a);
end;

type
  TObj = class
  public
	procedure Test; virtual;
  end;

  TObj2 = class(TObj)
  public
	procedure Test; override;
  end;


{ TObj2 }

procedure TObj2.Test;
begin
	inherited;
end;

{ TObj }

procedure TObj.Test;
begin
	SomeFunc1(1);
end;

{ TTestForm }

procedure TTestForm.cmdExceptionClick(Sender: TObject);
var s	: string;
	st	: TStrings;
begin
	TExceptionStackInfo.Attach;
	try
		raise Exception.Create('Error Message');
	except
		on E : Exception do begin
			s:=E.StackTrace;
			s:=E.ClassName + ': ' + E.Message + #$A + s;
			st:=TStringList.Create;
			st.Text:=s;
			st.SaveToFile(TPath.Combine(TPath.GetSharedDocumentsPath, 'exc.txt'));
			st.Free;
			MessageDlg(s, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], 0);
		end;
	end;
end;

procedure TTestForm.cmdTestClick(Sender: TObject);
var O	: TObj;
begin
	O:=TObj2.Create;
	O.Test;
end;

end.
