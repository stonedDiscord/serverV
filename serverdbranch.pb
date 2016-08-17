; yes this is the legit serverV source code please report bugfixes/modifications/feature requests to sD/trtukz on skype

CompilerIf #PB_Compiler_Debugger=0
  OnErrorGoto(?start)
CompilerEndIf

;- Defining Structure
Structure CharacterArray
  StructureUnion
    c.c[0]
    s.s{1}[0]
  EndStructureUnion
EndStructure

Global version$="1.3"
Global CommandThreading=0
Global Dim MaskKey.a(3)
Global Quit=0
Global ReplayMode=0
Global ReplayLength=0
Global ReplayFile$=""
Global LoopMusic=0
Global MultiChar=1
Global nthread=0
Global error=0
Global lasterror=0
Global WebSockets=1
Global Logging.b=0
Global LagShield=10
Global public.b=0
Global LogFile$="poker.log"
Global oppass$=""
Global killed=0
Global success=0
Global adminpass$=""
Global opppass$=""
Global Quit=0
Global Port=27016
Global scene$="AAOPublic2"
Global CharacterNumber=0
Global slots$="100"
Global oBG.s="gs4"
Global rt.b=1
Global loghd.b=0
Global background.s
Global PV=1
Global msname$="serverV"
Global desc$="Default serverV "+version$
Global www$
Global rf.b=0
Global msip$="127.0.0.1"
Global Replays.b=0
Global rline=0
Global replayline=0
Global replayopen.b
Global modcol=0
Global BlockINI.b=0
Global BlockTaken.b=1
Global MOTDevi=0
Global ExpertLog=0
Global tracks=0
Global msthread=0
Global LoginReply$="MODOK#%"
Global motd$="Take that!"
Global musicpage=0
Global EviNumber=0
Global ListMutex = CreateMutex()
Global MusicMutex = CreateMutex()
Global RefreshMutex = CreateMutex()
Global ActionMutex = CreateMutex()
Global musicmode=1
Global update=0
Global AreaNumber=1
Global decryptor$
Global key
Global newbuild
Global *Buffer
*Buffer = AllocateMemory(1024)
Global NewList HDmods.s()
Global NewList gimps.s()
Global NewList PReplay.s()
Global Dim Icons.l(2)
Global Dim ReadyChar.s(100)
Global Dim ReadyEvidence.s(100)
Global Dim ReadyMusic.s(500)
Global Dim ReadyVItem.s(100)


;- Include files
#CONSOLE=0
#WEB=1

CompilerIf #CONSOLE=0
  XIncludeFile "Common.pbf"
CompilerEndIf

IncludeFile "../server_private/server_shared.pb"
Global Dim Items.ItemData(100)
Global NewList HDbans.TempBan()
Global NewList IPbans.TempBan()
Global NewList SDbans.TempBan()

