UNIT HeartWare.FileStream;

INTERFACE

USES Classes,SysUtils;

CONST
  fmAppend              = Cardinal($80000000);
  fmAppendExisting      = Cardinal($40000000);

TYPE
  TFileStream   = CLASS(Classes.TFileStream)
                    CONSTRUCTOR         Create(CONST FileName : TFileName ; Mode : Cardinal ; Share : Cardinal); REINTRODUCE; OVERLOAD;
                    CONSTRUCTOR         Create(CONST FileName : TFileName ; Mode : Cardinal ; Encoding : TEncoding ; Share : Cardinal); REINTRODUCE; OVERLOAD;
                    CONSTRUCTOR         Create(CONST FileName : TFileName ; Mode : Cardinal); REINTRODUCE; OVERLOAD;
                    CONSTRUCTOR         Create(CONST FileName : TFileName ; Mode : Cardinal ; Encoding : TEncoding); REINTRODUCE; OVERLOAD;
                    DESTRUCTOR          Destroy; OVERRIDE;
                  STRICT PRIVATE
                    FName               : TFileName;
                    Encoding            : TEncoding;
                    FTW                 : TTextWriter;
                    CONST
                      AppendBits        = fmAppend OR fmAppendExisting;
                      ExclusiveBits     = fmExclusive;
                      AccessBits        = $00000007 AND NOT ExclusiveBits;
                      ShareBits         = $000000F0;
                    PROCEDURE           AppendFile(CONST FileName : TFileName ; Mode : Cardinal ; Share : Cardinal);
                  STRICT PROTECTED
                    FUNCTION            CreateTextWriter(Encoding : TEncoding) : TTextWriter;   VIRTUAL;
                    FUNCTION            DefEncoding : TEncoding;                                VIRTUAL;
                    FUNCTION            DefaultShare(Mode : Cardinal) : Cardinal;               VIRTUAL;
                    PROCEDURE           AfterConstruction;                                      OVERRIDE;
                  PUBLIC
                    CLASS VAR           DefaultEncoding : TEncoding;
                    FUNCTION            TW : TTextWriter;
                    FUNCTION            FileName : TFileName;
                    PROCEDURE           WriteLine(CONST S : STRING); OVERLOAD; INLINE;
                    PROCEDURE           WriteLine(CONST Format : STRING ; CONST Args : ARRAY OF CONST); OVERLOAD;
                  END;

IMPLEMENTATION

USES Windows,RTLConsts;

CONST
  fmShareAuto           = $000000F0;

CONSTRUCTOR TFileStream.Create(CONST FileName : TFileName ; Mode : Cardinal ; Encoding : TEncoding ; Share : Cardinal);
  BEGIN
    IF Mode AND AppendBits=0 THEN
      INHERITED Create(FileName,Mode,Share)
    ELSE
      AppendFile(FileName,Mode,Share);
    Self.Encoding:=Encoding
  END;

FUNCTION TFileStream.DefaultShare(Mode : Cardinal) : Cardinal;
  BEGIN
    IF Mode AND AppendBits=0 THEN Result:=fmShareCompat ELSE Result:=fmShareAuto
  END;

FUNCTION TFileStream.DefEncoding : TEncoding;
  BEGIN
    IF Assigned(DefaultEncoding) THEN Result:=DefaultEncoding ELSE Result:=TEncoding.Default
  END;

CONSTRUCTOR TFileStream.Create(CONST FileName : TFileName ; Mode : Cardinal ; Encoding : TEncoding);
  BEGIN
    Create(FileName,Mode,Encoding,DefaultShare(Mode))
  END;

FUNCTION TFileStream.CreateTextWriter(Encoding : TEncoding) : TTextWriter;
  BEGIN
    Result:=TStreamWriter.Create(Self,Encoding)
  END;

CONSTRUCTOR TFileStream.Create(CONST FileName : TFileName ; Mode : Cardinal ; Share : Cardinal);
  BEGIN
    Create(FileName,Mode,DefEncoding,Share)
  END;

CONSTRUCTOR TFileStream.Create(CONST FileName : TFileName ; Mode : Cardinal);
  BEGIN
    Create(FileName,Mode,DefEncoding)
  END;

PROCEDURE TFileStream.AppendFile(CONST FileName : TFileName ; Mode : Cardinal ; Share : Cardinal);
  VAR
    Exists                      : BOOLEAN;
    Append,Access,Sharing       : Cardinal;

  FUNCTION FileCreate(CONST FileName : TFileName ; Mode : LongWord) : THandle;
    CONST
      Exclusive : ARRAY[0..1] OF LongWord = (CREATE_ALWAYS,CREATE_NEW);
      ShareMode : ARRAY[2..4] OF LongWord = (FILE_SHARE_READ,FILE_SHARE_WRITE,FILE_SHARE_READ OR FILE_SHARE_WRITE);
      Access    : ARRAY[0..2] OF LongWord = (GENERIC_READ,GENERIC_WRITE,GENERIC_READ OR GENERIC_WRITE);

    VAR
      ShareIdx  : Cardinal;
      AccessIdx : Cardinal;
      ExclIdx   : Cardinal;

    BEGIN
      ShareIdx:=(Mode AND ShareBits) SHR 4; AccessIdx:=Mode AND AccessBits; ExclIdx:=(Mode AND ExclusiveBits) SHR 2;
      IF (ShareIdx IN [LOW(ShareMode)..HIGH(ShareMode)]) AND (AccessIdx IN [LOW(Access)..HIGH(Access)]) AND (ExclIdx IN [LOW(Exclusive)..HIGH(Exclusive)]) THEN
        Result:=CreateFile(PChar(FileName),Access[AccessIdx],ShareMode[ShareIdx],NIL,Exclusive[ExclIdx],FILE_ATTRIBUTE_NORMAL,0)
      ELSE
        Result:=INVALID_HANDLE_VALUE
    END;

  BEGIN
    Exists:=FileExists(FileName); Append:=Mode AND AppendBits; Access:=Mode AND AccessBits; Sharing:=Mode AND ShareBits;
    IF Sharing=0 THEN Sharing:=Share;
    IF (Append=fmAppendExisting) AND NOT Exists THEN
      FHandle:=INVALID_HANDLE_VALUE
    ELSE BEGIN
      IF Access=fmOpenRead THEN BEGIN
        Access:=fmOpenWrite;
        IF Append=fmAppendExisting THEN Access:=Access OR fmExclusive;
      END;
      IF Sharing=fmShareAuto THEN
        IF Access AND ExclusiveBits=0 THEN Sharing:=fmShareDenyWrite ELSE Sharing:=fmShareExclusive;
      Mode:=Access OR Sharing;
      IF Exists THEN
        INHERITED Create(FileOpen(FileName,Mode))
      ELSE
        INHERITED Create(FileCreate(FileName,Mode))
    END;
    IF FHandle=INVALID_HANDLE_VALUE THEN
      {$IFDEF VCL }
        RAISE EFOpenError.CreateResFmt(@SFOpenErrorEx,[ExpandFileName(FileName),SysErrorMessage(GetLastError)]);
      {$ELSE }
        RAISE EFOpenError.CreateFmt(SFOpenErrorEx,[ExpandFileName(FileName),SysErrorMessage(GetLastError)]);
      {$ENDIF }
    IF Exists THEN Seek(0,soEnd);
    FName:=FileName
  END;

DESTRUCTOR TFileStream.Destroy;
  BEGIN
    FreeAndNIL(FTW);
    INHERITED
  END;

FUNCTION TFileStream.FileName : TFileName;
  BEGIN
    IF FName='' THEN Result:=INHERITED FileName ELSE Result:=FName
  END;

FUNCTION TFileStream.TW : TTextWriter;
  BEGIN
    IF NOT Assigned(FTW) THEN FTW:=CreateTextWriter(Encoding);
    Result:=FTW
  END;

PROCEDURE TFileStream.WriteLine(CONST Format : STRING ; CONST Args : ARRAY OF CONST);
  BEGIN
    TW.WriteLine(Format,Args)
  END;

PROCEDURE TFileStream.WriteLine(CONST S : STRING);
  BEGIN
    TW.WriteLine(S)
  END;

PROCEDURE TFileStream.AfterConstruction;
  BEGIN
    IF NOT Assigned(Encoding) THEN Encoding:=DefEncoding;
    INHERITED
  END;

END.