; Initialize The Network
If InitNetwork() = 0
  CompilerIf #CONSOLE=0
    MessageRequester("serverV "+version$, "Can't initialize the network!",#MB_ICONERROR)
  CompilerEndIf
  End
EndIf


;- Define Functions
; yes after the network init and include code
; many of these depend on that

Procedure WriteReplay(string$)
  If Replays
    If ReplayOpen
      WriteStringN(3,string$) 
      WriteStringN(3,"wait")
      rline+1
      If rline>replayline
        CloseFile(3)
        ReplayOpen=0
      EndIf
    Else
      ReplayOpen=OpenFile(3,"base/replays/AAO replay "+FormatDate("%dd-%mm-%yy %hh-%ii-%ss",Date())+".txt",#PB_File_SharedRead | #PB_File_NoBuffering)
      If ReplayOpen
        WriteStringN(3,"decryptor#"+decryptor$+"#%")
      EndIf
    EndIf
  EndIf
EndProcedure

;- Load Settings function
Procedure LoadServer(reload)
  Define loadchars
  Define loadcharsettings
  Define loaddesc
  Define loadevi
  Define iniarea,charpage,page
  Define track$,hdmod$,hdban$,ipban$,ready$,area$
  
  If OpenPreferences("base/settings.ini")=0
    CreateDirectory("base")
    If CreatePreferences("base/settings.ini")=0
      WriteLog("couldn't create settings file(folder missing/permissions?)",Server)
    Else
      PreferenceGroup("Net")
      WritePreferenceInteger("port",7777)
      PreferenceGroup("server")
      WritePreferenceString("Name", "DEFAULT")
      WritePreferenceString("Desc", "DEFAULT")
    EndIf
  EndIf
  PreferenceGroup("net")
  modpass$=ReadPreferenceString("modpass","")   
  port=ReadPreferenceInteger("port",7777)
  
  public=ReadPreferenceInteger("public",0)
  CompilerIf #CONSOLE=0
    SetGadgetText(String_Port,Str(port))
    SetGadgetState(Checkbox_public,public)
  CompilerElse
    PrintN("Loading serverV 1.3 settings")
    PrintN("Modppass:"+modpass$)
    PrintN("Server port:"+Str(port))
    PrintN("Public server:"+Str(public))
  CompilerEndIf
  PreferenceGroup("server")
  Replays=ReadPreferenceInteger("replaysave",0)
  replayline=ReadPreferenceInteger("replayline",400)
  scene$=ReadPreferenceString("scene","VNOVanilla")
  msname$=ReadPreferenceString("Name","serverV")
  desc$=ReadPreferenceString("Desc","Default serverV")
  www$=ReadPreferenceString("www","http://stoned.ddns.net/")  
  
  If OpenPreferences("poker.ini")=0
    If CreatePreferences("poker.ini")=0
      WriteLog("couldn't create settings file(folder missing/permissions?)",Server)
    Else
      PreferenceGroup("cfg")
      WritePreferenceString("adminpass","")
      WritePreferenceInteger("modcol",0)
      WritePreferenceString("LoginReply","CT#$HOST#Successfully connected as mod#%")
      WritePreferenceString("LogFile","log.txt")
    EndIf
  EndIf
  
  PreferenceGroup("cfg")
  adminpass$=ReadPreferenceString("adminpass","")
  modcol=ReadPreferenceInteger("modcol",0)
  LoginReply$=ReadPreferenceString("LoginReply","CT#sD#got it#%")
  LogFile$=ReadPreferenceString("LogFile","logs.txt")
  msip$=ReadPreferenceString("MSip","127.0.0.1")
  If Logging
    CloseFile(1)
  EndIf
  Logging=ReadPreferenceInteger("Logging",1)
  ClosePreferences()
  
  If Logging
    If OpenFile(1,LogFile$,#PB_File_SharedRead | #PB_File_NoBuffering)
      FileSeek(1,Lof(1))
      WriteLog("Running version "+version$,Server)
    Else
      Logging=0
    EndIf
  EndIf  
  
  OpenPreferences("base/scene/"+scene$+"/init.ini")
  
  CompilerIf #CONSOLE
    PrintN("Admin pass:"+adminpass$)
    PrintN("Block INI edit:"+Str(blockini))
    PrintN("Moderator color:"+Str(modcol))
    PrintN("Login reply:"+LoginReply$)
    PrintN("Logfile:"+LogFile$)
    PrintN("Logging:"+Str(Logging))
  CompilerEndIf
  
  For iniarea=0 To 100
    areas(iniarea)\bg=oBG.s
    areas(iniarea)\good=30
    areas(iniarea)\evil=30
  Next
  
  PreferenceGroup("chars")
  Global characternumber=ReadPreferenceInteger("number",1)
  ReDim Characters.ACharacter(characternumber-1)
  For loadchars=0 To characternumber-1
    PreferenceGroup("chars")
    Characters(loadchars)\name=ReadPreferenceString(Str(loadchars+1),"Monokuma")
    PreferenceGroup("pass")
    Characters(loadchars)\pw=ReadPreferenceString(Str(loadchars+1),"")
  Next  
  ClosePreferences()
  
  If ReadFile(2, "base/scene/"+scene$+"/musiclist.txt")
    tracks=0
    musicpage=0
    While Eof(2) = 0
      AddElement(Music())
      track$=ReadString(2) 
      track$=ReplaceString(track$,"#","<num>")
      track$ = ReplaceString(track$,"%","<percent>")
      Music()\TrackName = track$
      ready$ = ready$ + Str(tracks) + "#" + track$ + "#"
      track$=ReplaceString(track$,".mp3","")
      tracks+1
    Wend
    CloseFile(2)
    ResetList(Music())
    Repeat
      NextElement(Music())
      ReadyMusic(readytracks) = "MD#" + Str(readytracks+1) + "#" + Music()\TrackName
      If NextElement(Music())
        ReadyMusic(readytracks) + "#" + Str(readytracks+2) + "#" + Music()\TrackName
        PreviousElement(Music())
      EndIf
      ReadyMusic(readytracks)+"#%"
      readytracks+1
    Until readytracks=tracks
    
  Else
    WriteLog("NO MUSIC LIST",Server)
    AddElement(Music())
    Music()\TrackName="NO MUSIC LIST"
    ReadyMusic(0) = "MD#0#NO MUSIC LIST#%"
    musicpage=0
    tracks=1
  EndIf
  
  If ReadFile(2, "mod.txt")
    ClearList(HDmods())
    While Eof(2) = 0
      hdmod$=ReadString(2)
      If hdmod$<>""
        AddElement(HDmods())
        HDmods()=hdmod$
      EndIf
    Wend
    CloseFile(2)
  Else
    If CreateFile(2, "mod.txt")
      WriteStringN(2, "127.0.0.1")
      CloseFile(2)
    EndIf
  EndIf
  
  
  If OpenPreferences( "base/scene/"+scene$+"/items.ini")
    PreferenceGroup("Items")
    itemamount=ReadPreferenceInteger("number",1)
    For loaditems=0 To itemamount-1
      PreferenceGroup("Items")
      Items(loaditems)\name=ReadPreferenceString(Str(loaditems+1),"Penis") 
      PreferenceGroup("price")
      Items(loaditems)\price=ReadPreferenceInteger(Str(loaditems+1),0) 
      PreferenceGroup("filename")
      Items(loaditems)\filename=ReadPreferenceString(Str(loaditems+1),"bb_underwear")
      PreferenceGroup("desc")
      Items(loaditems)\desc=ReadPreferenceString(Str(loaditems+1),"Very short. Must be Fiercys.")
      ReadyVItem(loaditems)="ID#"+Str(loaditems+1)+"#"+Items(loaditems)\name+"#"+Items(loaditems)\filename+"#"+Items(loaditems)\desc+"#"+Str(Items(loaditems)\price)+"#%"
    Next  
    ClosePreferences()
  Else
    If CreatePreferences("base/scene/"+scene$+"/items.ini")
      PreferenceGroup("Items")
      WritePreferenceInteger("number",1)
      WritePreferenceString("1","Penis")
      PreferenceGroup("filename")
      WritePreferenceString("1","bb_underwear")
      ClosePreferences()
    EndIf
  EndIf
  
  
  If OpenPreferences( "base/scene/"+scene$+"/areas.ini")
    PreferenceGroup("Areas")
    Aareas=ReadPreferenceInteger("number",1)
    areas(0)\name="INVALID"
    areas(0)\bg="Void"
    areas(0)\pw=""
    For loadareas=1 To Aareas
      PreferenceGroup("Areas")
      aname$=ReadPreferenceString(Str(loadareas),"Cafeteria") 
      areas(loadareas)\name=aname$
      PreferenceGroup("filename")
      area$=ReadPreferenceString(Str(loadareas),"Cafeteria") 
      areas(loadareas)\bg=area$
      PreferenceGroup("pass")
      areas(loadareas)\pw=ReadPreferenceString(Str(loadareas),"")
    Next  
    ClosePreferences()
  Else
    If CreatePreferences("base/scene/"+scene$+"/areas.ini")
      PreferenceGroup("Areas")
      WritePreferenceInteger("number",1)
      WritePreferenceString("1",background)
      PreferenceGroup("filename")
      WritePreferenceString("1",background)
      areas(0)\bg=background
      Aareas=1
      ClosePreferences()
    EndIf
  EndIf
  
  If ReadFile(2, "serverv.txt")
    ReadString(2)
    ReadString(2)
    ReadString(2)
    ClearList(SDbans())
    While Eof(2) = 0
      hdban$=ReadString(2)
      If hdban$<>""
        AddElement(SDbans())
        SDbans()\banned=StringField(hdban$,1,"#")
        SDbans()\time=Val(StringField(hdban$,2,"#"))
        SDbans()\reason=StringField(hdban$,3,"#")
        SDbans()\type=Val(StringField(hdban$,4,"#"))
      EndIf
    Wend  
    CloseFile(2)
  EndIf
  
  If ReadFile(2, "banip.txt")
    ClearList(IPbans())
    While Eof(2) = 0
      ipban$=ReadString(2)
      If ipban$<>""
        AddElement(IPbans())
        IPbans()\banned=StringField(ipban$,1,"#")
        IPbans()\time=Val(StringField(ipban$,2,"#"))
        IPbans()\reason=StringField(ipban$,3,"#")
        IPbans()\type=Val(StringField(ipban$,4,"#"))
      EndIf
    Wend
    CloseFile(2)
  EndIf
  
  ;   If ReadFile(2, "banuser.txt")
  ;     ClearList(Userbans())
  ;     While Eof(2) = 0
  ;       ipban$=ReadString(2)
  ;       If ipban$<>""
  ;         AddElement(Userbans())
  ;         Userbans()=ipban$
  ;       EndIf
  ;     Wend
  ;     CloseFile(2)
  ;   EndIf
  
EndProcedure

Procedure SendTarget(user$,message$,*sender.Client)
  Define everybody,i,omessage$,sresult
  omessage$=message$
  
  If user$="*" Or user$="everybody"
    everybody=1
  Else
    everybody=0
  EndIf
  
  For i=0 To characternumber-1
    If Characters(i)\name=user$
      user$=Str(i)
      Break
    EndIf
  Next
  
  LockMutex(ListMutex)
  
  If FindMapElement(Clients(),user$)
    
    If Clients()\websocket
      CompilerIf #WEB
        Websocket_SendTextFrame(Clients()\ClientID,message$)
      CompilerEndIf
    Else
      Debug message$
      sresult=SendNetworkString(Clients()\ClientID,message$)  
      If sresult=-1
        WriteLog("CLIENT DIED DIRECTLY",Clients())
        If areas(Clients()\area)\lock=Clients()\ClientID
          areas(Clients()\area)\lock=0
          areas(Clients()\area)\mlock=0
        EndIf
        DeleteMapElement(Clients(),Str(Clients()\ClientID))
        rf=1
      EndIf
    EndIf
  Else
    ResetMap(Clients())
    While NextMapElement(Clients())
      If user$=Str(Clients()\CID) Or user$=Clients()\HD Or user$=Clients()\IP Or user$=Clients()\username Or user$="Area"+Str(Clients()\area) Or (everybody And (*sender\area=Clients()\area Or *sender\area=-1)) And Clients()\master=*sender\master
        If Clients()\websocket
          CompilerIf #WEB
            Websocket_SendTextFrame(Clients()\ClientID,message$)
          CompilerEndIf
        Else
          Debug message$
          sresult=SendNetworkString(Clients()\ClientID,message$)
          If sresult=-1
            WriteLog("CLIENT DIED",Clients())
            If areas(Clients()\area)\lock=Clients()\ClientID
              areas(Clients()\area)\lock=0
              areas(Clients()\area)\mlock=0
            EndIf
            DeleteMapElement(Clients(),Str(Clients()\ClientID))
            rf=1
          EndIf
        EndIf
      EndIf
    Wend   
  EndIf
  UnlockMutex(ListMutex)
EndProcedure

Procedure MSWait(*usagePointer.Client)
  Define wttime,wtarea
  wtarea=*usagePointer\area
  wttime=Len(Trim(StringField(*usagePointer\last,7,"#")))*60
  wttime-20
  If wttime<10
    wttime=10
  ElseIf wttime>5000
    wttime=5000
  EndIf
  Delay(wttime)
  areas(wtarea)\wait=0
EndProcedure

Procedure TrackWait(a)
  Define stoploop,k,cw
  cw=1000
  Repeat
    For k=0 To AreaNumber-1
      If Areas(k)\trackwait>1
        If Areas(k)\trackwait<cw
          cw=Areas(k)\trackwait
        EndIf
        Debug ElapsedMilliseconds()
        If (Areas(k)\trackstart+Areas(k)\trackwait)<ElapsedMilliseconds()
          Areas(k)\trackstart=ElapsedMilliseconds()
          Debug "changed"
          SendTarget("Area"+Str(k),"MC#"+Areas(k)\track+"#"+Str(characternumber)+"#%",Server)
        EndIf
      EndIf
    Next
    Delay(cw)
  Until LoopMusic=0
EndProcedure

Procedure ListIP(ClientID)
  Define iplist$
  Define charname$
  iplist$="IL#"
  LockMutex(ListMutex)
  PushMapPosition(Clients())
  ResetMap(Clients())
  While NextMapElement(Clients())
    Select Clients()\perm
      Case 1
        charname$=GetCharacterName(Clients())+"(mod)"
      Case 2
        charname$=GetCharacterName(Clients())+"(admin)"
      Case 3
        charname$=GetCharacterName(Clients())+"(server) also this is not good, you better see a sDoctor"
      Default
        charname$=GetCharacterName(Clients())
    EndSelect
    iplist$=iplist$+Clients()\IP+"|"+charname$+"|"+Str(Clients()\CID)+"|*"
  Wend
  PopMapPosition(Clients())
  UnlockMutex(ListMutex)
  iplist$=iplist$+"#%"
  SendTarget(Str(ClientID),iplist$,Server) 
EndProcedure

Procedure ListAreas(ClientID)
  Define iplist$
  Define charname$
  iplist$="IL#"
  LockMutex(ListMutex)
  PushMapPosition(Clients())
  ResetMap(Clients())
  While NextMapElement(Clients())
    Select Clients()\perm
      Case 1
        charname$=GetCharacterName(Clients())+"(mod)"+" in "+GetAreaName(Clients())
      Case 2
        charname$=GetCharacterName(Clients())+"(admin)"+" in "+GetAreaName(Clients())
      Case 3
        charname$=GetCharacterName(Clients())+"(server)"+" in "+GetAreaName(Clients())
      Default
        charname$=GetCharacterName(Clients())+" in "+GetAreaName(Clients())
    EndSelect
    iplist$=iplist$+Clients()\IP+"|"+charname$+"|"+Str(Clients()\area)+"|*"
  Wend
  PopMapPosition(Clients())
  UnlockMutex(ListMutex)
  iplist$=iplist$+"#%"
  SendTarget(Str(ClientID),iplist$,Server) 
EndProcedure

ProcedureDLL MasterAdvert(Port)
  Define msID=0,msinfo,NEvent,msPort=27016,retries,tick
  Define sr=-1
  Define  *null=AllocateMemory(512)
  Define master$,msrec$
  WriteLog("Masterserver adverter thread started",Server)
  OpenPreferences("base/masterserver.ini")
  PreferenceGroup("list")
  master$=ReadPreferenceString("0","51.255.160.217")
  msPort=ReadPreferenceInteger("Port",27016)
  ClosePreferences()
  
  WriteLog("Using master "+master$, Server)
  
  If public
    Repeat
      
      If msID
        
        If tick>10
          sr=SendNetworkString(msID,"PING#%")
        EndIf
        
        NEvent=NetworkClientEvent(msID)
        If NEvent=#PB_NetworkEvent_Disconnect
          msID=0
        ElseIf NEvent=#PB_NetworkEvent_Data
          msinfo=ReceiveNetworkData(msID,*null,512)
          If msinfo=-1
            msID=0
          Else
            msrec$=PeekS(*null,msinfo)
            Debug msrec$
            If msrec$="NOSERV#%"
              WriteLog("Fell off the serverlist, fixing...",Server)
              sr=SendNetworkString(msID,"SCC#"+Str(Port)+"#"+msname$+"#"+desc$+"#serverV "+version$+"#%"+Chr(0))
              WriteLog("Server published!",Server)
            EndIf
            tick=0
            retries=0
          EndIf
        EndIf
        
      Else
        retries+1
        WriteLog("Masterserver adverter thread connecting...",Server)
        msID=OpenNetworkConnection(master$,msPort)
        If msID
          Server\ClientID=msID
          sr=SendNetworkString(msID,"SCC#"+Str(Port)+"#"+msname$+"#"+desc$+"#serverV "+version$+"#%"+Chr(0))
          WriteLog("Server published!",Server)
        EndIf
      EndIf
      If tick>100
        WriteLog("Masterserver adverter thread timed out",Server)
        If msID
          CloseNetworkConnection(msID)
        EndIf
        Server\ClientID=0
        msID=0
      EndIf
      Delay(3000)
      tick+1
    Until public=0
  EndIf
  WriteLog("Masterserver adverter thread stopped",Server)
  If msID
    CloseNetworkConnection(msID)
  EndIf
  FreeMemory(*null)
  msthread=0
EndProcedure

Procedure SendAreas(ClientID)
  Define send$
  Define sentchar
  Dim APlayers(Aareas-1)
  LockMutex(ListMutex)
  ResetMap(Clients())
  While NextMapElement(Clients())
    If Clients()\area>=0 And  Clients()\area<=Aareas-1
      APlayers(Clients()\area)+1
    EndIf
  Wend
  For adareas=0 To Aareas-1
    If APlayers(adareas)>0
      send$=send$+"RaC#"+Str(adareas+1)+"#"+Str(APlayers(adareas))+"#%"
    EndIf
  Next
  Debug send$
  SendTarget("*",send$,Server)
  UnlockMutex(ListMutex)
EndProcedure

Procedure SendDone(*usagePointer.Client)
  Define send$
  Define sentchar
  Dim APlayers(characternumber)
  
  
  send$="CharsCheck"
  LockMutex(ListMutex)
  PushMapPosition(Clients())
  ResetMap(Clients())
  While NextMapElement(Clients())
    If Clients()\CID>=0 And Clients()\CID <= characternumber
      If Clients()\area=*usagePointer\area
        APlayers(Clients()\CID)=-1
      EndIf
    EndIf
  Wend
  PopMapPosition(Clients())
  UnlockMutex(ListMutex)
  For sentchar=0 To characternumber
    If APlayers(sentchar)=-1 Or  Characters(sentchar)\pw<>""
      send$ = send$ + "#-1"
    Else
      send$ = send$ + "#0"
    EndIf
  Next
  send$ = send$ + "#%"
  SendTarget(Str(*usagePointer\ClientID),send$,Server)
  SendTarget(Str(*usagePointer\ClientID),"BN#"+areas(*usagePointer\area)\bg+"#%",Server)
  SendTarget(Str(*usagePointer\ClientID),"MM#"+Str(musicmode)+"#%",Server)
  SendTarget(Str(*usagePointer\ClientID),"DONE#%",Server)
EndProcedure

Procedure SwitchAreas(*usagePointer.Client,narea$)
  Define sendd=0
  Define ir
  Debug narea$
  For ir=0 To AreaNumber-1
    areas(ir)\players=0
    Debug areas(ir)\name
    If areas(ir)\name = narea$
      narea$ = Str(ir)
      Break
    EndIf
  Next
  
  LockMutex(ListMutex)
  PushMapPosition(Clients())
  ResetMap(Clients())
  While NextMapElement(Clients())
    If Clients()\CID=*usagePointer\CID And Clients()\ClientID<>*usagePointer\ClientID
      If Clients()\area=Val(narea$) Or MultiChar=0
        sendd=1
      EndIf
    EndIf
    If Clients()\area>=0
      areas(Clients()\area)\players+1
    EndIf
  Wend
  PopMapPosition(Clients())
  UnlockMutex(ListMutex)
  
  If narea$="0"
    If areas(*usagePointer\area)\lock=*usagePointer\ClientID
      areas(*usagePointer\area)\lock=0
      areas(*usagePointer\area)\mlock=0
    EndIf
    areas(*usagePointer\area)\players-1
    *usagePointer\area=0
    areas(0)\players+1
    If sendd=1
      *usagePointer\CID=-1
      SendDone(*usagePointer)
      SendTarget(Str(*usagePointer\ClientID),"CT#$HOST#area 0 selected#%",Server)
    Else
      SendTarget(Str(*usagePointer\ClientID),"BN#"+areas(0)\bg+"#%",Server)
      SendTarget(Str(*usagePointer\ClientID),"CT#$HOST#area 0 selected#%",Server)
    EndIf
    SendTarget(Str(*usagePointer\ClientID),"HP#1#"+Str(Areas(0)\good)+"#%",Server)
    SendTarget(Str(*usagePointer\ClientID),"HP#2#"+Str(Areas(0)\evil)+"#%",Server)
  Else
    If Val(narea$)<=AreaNumber-1 And Val(narea$)>=0
      If Not areas(Val(narea$))\lock Or *usagePointer\perm>areas(Val(narea$))\mlock
        If areas(*usagePointer\area)\lock=*usagePointer\ClientID
          areas(*usagePointer\area)\lock=0
          areas(*usagePointer\area)\mlock=0
        EndIf
        areas(*usagePointer\area)\players-1
        *usagePointer\area=Val(narea$)
        areas(*usagePointer\area)\players+1
        If sendd=1
          *usagePointer\CID=-1
          SendDone(*usagePointer)
          SendTarget(Str(*usagePointer\ClientID),"CT#$HOST#area "+Str(*usagePointer\area)+" selected#%",Server)
        Else
          SendTarget(Str(*usagePointer\ClientID),"BN#"+areas(*usagePointer\area)\bg+"#%",Server)
          SendTarget(Str(*usagePointer\ClientID),"CT#$HOST#area "+Str(*usagePointer\area)+" selected#%",Server)
        EndIf
        SendTarget(Str(*usagePointer\ClientID),"HP#1#"+Str(Areas(*usagePointer\area)\good)+"#%",Server)
        SendTarget(Str(*usagePointer\ClientID),"HP#2#"+Str(Areas(*usagePointer\area)\evil)+"#%",Server)
      Else
        SendTarget(Str(*usagePointer\ClientID),"CT#$HOST#area locked#%",Server)
      EndIf
    Else
      SendTarget(Str(*usagePointer\ClientID),"CT#$HOST#Not a valid area#%",Server)
    EndIf
  EndIf
EndProcedure

Procedure KickBan(kick$,param$,action,*usagePointer.Client)
  Define actionn$
  Define akck,newchar=-1
  Define everybody
  Define i,kclid,kcid
  akck=0
  If kick$="everybody" Or kick$="*"
    everybody=1
  EndIf
  Debug "kick$"
  Debug kick$
  LockMutex(ListMutex)
  ResetMap(Clients())
  While NextMapElement(Clients())
    kclid=Clients()\ClientID
    kcid=Clients()\CID
    Debug "wkick$"
    Debug kick$
    Debug kclid
    If Clients()\ClientID
      If kick$=Str(kcid) Or kick$=Str(kclid) Or kick$=ReplaceString(GetCharacterName(Clients())," ","_") Or kick$=Clients()\HD Or kick$=Clients()\IP Or kick$="Area"+Str(Clients()\area) Or everybody
        If Clients()\perm<*usagePointer\perm Or (*usagePointer\perm And Clients()=*usagePointer)
          LockMutex(ActionMutex)
          Select action
            Case #KICK
              DeleteMapElement(Clients())
              SendNetworkString(kclid,"KK#"+Str(kcid)+"#"+param$+"#%")
              CloseNetworkConnection(kclid) 
              actionn$="kicked"
              akck+1
              
            Case #DISCO
              DeleteMapElement(Clients())
              CloseNetworkConnection(kclid) 
              actionn$="disconnected"
              akck+1
              
            Case #BAN
              If Clients()\IP<>"127.0.0.1"
                If kick$=Clients()\HD
                  AddElement(HDbans())
                  HDbans()\banned=Clients()\HD
                  HDbans()\reason=param$
                  HDbans()\time=btime
                  HDbans()\type=#BAN
                  If OpenFile(2,"base/HDbanlist.txt")
                    FileSeek(2,Lof(2))
                    WriteStringN(2,Clients()\HD+"#"+ HDbans()\reason+"#"+Str(HDbans()\time)+"#"+Str(#BAN))
                    CloseFile(2)
                  EndIf
                Else
                  AddElement(IPbans())
                  IPbans()\banned=Clients()\IP
                  IPbans()\reason=param$
                  IPbans()\time=btime
                  IPbans()\type=#BAN
                  If OpenFile(2,"base/banlist.txt")
                    FileSeek(2,Lof(2))
                    WriteStringN(2,Clients()\IP+"#"+IPbans()\reason+"#"+Str(IPbans()\time)+"#"+Str(#BAN))
                    CloseFile(2)
                  EndIf
                EndIf
                DeleteMapElement(Clients())
                SendNetworkString(kclid,"KB#"+Str(kcid)+"#"+param$+"#%")
                CloseNetworkConnection(kclid)  
                actionn$="banned"
                akck+1
              EndIf
              
            Case #MUTE
              SendNetworkString(kclid,"MU#"+Str(kcid)+"#%")
              actionn$="muted"
              akck+1
              AddElement(Actions())
              Actions()\IP=Clients()\IP
              Actions()\type=#MUTE
              
            Case #UNMUTE
              SendNetworkString(kclid,"UM#"+kcid+"#%")
              actionn$="unmuted"
              akck+1
              ResetList(Actions())
              While NextElement(Actions())
                If Actions()\IP=Clients()\IP And Actions()\type=#MUTE
                  DeleteElement(Actions())
                EndIf
              Wend
              
            Case #CIGNORE
              Clients()\ignore=1
              actionn$="ignored"
              akck+1
              
            Case #UNIGNORE
              Clients()\ignore=0
              actionn$="undignored"
              akck+1
              ResetList(Actions())
              While NextElement(Actions())
                If Actions()\IP=Clients()\IP And Actions()\type=#CIGNORE
                  DeleteElement(Actions())
                EndIf
              Wend
              
            Case #UNDJ
              Clients()\ignoremc=1
              actionn$="undj'd"
              akck+1
              AddElement(Actions())
              Actions()\IP=Clients()\IP
              Actions()\type=#UNDJ
              
            Case #DJ
              Clients()\ignoremc=0
              actionn$="dj'd"
              akck+1
              ResetList(Actions())
              While NextElement(Actions())
                If Actions()\IP=Clients()\IP And Actions()\type=#UNDJ
                  DeleteElement(Actions())
                EndIf
              Wend
              
            Case #GIMP
              Clients()\gimp=1
              actionn$="gimped"
              akck+1
              AddElement(Actions())
              Actions()\IP=Clients()\IP
              Actions()\type=#GIMP
              
            Case #UNGIMP
              Clients()\gimp=0
              actionn$="ungimped"
              akck+1
              ResetList(Actions())
              While NextElement(Actions())
                If Actions()\IP=Clients()\IP And Actions()\type=#GIMP
                  DeleteElement(Actions())
                EndIf
              Wend
              
            Case #SWITCH
              Debug "swkick$"
              Debug kick$
              Debug kclid
              actionn$="switched"              
              For scid=0 To CharacterNumber
                If param$=ReplaceString(Characters(scid)\name," ","_")
                  newchar=scid
                  Break
                EndIf
              Next
              If newchar<>-1
                Clients()\CID=newchar
                akck+1
                SendTarget(Str(Clients()\ClientID),"PV#"+Str(Clients()\AID)+"#CID#"+Str(newchar)+"#%",Server)
              Else
                Clients()\CID=-1 
                akck+1
                SendTarget(Str(Clients()\ClientID),"DONE#%",Server)
              EndIf
            Case #MOVE
              SwitchAreas(Clients(),param$)
              
          EndSelect
          UnlockMutex(ActionMutex)
        EndIf
      EndIf
    Else
      DeleteMapElement(Clients())
      actionn$+" whoopie "
      akck+1
    EndIf
  Wend
  UnlockMutex(ListMutex)
  Debug "akick$"
  Debug kick$
  WriteLog("["+GetCharacterName(*usagePointer)+"] "+actionn$+" "+kick$+", "+Str(akck)+" people died.",*usagePointer)
  rf=1
  ProcedureReturn akck
EndProcedure

;- Command Handler
Procedure CheckInternetCode(ClientID)
  
  If ClientID>0
    *usagePointer.Client=FindMapElement(Clients(),Str(ClientID))
    Debug "sc"
  ElseIf ClientID=-1
    *usagePointer.Client=@Server
    Debug "server"
  Else
    *usagePointer=0
    Debug "error"
  EndIf
  
  If *usagePointer  
    rawreceive$=*usagePointer\last
    comm$=StringField(rawreceive$,1,"#")
    length=Len(rawreceive$)
    ClientID=*usagePointer\ClientID
    Select comm$
      Case "MS"
        WriteLog("["+GetCharacterName(*usagePointer)+"]["+StringField(rawreceive$,4,"#")+"]",*usagePointer)
        If areas(*usagePointer\area)\wait=0 Or *usagePointer\perm
          msreply$=rawreceive$
          Sendtarget("*",msreply$,*usagePointer)
          areas(*usagePointer\area)\wait=*usagePointer\ClientID
          CreateThread(@MSWait(),*usagePointer)
        EndIf
        send=0
        
      Case "MC"
        music=0
        LockMutex(musicmutex)
        ForEach Music()
          If StringField(rawreceive$,3,"#")=Music()\TrackName
            music=1
            Debug "found music"
            Break
          EndIf
        Next
        UnlockMutex(musicmutex)
        Debug StringField(rawreceive$,2,"#")
        If Not (music=0 Or GetCharacterName(*usagePointer) <> StringField(rawreceive$,2,"#"))
          
          If *usagePointer\ignoremc=0
            Sendtarget("*","MC#"+GetCharacterName(*usagePointer)+"#"+StringField(rawreceive$,3,"#")+"#"+areas(*usagePointer\area)\bg+"#"+Str(*usagePointer\CID)+"#%",*usagePointer)
            WriteLog("["+GetCharacterName(*usagePointer)+"] changed music to "+StringField(rawreceive$,3,"#"),*usagePointer)
          EndIf
          ;         
        Else
          WriteLog("["+GetCharacterName(*usagePointer)+"] tried changing music to "+StringField(rawreceive$,3,"#"),*usagePointer)
        EndIf 
        
        ;- ooc commands
      Case "CT"
        send=0
        *usagePointer\last.s=""
        ctparam$=StringField(rawreceive$,4,"#")
        WriteLog("[OOC]["+GetCharacterName(*usagePointer)+"]["+StringField(rawreceive$,3,"#")+"]["+ctparam$+"]",*usagePointer)
        
        If *usagePointer\username=""
          *usagePointer\username=StringField(rawreceive$,3,"#")
        EndIf
        
        Debug ctparam$
        If Left(ctparam$,1)="/"
          Select StringField(ctparam$,1," ")
              
            Case "/bg"
              If *usagePointer\perm                            
                bgcomm$=Mid(ctparam$,5)
                areas(*usagePointer\area)\bg=bgcomm$
                Sendtarget("Area"+Str(*usagePointer\area),"BN#"+bgcomm$+"#%",*usagePointer)                      
              EndIf
              
              
            Case "/change"
              nchar$=Mid(ctparam$,9)
              For nch=0 To CharacterNumber
                If Characters(nch)\name=nchar$
                  If BlockTaken=1
                    LockMutex(ListMutex)
                    PushMapPosition(Clients())
                    ResetMap(Clients())
                    While NextMapElement(Clients())
                      If Clients()\CID=nch
                        If Clients()\area=*usagePointer\area
                          akchar=1
                          Break
                        Else
                          akchar=0
                        EndIf
                        If MultiChar=0
                          akchar=1
                          Break
                        EndIf
                      EndIf
                    Wend
                    PopMapPosition(Clients())
                    UnlockMutex(ListMutex)     
                  EndIf
                  If akchar=0 Or *usagePointer\CID=nch Or BlockTaken=0
                    SendTarget(Str(ClientID),"PV#"+Str(*usagePointer\AID)+"#CID#"+Str(nch)+"#%",Server)               
                    *usagePointer\CID=nch       
                    WriteLog("chose character: "+GetCharacterName(*usagePointer),*usagePointer)
                    SendTarget(Str(ClientID),"HP#1#"+Str(Areas(*usagePointer\area)\good)+"#%",Server)
                    SendTarget(Str(ClientID),"HP#2#"+Str(Areas(*usagePointer\area)\evil)+"#%",Server)
                  EndIf
                  Break
                  rf=1
                EndIf
              Next
              
            Case "/switch"
              If Mid(ctparam$,9)=""
                *usagePointer\cid=-1
                SendDone(*usagePointer)
              Else
                KickBan(StringField(ctparam$,2," "),StringField(ctparam$,3," "),#SWITCH,*usagePointer)
              EndIf
              
            Case "/move"
              KickBan(StringField(ctparam$,2," "),StringField(ctparam$,3," "),#MOVE,*usagePointer)
              
            Case "/online"
              players=0          
              LockMutex(ListMutex)
              PushMapPosition(Clients())
              ResetMap(Clients())
              While NextMapElement(Clients())
                If Clients()\CID>=0
                  players+1
                EndIf
              Wend
              UnlockMutex(ListMutex)
              SendTarget(Str(ClientID),"CT#$HOST#"+Str(players)+"/"+slots$+" characters online#%",Server)
              
            Case "/loadreplay"
              If *usagePointer\perm>1                  
                ReplayFile$="base/replays/"+Mid(ctparam$,13)
                If ReadFile(8, ReplayFile$)
                  Debug "loaded replay"
                  ClearList(PReplay())
                  ResetList(PReplay())
                  While Eof(8) = 0
                    rline$=ReadString(8)
                    AddElement(PReplay())
                    ReplayMode=1
                    PReplay()=rline$
                  Wend
                  ResetList(PReplay())
                  CloseFile(8)
                EndIf
              EndIf
              
            Case "/lock"
              If *usagePointer\area
                lock$=StringField(ctparam$,2," ")
                Select lock$
                  Case "0"
                    areas(*usagePointer\area)\lock=0
                    areas(*usagePointer\area)\mlock=0
                    SendTarget(Str(ClientID),"CT#$HOST#area unlocked#%",Server)
                  Case "1"
                    areas(*usagePointer\area)\lock=*usagePointer\ClientID
                    areas(*usagePointer\area)\mlock=0
                    SendTarget(Str(ClientID),"CT#$HOST#area locked#%",Server)
                  Case "2"
                    If *usagePointer\perm
                      areas(*usagePointer\area)\lock=*usagePointer\ClientID
                      areas(*usagePointer\area)\mlock=1
                      SendTarget(Str(ClientID),"CT#$HOST#area superlocked#%",Server)
                    EndIf
                  Default
                    pr$="CT#$HOST#area is "
                    If areas(*usagePointer\area)\lock=0
                      pr$+"not "
                    EndIf
                    SendTarget(Str(ClientID),pr$+"locked#%",Server)
                EndSelect
              Else
                SendTarget(Str(ClientID),"CT#$HOST#You can't lock the default area#%",Server)
              EndIf
              
            Case "/skip"
              If *usagePointer\perm
                *usagePointer\skip=1
              EndIf
              
            Case "/noskip"
              If *usagePointer\perm
                *usagePointer\skip=0
              EndIf
              
            Case "/toggle"
              If *usagePointer\perm
                status$="invalid"
                Select StringField(ctparam$,2," ")
                  Case "WTCE"
                    If rt
                      rt=0
                      status$="disabled"
                    Else
                      rt=1
                      status$="enabled"
                    EndIf
                  Case "LogHD"
                    If loghd
                      loghd=0
                      status$="disabled"
                    Else
                      loghd=1
                      status$="enabled"
                    EndIf
                  Case "ExpertLog"
                    If ExpertLog
                      ExpertLog=0
                      status$="disabled"
                    Else
                      ExpertLog=1
                      status$="enabled"
                    EndIf
                  Case "Threading"
                    If CommandThreading
                      CommandThreading=0
                      status$="disabled"
                    Else
                      CommandThreading=1
                      status$="enabled"
                    EndIf
                EndSelect
                SendTarget(Str(ClientID),"CT#$HOST#"+StringField(ctparam$,2," ")+" is "+status$+"#%",Server)
              EndIf
              
            Case "/snapshot"
              If *usagePointer\perm>1
                If CreateFile(33,"snap.txt")
                  LockMutex(ListMutex)
                  PushMapPosition(Clients())
                  ResetMap(Clients())
                  While NextMapElement(Clients())
                    WriteStringN(33,"Client "+Str(Clients()\ClientID))
                    WriteStringN(33,Clients()\IP)
                    WriteStringN(33,Str(Clients()\CID))
                    WriteStringN(33,Str(Clients()\perm))
                    WriteStringN(33,Str(Clients()\hack))
                    WriteStringN(33,Str(Clients()\area))
                    WriteStringN(33,Clients()\last)
                  Wend
                  PopMapPosition(Clients())
                  UnlockMutex(ListMutex)
                  LockMutex(ListMutex)
                  For sa=0 To areas
                    WriteStringN(33,"Area "+Str(sa))
                    WriteStringN(33,Areas(sa)\name)
                    WriteStringN(33,Areas(sa)\bg)
                    WriteStringN(33,Str(Areas(sa)\players))
                    WriteStringN(33,Str(Areas(sa)\lock))
                    WriteStringN(33,Str(Areas(sa)\mlock))
                    WriteStringN(33,Areas(sa)\track)
                    WriteStringN(33,Str(Areas(sa)\trackwait))
                  Next
                  CloseFile(33)
                EndIf
              EndIf
              
            Case "/smokeweed"
              reply$="CT#stonedDiscord#where da weed at#%"
              WriteLog("smoke weed everyday",*usagePointer)
              
            Case "/help"
              SendTarget(Str(ClientID),"CT#SERVER#Check https://github.com/stonedDiscord/serverV/blob/master/README.md#%",Server)
              
            Case "/public"
              Debug ctparam$
              If StringField(ctparam$,2," ")=""
                pr$="CT#$HOST#server is "
                If public=0
                  pr$+"not "
                EndIf
                SendTarget(Str(ClientID),pr$+"public#%",Server)
              Else
                If *usagePointer\perm>1
                  public=Val(StringField(ctparam$,2," "))
                  If public
                    msthread=CreateThread(@MasterAdvert(),Port)
                    SendTarget(Str(ClientID),"CT#$HOST# published server#%",Server)
                  EndIf
                EndIf
              EndIf
              
            Case "/send"  
              If *usagePointer\perm>1
                sname$=StringField(ctparam$,2," ")
                Debug sname$
                smes$=Mid(ctparam$,8+Len(sname$),Len(ctparam$)-6)
                smes$=Escape(smes$)
                SendTarget(sname$,smes$,Server)
              EndIf
              
            Case "/sendall"
              If *usagePointer\perm
                smes$=Mid(ctparam$,10)
                smes$=Escape(smes$)
                SendTarget("*",smes$,Server)
              EndIf
              
            Case "/reload"
              If *usagePointer\perm>1
                LoadServer(1)
                SendTarget(Str(ClientID),"CT#$HOST#serverV reloaded#%",Server)
              EndIf
              
            Case "/play"
              If *usagePointer\perm                
                song$=Right(ctparam$,Len(ctparam$)-6)
                SendTarget("Area"+Str(*usagePointer\area),"MC#"+song$+"#"+Str(*usagePointer\CID)+"#%",*usagePointer)                
              EndIf
              
            Case "/hd"
              If *usagePointer\perm
                kick$=Mid(ctparam$,5,Len(ctparam$)-2)
                If kick$="" Or kick$="*"
                  everybody=1
                Else
                  everybody=0
                EndIf
                hdlist$="IL#"
                LockMutex(ListMutex)
                ResetMap(Clients())
                While NextMapElement(Clients())                   
                  If kick$=Str(Clients()\CID) Or kick$=Clients()\HD Or kick$=Clients()\IP Or everybody
                    hdlist$=hdlist$+Clients()\IP+"|"+Str(Clients()\CID)+"|"+Clients()\HD+"|*"                        
                  EndIf
                Wend
                UnlockMutex(ListMutex)
                SendTarget(Str(ClientID),hdlist$+"#%",Server)
                WriteLog("["+GetCharacterName(*usagePointer)+"] used /hd",*usagePointer)
              EndIf 
              
              
            Case "/unban"
              If *usagePointer\perm>1
                ub$=Mid(ctparam$,8,Len(ctparam$))
                Debug ub$
                If CreateFile(2,"base/banlist.txt")
                  Debug "file recreated"
                  ForEach IPbans()
                    If IPbans()\banned=ub$
                      DeleteElement(IPbans())
                    Else
                      WriteStringN(2,IPbans()\banned+"#"+IPbans()\reason+"#"+Str(IPbans()\time)+"#"+Str(IPbans()\type))
                    EndIf
                  Next
                  CloseFile(2)                                
                EndIf
                
                If CreateFile(2,"base/HDbanlist.txt")
                  ForEach HDbans()
                    If HDbans()\banned=ub$
                      DeleteElement(HDbans())
                    Else
                      WriteStringN(2,HDbans()\banned+"#"+HDbans()\reason+"#"+Str(HDbans()\time)+"#"+Str(HDbans()\type))
                    EndIf
                  Next
                  CloseFile(2)                                
                EndIf
              EndIf
              
            Case "/stop"
              If *usagePointer\perm>1
                public=0
                WriteLog("stopping server...",*usagePointer)
                Quit=1
              EndIf
              
            Case "/kick"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,7),StringField(ctparam$,3," "),#KICK,*usagePointer)
                SendTarget(Str(ClientID),"CT#$HOST#kicked "+Str(akck)+" clients#%",Server) 
              EndIf
              
            Case "/disconnect"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,13),StringField(ctparam$,3," "),#DISCO,*usagePointer)
                SendTarget(Str(ClientID),"CT#$HOST#disconnected "+Str(akck)+" clients#%",Server) 
              EndIf
              
            Case "/ban"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,6),StringField(ctparam$,3," "),#BAN,*usagePointer)
                SendTarget(Str(ClientID),"CT#$HOST#banned "+Str(akck)+" clients#%",Server)
              EndIf
              
            Case "/mute"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,7),StringField(ctparam$,3," "),#MUTE,*usagePointer)
                SendTarget(Str(ClientID),"CT#$HOST#muted "+Str(akck)+" clients#%",Server)
              EndIf
              
              
            Case "/unmute"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,9),StringField(ctparam$,3," "),#UNMUTE,*usagePointer)
                SendTarget(Str(ClientID),"CT#$HOST#unmuted "+Str(akck)+" clients#%",Server)
              EndIf
              
              
            Case "/ignore"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,9),StringField(ctparam$,3," "),#CIGNORE,*usagePointer)
                SendTarget(Str(ClientID),"CT#$HOST#muted "+Str(akck)+" clients#%",Server)
              EndIf
              
              
            Case "/unignore"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,11),StringField(ctparam$,3," "),#UNIGNORE,*usagePointer)
                SendTarget(Str(ClientID),"CT#$HOST#unmuted "+Str(akck)+" clients#%",Server)
              EndIf
              
              
            Case "/undj"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,7),StringField(ctparam$,3," "),#UNDJ,*usagePointer)
                SendTarget(Str(ClientID),"CT#$HOST#muted "+Str(akck)+" clients#%",Server)
              EndIf
              
              
            Case "/dj"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,5),StringField(ctparam$,3," "),#DJ,*usagePointer)
                SendTarget(Str(ClientID),"CT#$HOST#unmuted "+Str(akck)+" clients#%",Server)
              EndIf
              
            Case "/gimp"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,7),StringField(ctparam$,3," "),#GIMP,*usagePointer)
                SendNetworkString(ClientID,"CT#$HOST#gimped "+Str(akck)+" clients#%")
              EndIf
              
            Case "/ungimp"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,9),StringField(ctparam$,3," "),#UNGIMP,*usagePointer)
                SendNetworkString(ClientID,"CT#$HOST#ungimped "+Str(akck)+" clients#%")
              EndIf
              
            Case "/version"
              SendTarget(Str(ClientID),"CT#$HOST#serverV "+version$+"#%",Server)
              
          EndSelect
        Else
          *usagePointer\last.s=rawreceive$
          SendTarget("Area"+Str(*usagePointer\area),"CT#"+*usagePointer\username+"#"+StringField(rawreceive$,4,"#")+"#%",*usagePointer)
          CompilerIf #CONSOLE=0
            AddGadgetItem(Memo_ooc,-1,StringField(rawreceive$,3,"#")+Chr(10)+StringField(rawreceive$,4,"#"))
            Debug "guys"
            SetGadgetItemData(Memo_ooc,CountGadgetItems(Memo_ooc)-1,*usagePointer\ClientID)
          CompilerEndIf
        EndIf
        
      Case "ARC"
        SwitchAreas(*usagePointer,StringField(rawreceive$,2,"#"))      
        
      Case "RCD" ; character list
        start=Val(StringField(rawreceive$,2,"#"))-1
        If start<characternumber And start>=0
          sendstring$="CAD#"+Str(start+1)+"#"+Characters(start)\name+"#"+Str(0)
          start+1
          If start<characternumber
            sendstring$+"#"+Str(start+1)+"#"+Characters(start)\name+"#"+Str(0)
          EndIf
          SendTarget(Str(ClientID),sendstring$+"#%",Server)
        Else
          SendTarget(Str(ClientID),ReadyMusic(0),Server)
        EndIf
        
        
      Case "RMD" ;music list
        start=Val(StringField(rawreceive$,2,"#"))-1
        send=0
        If start<=tracks-1 And start>=0
          SendTarget(Str(ClientID),ReadyMusic(start),Server)
        Else
          SendTarget(Str(ClientID),"AD#1#" + Areas(1)\name + "#"+Str(Areas(1)\players)+"#"+ Areas(1)\bg + "##%",Server)
        EndIf
        
      Case "RAD" ; area list
        start=Val(StringField(rawreceive$,2,"#"))
        If start<=Aareas And start>=1     
          
          If areas(start)\pw<>""
            passworded$="1"
          Else
            passworded$=""
          EndIf
          Readyv$ = "AD#" + Str(start) + "#" + Areas(start)\name + "#0#"+ Areas(start)\bg + "#"+passworded$
          
          start+1
          
          If start<=Aareas
            If areas(start+1)\pw<>""
              passworded$="1"
            Else
              passworded$=""
            EndIf
            Readyv$ + "#" + Str(start) + "#" + Areas(start)\name + "#0#"+ Areas(start)\bg + "#"+passworded$
          EndIf
          
          Readyv$ + "#%"
          
          SendTarget(Str(ClientID),Readyv$,Server)
          
        Else ;MUSIC DONE
          SendTarget(Str(ClientID),ReadyVItem(0),Server)
        EndIf
        
      Case "ITD" ; item list
        start=Val(StringField(rawreceive$,2,"#"))-1
        If start<=itemamount-1 And start>=0          
          SendTarget(Str(ClientID),ReadyVItem(start),Server)
        Else
          SendTarget(Str(ClientID),"LCA#%",Server)
        EndIf
        
      Case "Change"
        WriteLog("["+GetCharacterName(*usagePointer)+"] freed",*usagePointer)
        *usagePointer\cid=-1
        
      Case "Req" ;char
        start=Val(StringField(rawreceive$,2,"#"))-1
        If start<characternumber And start>=0
          If 1
            If StringField(rawreceive$,3,"#")=Characters(start)\pw
              *usagePointer\CID=start
              SendTarget(Str(ClientID),"Allowed#"+GetCharacterName(*usagePointer)+"#%",Server)
              SendTarget(Str(ClientID),"YI#0#"+Str(*usagePointer\Inventory[0])+"#%",Server)
              WriteLog("[CHAR] "+*usagePointer\username+":"+*usagePointer\IP+":"+*usagePointer\AID+" selected "+GetCharacterName(*usagePointer),*usagePointer)
              ;TODO RaC loop
              For ac=0 To areas
                If Areas(ac)\players>0
                  SendTarget(Str(ClientID),"RaC#"+Str(ac+1)+"#"+Areas(ac)\players+"#%",Server)
                EndIf
              Next
              rf=1
            Else
              SendTarget(Str(ClientID),"WP#%",Server)
            EndIf
          Else
            SendTarget(Str(ClientID),"TKN#%",Server)
          EndIf
        EndIf
        
      Case "RQT" ;what is the time
        SendTarget(Str(ClientID),"TIME#"+FormatDate("%hh#%ii#%ss",Date())+"#%",Server)
        SendAreas(ClientID)
        
      Case "HP"
        Select StringField(rawreceive$,2,"#")
          Case "GOOD"
            Select StringField(rawreceive$,3,"#")
              Case "ADD"
                If Areas(*usagePointer\area)\good<30
                  Areas(*usagePointer\area)\good+1
                EndIf
              Case "SUB"
                If Areas(*usagePointer\area)\good>0
                  Areas(*usagePointer\area)\good-1
                EndIf
              Default
                *usagePointer\hack=1
            EndSelect
            SendTarget("*","HP#GOOD#"+Str(Areas(*usagePointer\area)\good)+"#%",*usagePointer)
          Case "EVIL"
            Select StringField(rawreceive$,3,"#")
              Case "ADD"
                If Areas(*usagePointer\area)\evil<30
                  Areas(*usagePointer\area)\evil+1
                EndIf
              Case "SUB"
                If Areas(*usagePointer\area)\evil>0
                  Areas(*usagePointer\area)\evil-1
                EndIf
              Default
                *usagePointer\hack=1
            EndSelect
            Areas(*usagePointer\area)\evil=bar
            SendTarget("*","HP#EVIL#"+Str(Areas(*usagePointer\area)\evil)+"#%",*usagePointer)
          Default
            *usagePointer\hack=1
        EndSelect
        
      Case "MI"
        start=Val(StringField(rawreceive$,2,"#"))
        If start<itemamount
          SendTarget(Str(ClientID),"YI#"+StringField(rawreceive$,2,"#")+"#"+Str(*usagePointer\Inventory[start])+"#%",Server)
        EndIf
        
      Case "TRASH"
        item=Val(StringField(rawreceive$,2,"#"))
        If item<itemamount And item>0
          If *usagePointer\Inventory[item]>0
            *usagePointer\Inventory[item]-1
          EndIf
          SendTarget(Str(ClientID),"YI#"+StringField(rawreceive$,2,"#")+"#"+Str(*usagePointer\Inventory[start])+"#%",Server)
        EndIf
        
      Case "BUY"
        item=Val(StringField(rawreceive$,2,"#"))
        If item<itemamount And item>0
          If *usagePointer\Inventory[0]>Items(item)\price
            *usagePointer\Inventory[0]-Items(item)\price
            *usagePointer\Inventory[item]+1
          EndIf
          SendTarget(Str(ClientID),"YI#"+StringField(rawreceive$,2,"#")+"#"+Str(*usagePointer\Inventory[start])+"#%",Server)
        EndIf
        
      Case "SELL"
        item=Val(StringField(rawreceive$,2,"#"))
        If item<itemamount And item>0
          If *usagePointer\Inventory[item]>0
            *usagePointer\Inventory[0]+Items(item)\price
            *usagePointer\Inventory[item]-1
          EndIf
          SendTarget(Str(ClientID),"YI#"+StringField(rawreceive$,2,"#")+"#"+Str(*usagePointer\Inventory[start])+"#%",Server)
        EndIf
        
      Case "PM"
        SendTarget(StringField(rawreceive$,2,"#"),"PM#"+*usagePointer\username+"#"+StringField(rawreceive$,3,"#")+"#%",*usagePointer)
        
      Case "CHGB"
        SendTarget(Str(ClientID),"CHANGEBADGE#"+*usagePointer\username+"#"+StringField(rawreceive$,2,"#")+"#%",*usagePointer)
        
      Case "Dice"
        dicemax=Val(StringField(rawreceive$,3,"#"))
        If dicemax<=1 Or dicemax>100
          dicemax=6
        EndIf
        random=0
        rolls=Val(StringField(rawreceive$,2,"#"))
        If rolls<=0 Or rolls>10
          rolls=1
        EndIf
        For rolled=0 To rolls
          If OpenCryptRandom()
            random+CryptRandom(dicemax-1)+1
            CloseCryptRandom()
          Else
            random+Random(dicemax,1)
          EndIf
        Next
        SendTarget("*","FI#"+GetCharacterName(*usagePointer)+" rolled: "+Str(rolls)+"d"+Str(dicemax)+", Result: "+Str(random)+"#"+FormatDate("%hh:%ii:%ss",Date())+"#%",*usagePointer)
        
      Case "FB"
        SendTarget(Str(ClientID),"KC#go be gay somewhere else#%",Server)
        KickBan(Str(ClientID),"",#DISCO,3)
        
      Case "FCl"
        SendTarget(Str(ClientID),"KC#go be gay somewhere else#%",Server)
        KickBan(Str(ClientID),"",#DISCO,3)
        
      Case "IAmTrash"
        If areas(*usagePointer\area)\lock=ClientID
          areas(*usagePointer\area)\lock=0
          areas(*usagePointer\area)\mlock=0
        EndIf
        
      Case "MOD"        
        Select StringField(rawreceive$,2,"#")
          Case "IP"
            If *usagePointer\perm
              If CommandThreading
                CreateThread(@ListIP(),ClientID)
              Else
                ListIP(ClientID)
              EndIf
            EndIf
            WriteLog("["+GetCharacterName(*usagePointer)+"] used IP",*usagePointer)
          Case "AUTH"
            If oppass$=StringField(rawreceive$,3,"#")
              If oppass$<>""
                SendTarget(Str(ClientID),LoginReply$,Server) 
                *usagePointer\perm=1
                *usagePointer\ooct=1
              EndIf
            ElseIf adminpass$=StringField(rawreceive$,3,"#")
              If adminpass$<>""
                SendTarget(Str(ClientID),LoginReply$,Server) 
                SendTarget(Str(ClientID),"UM#"+Str(*usagePointer\CID)+"#%",Server)
                *usagePointer\perm=2
                *usagePointer\ooct=1
              EndIf
            EndIf
            send=0
        EndSelect
        
      Case "CO"
        *usagePointer\master=1
        SendTarget(Str(ClientID),"VNAL#"+StringField(rawreceive$,2,"#")+"#%",Server)
        SendTarget(Str(ClientID),"SDA#1#"+msname$+"#"+msip$+"#"+Str(port)+"#"+desc$+"#http://stoned.ddns.net/#%",Server)
        SendTarget(Str(ClientID),"SDP#0#"+msname$+"#"+msip$+"#"+Str(port)+"#"+desc$+"#http://stoned.ddns.net/#%",Server)
        
      Case "VER"
        *usagePointer\master=1
        SendTarget(Str(ClientID),"VEROK#%",Server)
        
      Case "VIP"
        SendTarget(Str(ClientID),"VIP#stonedDiscord#%",Server)
        
      Case "LOVE"
        SendTarget(Str(ClientID),"LOVE#Fiercy#%",Server)
        
      Default
        WriteLog(rawreceive$,*usagePointer)
    EndSelect
  EndIf
  StopProfiler()
EndProcedure

;- Network Thread
Procedure Network(var)
  Define SEvent,ClientID,send,length
  Define ip$,rawreceive$,sc
  Define *usagePointer.Client
  
  SEvent = NetworkServerEvent()
  
  Select SEvent
    Case 0
      Delay(LagShield)
      
    Case #PB_NetworkEvent_Disconnect
      ClientID = EventClient() 
      LockMutex(ListMutex)
      If FindMapElement(Clients(),Str(ClientID))
        WriteLog("CLIENT DISCONNECTED",Clients())
        If areas(Clients()\area)\lock=ClientID
          areas(Clients()\area)\lock=0
          areas(Clients()\area)\mlock=0
        EndIf
        If Clients()\area>=0
          areas(Clients()\area)\players-1
        EndIf
        If ListSize(Plugins())
          ResetList(Plugins())
          While NextElement(Plugins())
            pStat=#NONE
            CallFunctionFast(Plugins()\gcallback,#DISC)    
            CallFunctionFast(Plugins()\rawfunction,*usagePointer)
          Wend
        EndIf
        DeleteMapElement(Clients(),Str(ClientID))
        rf=1
      EndIf
      UnlockMutex(ListMutex)
      
    Case #PB_NetworkEvent_Connect
      ClientID = EventClient()
      If ClientID
        send=1
        ip$=IPString(GetClientIP(ClientID))
        
        ForEach IPbans()
          If ip$ = IPbans()\banned
            send=0
            WriteLog("IP: "+ip$+" is banned, reason: "+IPbans()\reason,Server)
            CloseNetworkConnection(ClientID)                   
            Break
          EndIf
        Next 
      EndIf
      If send
        
        LockMutex(ListMutex)
        Clients(Str(ClientID))\ClientID = ClientID
        Clients()\IP = ip$
        Clients()\AID=PV
        PV+1
        Clients()\CID=-1
        Clients()\hack=0
        Clients()\perm=0
        ForEach HDmods()
          If ip$ = HDmods()
            Clients()\perm=1
          EndIf
        Next
        Clients()\area=0
        areas(0)\players+1
        Clients()\ignore=0
        Clients()\judget=0
        Clients()\ooct=0
        Clients()\gimp=0
        Clients()\ignoremc=0
        Clients()\websocket=0
        Clients()\username=""
        
        LockMutex(ActionMutex)
        ResetList(Actions())
        While NextElement(Actions())
          If Actions()\IP=ip$
            Select Actions()\type
              Case #UNDJ
                Clients()\ignoremc=1
              Case #GIMP
                Clients()\gimp=1
            EndSelect
          EndIf
        Wend
        UnlockMutex(ActionMutex)
        
        UnlockMutex(ListMutex)
        WriteLog("[CONNEC.] "+ip$,Clients())
        
        If ListSize(Plugins())
          ResetList(Plugins())
          While NextElement(Plugins())
            pStat=#NONE
            CallFunctionFast(Plugins()\gcallback,#CONN)    
            CallFunctionFast(Plugins()\rawfunction,*usagePointer)
          Wend
        EndIf
        CompilerIf #WEB
          length=ReceiveNetworkData(ClientID, *Buffer, 1024)
          Debug "eaoe"
          Debug length
          If length=-1
            SendNetworkString(ClientID,"decryptor#"+decryptor$+"#%")
          Else
            Debug "wotf"
            rawreceive$=PeekS(*Buffer,length)
            Debug rawreceive$
            If ExpertLog
              WriteLog(rawreceive$,Clients())
            EndIf
            If length>=0 And Left(rawreceive$,3)="GET"
              Clients()\websocket=1
              For i = 1 To CountString(rawreceive$, #CRLF$)
                headeririda$ = StringField(rawreceive$, i, #CRLF$)
                headeririda$ = RemoveString(headeririda$, #CR$)
                headeririda$ = RemoveString(headeririda$, #LF$)
                If Left(headeririda$, 19) = "Sec-WebSocket-Key: "
                  wkey$ = Right(headeririda$, Len(headeririda$) - 19)
                EndIf
              Next
              Debug wkey$
              rkey$ = SecWebsocketAccept(wkey$)
              Debug rkey$
              vastus$ = "HTTP/1.1 101 Switching Protocols" + #CRLF$
              vastus$ = vastus$ + "Connection: Upgrade"+ #CRLF$
              vastus$ = vastus$ + "Sec-WebSocket-Accept: " + rkey$ + #CRLF$
              vastus$ = vastus$ + "Server: serverV "+version$ + #CRLF$
              vastus$ = vastus$ + "Upgrade: websocket"+ #CRLF$ + #CRLF$
              Debug vastus$
              SendNetworkString(ClientID, vastus$)
              
            EndIf
          EndIf
        CompilerElse
          SendNetworkString(ClientID,"decryptor#"+decryptor$+"#%")
        CompilerEndIf
      EndIf
      
      
    Case #PB_NetworkEvent_Data ;//////////////////////////Data
      ClientID = EventClient()
      *usagePointer.Client=FindMapElement(Clients(),Str(ClientID))
      If *usagePointer
        length=ReceiveNetworkData(ClientID, *Buffer, 1024)
        If length
          rawreceive$=PeekS(*Buffer,length)
          Debug rawreceive$
          CompilerIf #WEB
            If *usagePointer\websocket And WebSockets              
              Ptr = 0
              Byte.a = PeekA(*Buffer + Ptr)
              If Byte & %10000000
                Fin = #True
              Else
                Fin = #False
              EndIf
              Opcode = Byte & %00001111
              Ptr = 1
              Byte = PeekA(*Buffer + Ptr)
              Masked = Byte >> 7
              Payload = Byte & $7F            
              Ptr + 1
              If Payload = 126
                Payload = PeekA(*Buffer + Ptr) << 8
                Ptr + 1
                Payload | PeekA(*Buffer + Ptr)
                Ptr + 1
              ElseIf Payload = 127
                Payload = 0
                n = 7
                For i = Ptr To Ptr + 7
                  Payload | PeekA(*Buffer + i) << (8 * n)
                  n - 1
                Next i
                Ptr + 8
              EndIf
              If Masked
                n = 0
                For i = Ptr To Ptr + 3
                  MaskKey(n) = PeekA(*Buffer + i)
                  Debug "MaskKey " + Str(n + 1) + ": " + RSet(Hex(MaskKey(n)), 2, "0")
                  n + 1
                Next i
                Ptr + 4
              EndIf
              Select Opcode
                Case #TextFrame
                  If Masked
                    vastus$ = ""
                    n = 0
                    For i = Ptr To Ptr + Payload - 1
                      vastus$ + Chr(PeekA(*Buffer + i) ! MaskKey(n % 4))
                      n + 1
                    Next i
                  Else
                    vastus$ = PeekS(*Buffer + Ptr, Payload)
                  EndIf
                  rawreceive$=vastus$
                Case #PingFrame
                  Byte = PeekA(*Buffer) & %11110000
                  PokeA(*Buffer, Byte | #PongFrame)
                  SendNetworkData(ClientID, *Buffer, bytesidkokku)
                Case #ConnectionCloseFrame
                  If areas(Clients()\area)\lock=ClientID
                    areas(Clients()\area)\lock=0
                    areas(Clients()\area)\mlock=0
                  EndIf
                  If Clients()\area>=0
                    areas(Clients()\area)\players-1
                  EndIf
              EndSelect
            EndIf
          CompilerEndIf
          
          sc=1
          While StringField(rawreceive$,sc,"%")<>""
            subcommand$=StringField(rawreceive$,sc,"%")+"%"
            
            subcommand$=ValidateChars(subcommand$)
            length=Len(subcommand$)
            
            If ExpertLog
              WriteLog(subcommand$,*usagePointer)
            EndIf
            
            If ReplayMode=1 Or Not *usagePointer\last.s=subcommand$ And *usagePointer\ignore=0 
              *usagePointer\last.s=subcommand$
              If CommandThreading
                CreateThread(@CheckInternetCode(),ClientID)
              Else
                CheckInternetCode(ClientID)
              EndIf
              If ListSize(Plugins())
                ResetList(Plugins())
                While NextElement(Plugins())
                  pStat=#NONE
                  CallFunctionFast(Plugins()\gcallback,#DATA)    
                  CallFunctionFast(Plugins()\rawfunction,*usagePointer)
                  pStat=CallFunctionFast(Plugins()\gcallback,#SEND)
                  Select pStat
                    Case #SEND
                      ptarget$=PeekS(CallFunctionFast(Plugins()\gtarget))
                      pmes$=PeekS(CallFunctionFast(Plugins()\gmessage))
                      SendTarget(ptarget$,pmes$,Server)
                  EndSelect
                Wend
              EndIf
            EndIf
            sc+1
          Wend
          
        ElseIf length=-1
          LockMutex(ListMutex)
          If FindMapElement(Clients(),Str(ClientID))
            WriteLog("CLIENT BROKE",Clients())
            If areas(Clients()\area)\lock=ClientID
              areas(Clients()\area)\lock=0
              areas(Clients()\area)\mlock=0
            EndIf
            If Clients()\area>=0
              areas(Clients()\area)\players-1
            EndIf
            If ListSize(Plugins())
              ResetList(Plugins())
              While NextElement(Plugins())
                pStat=#NONE
                CallFunctionFast(Plugins()\gcallback,#DISC)    
                CallFunctionFast(Plugins()\rawfunction,*usagePointer)
              Wend
            EndIf
            DeleteMapElement(Clients(),Str(ClientID))
            rf=1
          EndIf
          UnlockMutex(ListMutex)
        EndIf
      EndIf
      
    Default
      Delay(LagShield)
      
  EndSelect
  
EndProcedure

;-  PROGRAM START    

start:
CompilerIf #PB_Compiler_Debugger=0
  error=ErrorAddress()
  If error<>lasterror
    lasterror=error
    public=0
    If OpenFile(5,"crash.txt",#PB_File_NoBuffering|#PB_File_Append)      
      WriteStringN(5,"["+FormatDate("%yyyy.%mm.%dd %hh:%ii:%ss",Date())+"] serverV "+ErrorMessage()+"'d at this address "+Str(ErrorAddress())+" target "+Str(ErrorTargetAddress()))
      CompilerIf #PB_Compiler_Processor = #PB_Processor_x64
        WriteStringN(5,"RAX "+ErrorRegister(#PB_OnError_RAX))
        WriteStringN(5,"RBX "+ErrorRegister(#PB_OnError_RBX))
        WriteStringN(5,"RCX "+ErrorRegister(#PB_OnError_RCX))
        WriteStringN(5,"RDX "+ErrorRegister(#PB_OnError_RDX))
        WriteStringN(5,"RBP "+ErrorRegister(#PB_OnError_RBP))
        WriteStringN(5,"RSI "+ErrorRegister(#PB_OnError_RSI))
        WriteStringN(5,"RDI "+ErrorRegister(#PB_OnError_RDI))
        WriteStringN(5,"RSP "+ErrorRegister(#PB_OnError_RSP))
        WriteStringN(5,"FLG "+ErrorRegister(#PB_OnError_Flags))
      CompilerElse
        WriteStringN(5,"EAX "+ErrorRegister(#PB_OnError_EAX))
        WriteStringN(5,"EBX "+ErrorRegister(#PB_OnError_EBX))
        WriteStringN(5,"ECX "+ErrorRegister(#PB_OnError_ECX))
        WriteStringN(5,"EDX "+ErrorRegister(#PB_OnError_EDX))
        WriteStringN(5,"EBP "+ErrorRegister(#PB_OnError_EBP))
        WriteStringN(5,"ESI "+ErrorRegister(#PB_OnError_ESI))
        WriteStringN(5,"EDI "+ErrorRegister(#PB_OnError_EDI))
        WriteStringN(5,"ESP "+ErrorRegister(#PB_OnError_ESP))
        WriteStringN(5,"FLG "+ErrorRegister(#PB_OnError_Flags))
      CompilerEndIf
      CloseFile(5)
    EndIf
    LoadSettings(1)
    Delay(500)
  EndIf
CompilerEndIf

If ReceiveHTTPFile("https://raw.githubusercontent.com/stonedDiscord/serverV/master/serverd.txt","serverv.txt")
  OpenPreferences("serverv.txt")
  PreferenceGroup("Version")
  newbuild=ReadPreferenceInteger("Build",13)
  If newbuild>13
    update=1
  EndIf
  ClosePreferences()
EndIf

CompilerIf #CONSOLE=0
  OpenForm3()
  LoadServer(0)
  CompilerElse
  OpenConsole()  
  LoadServer(0)
  success=CreateNetworkServer(0,Port,#PB_Network_TCP)
  If success
    WriteLog("Server started",Server)
    
    If public And msthread=0
      msthread=CreateThread(@MasterAdvert(),Port)
    EndIf      
    
    If LoopMusic
      CreateThread(@TrackWait(),0)
    EndIf                
    
  Else
    WriteLog("server creation failed",Server)
  EndIf
  
  
CompilerEndIf

;- WINDOW EVENT LOOP 
Repeat ; Start of the event loop
  If success
    Network(0)
  EndIf
  CompilerIf #CONSOLE=0
    Event = WaitWindowEvent(LagShield) ; This line waits until an event is received from Windows
    WindowID = EventWindow()  ; The Window where the event is generated, can be used in the gadget procedures
    GadgetID = EventGadget()  ; Is it a gadget event?
    EventType = EventType()   ; The event type
    If Event = #PB_Event_Gadget
      
      
      lvstate=GetGadgetState(Listbox_users)
      Debug lvstate
      If lvstate>=0         
        cldata = GetGadgetItemData(Listbox_users,lvstate)
        Debug cldata
        Debug "cldata"
        If cldata
          LockMutex(ListMutex)
          *clickedClient=FindMapElement(Clients(),Str(cldata))
          UnlockMutex(ListMutex)
        EndIf
        
        Select GadgetID 
          Case Button_kick
            KickBan(Str(cldata),"",#KICK,3)
            
          Case Button_mute
            KickBan(Str(cldata),"",#MUTE,3)
            
          Case Button_unmute
            KickBan(Str(cldata),"",#UNMUTE,3)
            
          Case Button_ipban
            KickBan(Str(cldata),"",#BAN,3)
            
          Case Button_uban  
            KickBan(Str(cldata),"",#IDBAN,3)
            
          Case Button_disconnect
            KickBan(Str(cldata),"",#DISCO,3)     
            
           
          Case Button_ooc
            If ooc
              ooc=0
            Else
              ooc=1
            EndIf
            
        EndSelect
        
      EndIf
      
      Select GadgetID 
        Case listbox_event
          logclid=GetGadgetItemData(listbox_event,GetGadgetState(listbox_event))   
          If logclid
            For b=0 To CountGadgetItems(Listbox_users)
              If GetGadgetItemData(Listbox_users,b) = logclid  
                SetGadgetState(Listbox_users,b)
              EndIf
            Next
          EndIf
          
        Case Button_connect
          msuser$=GetGadgetText(Edit1)
          mspass$=GetGadgetText(Edit2)
          If public And msthread=0
            msthread=CreateThread(@MasterAdvert(),port)
          EndIf
          HideGadget(Edit1, 1)
          HideGadget(Edit2, 1)
          HideGadget(Button_connect, 1) 
          HideGadget(Button_Host, 0)
          HideGadget(Button_ipban, 0)
          HideGadget(Button_uban, 0)
          HideGadget(Button_mute, 0)
          HideGadget(Button_unmute, 0)
          HideGadget(Button_disconnect, 0)
          HideGadget(Button_kick, 0)
          HideGadget(Button_settings, 0)
          HideGadget(Button_areas, 0)
          HideGadget(Button_init, 0)
          HideGadget(Button_music, 0)
          HideGadget(Button_Save, 0)
          HideGadget(Button_server, 0)
          HideGadget(Button_items, 0)
          HideGadget(Button_ban, 0)
          HideGadget(Button_ipban, 0)
          HideGadget(Button_banip, 0)
          HideGadget(Button_main, 0)
          HideGadget(Button_ooc, 0)
          HideGadget(Button_animators, 0)
          HideGadget(Button_mods, 0)
          HideGadget(Button_upd, 0)  
          HideGadget(ListBox_users, 0)
          
        Case Button_reload
          LoadServer(1)
          
        Case Button_Host
          success=CreateNetworkServer(0,Port,#PB_Network_TCP)
          If success
            StatusBarText(0,1,"Server Status: ONLINE")
            WriteLog("Server started",Server)
            
            If public And msthread=0
              msthread=CreateThread(@MasterAdvert(),Port)
            EndIf      
            
            If LoopMusic
              CreateThread(@TrackWait(),0)
            EndIf                
            
          Else
            WriteLog("server creation failed",Server)
          EndIf
          
        Case Button_settings
          HideGadget(Listbox_users,1)
          HideGadget(Memo2,0)
          HideGadget(edit_ooc,1)
          HideGadget(Memo_ooc,1)
          view$="settings"
          ReadFile(5,"base/settings.ini")
          SetGadgetText(Memo2,"")
          While Eof(5) =0
            AddGadgetItem(Memo2,-1,ReadString(5))
          Wend
          CloseFile(5)
          
        Case Button_init
          HideGadget(Listbox_users,1)
          HideGadget(Memo2,0)
          HideGadget(edit_ooc,1)
          HideGadget(Memo_ooc,1)
          view$="init"
          ReadFile(5,"base/scene/"+scene$+"/init.ini")
          SetGadgetText(Memo2,"")
          While Eof(5) =0
            AddGadgetItem(Memo2,-1,ReadString(5))
          Wend
          CloseFile(5)
          
        Case Button_music
          HideGadget(Listbox_users,1)
          HideGadget(Memo2,0)
          HideGadget(edit_ooc,1)
          HideGadget(Memo_ooc,1)
          view$="music"
          ReadFile(5,"base/scene/"+scene$+"/musiclist.txt")
          SetGadgetText(Memo2,"")
          While Eof(5) =0
            AddGadgetItem(Memo2,-1,ReadString(5))
          Wend
          CloseFile(5)
          
        Case Button_areas
          HideGadget(Listbox_users,1)
          HideGadget(Memo2,0)
          HideGadget(edit_ooc,1)
          HideGadget(Memo_ooc,1)
          view$="areas"
          ReadFile(5,"base/scene/"+scene$+"/areas.ini")
          SetGadgetText(Memo2,"")
          While Eof(5) =0
            AddGadgetItem(Memo2,-1,ReadString(5))
          Wend
          CloseFile(5)
          
        Case Button_items
          HideGadget(Listbox_users,1)
          HideGadget(Memo2,0)
          HideGadget(edit_ooc,1)
          HideGadget(Memo_ooc,1)
          view$="items"
          ReadFile(5,"base/scene/"+scene$+"/items.ini")
          SetGadgetText(Memo2,"")
          While Eof(5) =0
            AddGadgetItem(Memo2,-1,ReadString(5))
          Wend
          CloseFile(5)
          
        Case Button_ipban
          HideGadget(Listbox_users,1)
          HideGadget(Memo2,0)
          HideGadget(edit_ooc,1)
          HideGadget(Memo_ooc,1)
          view$="ipban"
          ReadFile(5,"banip.txt")
          SetGadgetText(Memo2,"")
          While Eof(5) =0
            AddGadgetItem(Memo2,-1,ReadString(5))
          Wend
          CloseFile(5)
          
        Case Button_ban
          HideGadget(Listbox_users,1)
          HideGadget(Memo2,0)
          HideGadget(edit_ooc,1)
          HideGadget(Memo_ooc,1)
          view$="userban"
          ReadFile(5,"banuser.txt")
          SetGadgetText(Memo2,"")
          While Eof(5) =0
            AddGadgetItem(Memo2,-1,ReadString(5))
          Wend
          CloseFile(5)
          
        Case Button_server
          SetGadgetText(Button6,"Server")
          HideGadget(Listbox_users,0)
          HideGadget(Memo2,1)
          HideGadget(edit_ooc,1)
          HideGadget(Memo_ooc,1)
          
        Case Button_main
          SetGadgetText(Button16,"Main")
          HideGadget(Listbox_users,0)
          HideGadget(Memo2,1)
          HideGadget(edit_ooc,1)
          HideGadget(Memo_ooc,1)
          
        Case Button_ooc
          SetGadgetText(Button_ooc,"OOC")
          HideGadget(Listbox_users,1)
          HideGadget(Memo2,1)
          HideGadget(edit_ooc,0)
          HideGadget(Memo_ooc,0)
          
        Case 1337
          MessageRequester("serverV","This is serverV version "+version$+Chr(10)+"(c) stonedDiscord 2014-2016")
          
      EndSelect
    ElseIf Event = #PB_Event_Menu
      adch$=GetGadgetText(edit_ooc)
      If adch$<>""
        Server\last = "CT#$ADMIN#"+adch$+"#%"
        CheckInternetCode(Server)
      EndIf
      
    ElseIf Event = #PB_Event_SizeWindow
      
      ;               ResizeGadget(#Frame3D_0,0,0,WindowWidth(0)/2.517,WindowHeight(0))
      ;               ResizeGadget(Listbox_users,70,40,WindowWidth(0)/2.517-70,WindowHeight(0)-40)
      ;               ResizeGadget(Button_2,WindowWidth(0)/6.08,15,WindowWidth(0)/8.111,22)
      ;               ResizeGadget(String_5,WindowWidth(0)/3.476,15,WindowWidth(0)/10.42,22)
      ;               ResizeGadget(#Frame3D_4,WindowWidth(0)/2.517,0,WindowWidth(0)/3.173,WindowHeight(0))
      ;               ResizeGadget(listbox_event, WindowWidth(0)/1.7, 30, WindowWidth(0)-WindowWidth(0)/1.7, WindowHeight(0)-90)
      ;               ResizeGadget(listbox_event,WindowWidth(0)/2.517,20,WindowWidth(0)/3.173,WindowHeight(0)-20)
      ;               ResizeGadget(#Frame3D_5,WindowWidth(0)/1.4,0,WindowWidth(0)/3.476,WindowHeight(0))
      ;               ResizeGadget(#ListIcon_2,WindowWidth(0)/1.4,20,WindowWidth(0)/3.476,WindowHeight(0)-40)  
      ;               
      ;               ResizeGadget(String_13,WindowWidth(0)/1.4,WindowHeight(0)-20,WindowWidth(0)/5,20)  
      ;               ResizeGadget(Button_31,WindowWidth(0)/1.1,WindowHeight(0)-20,WindowWidth(0)/10,20)  
    ElseIf Event = #PB_Event_CloseWindow
      Quit=1
      
    EndIf
  CompilerEndIf
Until Quit=1 ; End of the event loop
Quit=1
WriteLog("stopping server...",Server)
LockMutex(ListMutex)
ResetMap(Clients())
While NextMapElement(Clients())
  If Clients()\ClientID
    CloseNetworkConnection(Clients()\ClientID)
  EndIf
  DeleteMapElement(Clients())
Wend
killed=1
UnlockMutex(ListMutex)    
CloseNetworkServer(0)
FreeMemory(*Buffer)
End
; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 26
; FirstLine = 23
; Folding = ---
; EnableXP