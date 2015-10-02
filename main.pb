;EnableExplicit
; yes this is the legIt serverV source code please report bugfixes/modifications/feature requests to sD/trtukz on skype
CompilerIf #PB_Compiler_OS <> #PB_OS_Windows
  #MB_ICONERROR=0
CompilerEndIf

;- Defining Structure
Structure CharacterArray
  StructureUnion
    c.c[0]
    s.s{1}[0]
  EndStructureUnion
EndStructure

Structure Evidence
  type.w
  name.s
  desc.s
  image.s
EndStructure

#CROSS=0
Global version$="1.0"
Global Logging.b=0
Global public.b=0
Global CheckEm.b=1
Global LogFile$="log.txt"
Global modpass$=""
Global adminpass$=""
Global ooc.b=1
Global Quit=0
Global defbar$="10"
Global probar$="10"
Global port
Global scene$="VNOVanilla"
Global characternumber=0
Global oBG.s="Cafeteria"
Global rt.b=1
Global loghd.b=0
Global background.s
Global PV=1
Global msname$="serverV"
Global desc$="Default server "+version$
Global www$
Global rf.b=0
Global msip$="127.0.0.1"
Global Replays.b=0
Global rline=0
Global replayline=0
Global replayopen.b
Global modcol=0
Global blockini.b=0
Global ExpertLog=0
Global tracks=0
Global msthread=0
Global LoginReply$="CT#$HOST#Successfully connected as mod#%"
Global musicpage=0
Global ChatMutex = CreateMutex()
Global ListMutex = CreateMutex()
Global MusicMutex = CreateMutex()
Global RefreshMutex = CreateMutex()
Global musicmode=1
Global update=0
Global Aareas
Global NewList HDmods.s()
Global NewList IPbans.s()
Global NewList SDbans.s()
Global Dim ReadyMusic.s(400)
Global Dim ReadyVArea.s(100)
Global Dim ReadyVMusic.s(1000)
;- Initialize The Network
If InitNetwork() = 0
  CompilerIf #CONSOLE=0
    MessageRequester("serverV", "Can't initialize the network!",#MB_ICONERROR)
  CompilerEndIf
  End
EndIf

;- Include files

CompilerIf #CONSOLE=0
  IncludeFile "Common.pbf"
CompilerEndIf

IncludeFile "../server_private/server_shared.pb"

;- Define Functions
; yes after the network init and include code
; many of these depend on that

Procedure MSWait(*usagePointer.Client)
  Define wttime
  Debug areas(*usagePointer\area)\wait
  Debug *usagePointer\area
  wttime=Len(Trim(StringField(*usagePointer\last,4,"#")))*60
  If wttime>5000
    wttime=5000
  EndIf
  Delay(wttime)
  areas(*usagePointer\area)\wait=0
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
    PrintN("Loading serverV "+Str(#PB_Editor_BuildCount)+"."+Str(#PB_Editor_CompileCount)+" settings")
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
  www$=ReadPreferenceString("www","http://weedlan.de/serverv/")  
  
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
  LogFile$=ReadPreferenceString("LogFile","log.txt")
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
  Next
  
  PreferenceGroup("chars")
  Global characternumber=ReadPreferenceInteger("number",1)
  ReDim Characters.ACharacter(characternumber)
  For loadchars=0 To characternumber-1
    PreferenceGroup("chars")
    Characters(loadchars)\name=ReadPreferenceString(Str(loadchars+1),"Monokuma")
    PreferenceGroup("pass")
    Characters(loadchars)\pw=ReadPreferenceString(Str(loadchars+1),"")
    If reload=0
      Characters(loadchars)\taken=0
    EndIf
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
      ReadyVMusic(tracks) = "MD#" + Str(tracks+1) + "#" + track$ + "#%"
      tracks+1
    Wend
    CloseFile(2)
    
  Else
    WriteLog("NO MUSIC LIST",Server)
    AddElement(Music())
    Music()\TrackName="NO MUSIC LIST"
    ReadyVMusic(0) = "MD#0#NO MUSIC LIST#%"
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
  
  If OpenPreferences( "base/scene/"+scene$+"/areas.ini")
    PreferenceGroup("Areas")
    Aareas=ReadPreferenceInteger("number",1)
    For loadareas=0 To Aareas-1
      PreferenceGroup("Areas")
      aname$=ReadPreferenceString(Str(loadareas+1),"gs4") 
      areas(loadareas)\name=aname$
      PreferenceGroup("filename")
      area$=ReadPreferenceString(Str(loadareas+1),"gs4") 
      areas(loadareas)\bg=area$
      PreferenceGroup("pass")
      areas(loadareas)\pw=ReadPreferenceString(Str(loadareas+1),"")
      If areas(loadareas)\pw<>""
        passworded$="1"
      Else
        passworded$=""
      EndIf
      ReadyVArea(loadareas) = "AD#" + Str(loadareas+1) + "#" + aname$ + "#0#"+ area$ + "#"+passworded$+"#%" 
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
        SDbans()=hdban$
      EndIf
    Wend  
    CloseFile(2)
  EndIf
  
  If ReadFile(2, "ipbanlist.ini")
    ClearList(IPbans())
    While Eof(2) = 0
      ipban$=ReadString(2)
      If ipban$<>""
        AddElement(IPbans())
        IPbans()=ipban$
      EndIf
    Wend
    CloseFile(2)
  EndIf
  
EndProcedure

Procedure SendTarget(user$,message$,*sender.Client)
  Define everybody,i
  omessage$=message$
  RAWmessage$=message$
  
  If user$="*"
    everybody=1
  Else
    everybody=0
  EndIf
  
  For i=0 To characternumber
    If Characters(i)\name=user$
      user$=Str(i)
      Break
    EndIf
  Next
  CompilerIf #CROSS
    If *sender\RAW
      Debug "sender is RAW"
      Select Left(message$,2)
        Case"MC"    
          message$="MC#"+StringField(message$,3,"#")+".mp3#"+Str(*sender\CID)+"#%"
        Case "MS"
          message$="MS#chat#"+StringField(message$,3,"#")+"#"+GetCharacterName(*sender)+"#"+StringField(message$,3,"#")+"#"+StringField(message$,4,"#")+"#wit#1#0#"+Str(*sender\CID)+"#0#0#0#"+Str(*sender\CID)+"#0#"+StringField(message$,6,"#")+"#%"
          ; MS#chat#(a)smug#Discord#storm#rekt#jud#1#0#9#0#0#0#9#0#0#%
      EndSelect
    Else
      Debug "sender is AO or nothing"
      Select Left(message$,2)
        Case"MC"    
          RAWmessage$="MC#"+GetCharacterName(*sender)+"#"+StringField(ReplaceString(message$,".mp3",""),2,"#")+"#"+areas(*sender\area)\bg+"#"+Str(*sender\CID)+"#%"
        Case "MS"
          RAWmessage$="MS#"+GetCharacterName(*sender)+"#"+StringField(message$,3,"#")+"#"+StringField(message$,6,"#")+"#char#"+StringField(message$,16,"#")+"#"+Str(*sender\CID)+"#%"
          ; MS#chat#(a)smug#Discord#storm#rekt#jud#1#0#9#0#0#0#9#0#0#%
        Case "IL"
          RAWmessage$="CT#SERVER#"+Mid(message$,3)
          Debug "CT#SERVER"+Mid(message$,3)
      EndSelect
    EndIf
  CompilerEndIf
  LockMutex(ListMutex)
  
  If FindMapElement(Clients(),user$)
    
    If Clients()\websocket
      CompilerIf #WEB
        Websocket_SendTextFrame(Clients()\ClientID,message$)
      CompilerEndIf
    Else
      SendNetworkString(Clients()\ClientID,message$)  
    EndIf
  Else
    ResetMap(Clients())
    While NextMapElement(Clients())
      If user$=Str(Clients()\CID) Or user$=Clients()\IP Or (everybody And (*sender\area=Clients()\area Or *sender\area=-1)) And Clients()\master=*sender\master
        If Clients()\websocket
          CompilerIf #WEB
            Websocket_SendTextFrame(Clients()\ClientID,message$)
          CompilerEndIf
        Else
          SendNetworkString(Clients()\ClientID,message$)  
        EndIf
      EndIf
    Wend   
  EndIf
  UnlockMutex(ListMutex)
EndProcedure

Procedure ListIP(ClientID)
  Define send.b
  Define iplist$
  Define charname$
  Define char
  send=0
  iplist$="CT#$HOST#"
  LockMutex(ListMutex)  
  ResetMap(Clients())
  While NextMapElement(Clients())
    Select Clients()\perm
      Case 1
        charname$=GetCharacterName(Clients())+"(mod)"
      Case 2
        charname$=GetCharacterName(Clients())+"(admin)"
      Case 3
        charname$=GetCharacterName(Clients())+"(server)"
      Default
        charname$=GetCharacterName(Clients())
    EndSelect
    iplist$=iplist$+Clients()\IP+"|"+charname$+"|"+Str(Clients()\CID)+"|*"
  Wend
  UnlockMutex(ListMutex)
  iplist$=iplist$+"#%"
  SendTarget(Str(ClientID),iplist$,Server) 
EndProcedure

Procedure KickBan(kick$,action,perm)
  Define akck
  Define everybody.b
  Define i,kclid
  akck=0
  If kick$="everybody"
    everybody.b=1
  EndIf
  For i=0 To characternumber
    If Characters(i)\name=kick$
      kick$=Str(i)
      Break
    EndIf
  Next
  LockMutex(ListMutex)
  ResetMap(Clients())
  While NextMapElement(Clients())
    kclid=Clients()\ClientID
    kcid=Clients()\CID
    If kick$=Str(kcid) Or kick$=Str(kclid) Or kick$=Clients()\HD Or kick$=Clients()\IP Or everybody
      If Clients()\perm<perm
        Select action
          Case #KICK
            If Clients()\CID>=0
              Characters(Clients()\CID)\taken=0
            EndIf
            DeleteMapElement(Clients())
            SendNetworkString(kclid,"KC#"+Str(kcid)+"#%")
            CloseNetworkConnection(kclid)          
            akck+1
            
          Case #BAN
            AddElement(IPbans())
            IPbans()=Clients()\IP
            If OpenFile(2,"base/banlist.txt")
              FileSeek(2,Lof(2))
              WriteStringN(2,Clients()\IP)
              CloseFile(2)
            EndIf
            If Clients()\CID>=0
              Characters(Clients()\CID)\taken=0
            EndIf
            kclid=Clients()\ClientID
            DeleteMapElement(Clients())
            SendNetworkString(kclid,"KC#"+Str(kcid)+"#%")
            CloseNetworkConnection(kclid)  
            akck+1
          Case #MUTE
            SendNetworkString(Clients()\ClientID,"MU#"+Str(Clients()\CID)+"#%")
            akck+1
          Case #UNMUTE
            SendNetworkString(Clients()\ClientID,"UM#"+Str(Clients()\CID)+"#%")
            akck+1
          Case #CIGNORE
            Clients()\ignore=1
            akck+1
          Case #UNIGNORE
            Clients()\ignore=0
            akck+1
          Case #UNDJ
            Clients()\ignoremc=1
            akck+1
          Case #DJ
            Clients()\ignoremc=0
            akck+1
        EndSelect
      EndIf
    EndIf
  Wend    
  UnlockMutex(ListMutex) 
  rf=1
  ProcedureReturn akck
EndProcedure

ProcedureDLL MasterAdvert(port)
  Define msID=0,msinfo,NEvent,MVNO=0,msport=6543,retries
  Define sr=-1
  Define  *null=AllocateMemory(100)
  Define master$,msrec$
  WriteLog("Masterserver adverter thread started",Server)
  OpenPreferences("base/AS.ini")
  PreferenceGroup("AS")
  master$=ReadPreferenceString("1","54.93.210.149")
  PreferenceGroup("login")
  msuser$=ReadPreferenceString("Username","serverV")
  mspass$=ReadPreferenceString("Password","serverV")
  CheckEm=ReadPreferenceInteger("Check",1)
  mscpass$=UCase(MD5Fingerprint(@mspass$,StringByteLength(mspass$)))
  msport=6543
  ClosePreferences() 
  desc$=ReplaceString(desc$,"$n","|")  
  desc$=ReplaceString(desc$,"%n","|") 
  desc$=ReplaceString(desc$,"#","!") 
  desc$=ReplaceString(desc$,"%","!") 
  
  WriteLog("Using master "+master$, Server)
  
  If public
    
    Repeat      
      If msID
        NEvent=NetworkClientEvent(msID)
        If NEvent=#PB_NetworkEvent_Disconnect
          sr=-1
          msID=0
          Server\ClientID=msID
          CompilerIf #CONSOLE=0
            StatusBarText(0,0,"AS Connection: ERROR")
          CompilerEndIf
        ElseIf NEvent=#PB_NetworkEvent_Data
          msinfo=ReceiveNetworkData(msID,*null,100)
          If msinfo=-1
            sr=-1
            CompilerIf #CONSOLE=0
              StatusBarText(0,0,"AS Connection: ERROR")
            CompilerEndIf
          Else
            tick=0
            retries=0
            msrec$=PeekS(*null,msinfo)
            If ExpertLog
              WriteLog(msrec$,Server)
            EndIf
            Select StringField(msrec$,1,"#")    
              Case "CV"
                sr=SendNetworkString(msID,"VER#S#"+version$+"#%")
                sr=SendNetworkString(msID,"CO#"+msuser$+"#"+mscpass$+"#%")
              Case "VEROK"
                WriteLog("Running latest VNO server version.",Server)
              Case "VERPB"
                WriteLog("VNO Protocol outdated!",Server)
                CompilerIf #CONSOLE=0
                  StatusBarText(0,0,"AS Connection: OUTDATED")
                CompilerEndIf
                public=0
              Case "VNAL"
                sr=SendNetworkString(msID,"RequestPub#"+msname$+"#"+Str(port)+"#"+desc$+"#"+www$+"#%")
              Case "No"
                WriteLog("Wrong master credentials",Server)
              Case "VNOBD"
                WriteLog("Banned from master",Server)
                CompilerIf #CONSOLE=0
                  StatusBarText(0,0,"AS Connection: BANNED")
                CompilerEndIf
                public=0
              Case "NOPUB"
                WriteLog("Banned from hosting",Server)
                CompilerIf #CONSOLE=0
                  StatusBarText(0,0,"AS Connection: BANNED")
                CompilerEndIf
                public=0
              Case "OKAY"                
                LockMutex(ListMutex)
                ResetMap(Clients())
                While NextMapElement(Clients())
                  Debug "ip "+StringField(msrec$,3,"#")
                  If Clients()\IP=StringField(msrec$,3,"#")
                    Clients()\username=StringField(msrec$,2,"#")
                    WriteLog("[AUTH.] "+Clients()\username+":"+Clients()\IP+":"+Str(Clients()\AID),Server)
                  EndIf
                Wend
                UnlockMutex(ListMutex)
            EndSelect
          EndIf
        EndIf
        
        If sr=-1
          retries+1
          WriteLog("Masterserver adverter thread connecting...",Server)
          msID=OpenNetworkConnection(master$,msport)
          Server\ClientID=msID
          If msID
            CompilerIf #CONSOLE=0
              StatusBarText(0,0,"AS Connection: ONLINE")
            CompilerEndIf
          EndIf
        EndIf 
        
      Else
        retries+1
        WriteLog("Masterserver adverter thread connecting...",Server)
        msID=OpenNetworkConnection(master$,msport)
        Server\ClientID=msID
        If msID
          CompilerIf #CONSOLE=0
            StatusBarText(0,0,"AS Connection: ONLINE")
          CompilerEndIf
        EndIf
      EndIf
      If retries>50
        WriteLog("Too many masterserver connect retries, aborting...",Server)
        public=0
      EndIf
      Delay(1000)
    Until public=0
  EndIf
  WriteLog("Masterserver adverter thread stopped",Server)
  CompilerIf #CONSOLE=0
    StatusBarText(0,0,"AS Connection: OFFLINE")
  CompilerEndIf
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


CompilerIf #PB_Compiler_Debugger=0
  OnErrorGoto(?start)
CompilerEndIf

;- Command Handler
Procedure CheckInternetCode(*usagePointer.Client)
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
      
    Case "CT"
      send=0
      *usagePointer\last.s=""
      ctparam$=StringField(rawreceive$,3,"#")
      Debug Mid(ctparam$,5)
      Debug adminpass$
      If *usagePointer\CID>=0
        WriteLog("[OOC]["+GetCharacterName(*usagePointer)+"]["+StringField(rawreceive$,2,"#")+"]["+ctparam$+"]",*usagePointer)
        
        Debug ctparam$
        If Left(ctparam$,1)="/"
          Select StringField(ctparam$,1," ")
            Case "/ps"
              If modpass$=Mid(ctparam$,5)
                If modpass$<>""
                  SendTarget(Str(ClientID),LoginReply$,Server)
                  *usagePointer\perm=1
                  *usagePointer\ooct=1
                EndIf
              ElseIf adminpass$=Mid(ctparam$,5)
                If adminpass$<>""
                  SendTarget(Str(ClientID),LoginReply$,Server)
                  SendTarget(Str(ClientID),"UM#"+Str(*usagePointer\CID)+"#%",Server)
                  *usagePointer\perm=2
                  *usagePointer\ooct=1
                EndIf
              EndIf
              send=0
              
            Case "/ooc"
              If *usagePointer\perm
                ooc=1
              EndIf
              
            Case "/nooc"
              If *usagePointer\perm
                ooc=0
              EndIf
              
            Case "/toggle"
              If *usagePointer\perm
                Select StringField(ctparam$,2," ")
                  Case "WTCE"
                    If rt
                      rt=0
                    Else
                      rt=1
                    EndIf
                    pr$="FI#WTCE is "
                    If rt=1
                      pr$+"enabled%"
                    Else
                      pr$+"disabled%"
                    EndIf
                    SendTarget(Str(ClientID),pr$,Server)
                  Case "LogHD"
                    If loghd
                      loghd=0
                    Else
                      loghd=1
                    EndIf
                  Case "ExpertLog"
                    If ExpertLog
                      ExpertLog=0
                    Else
                      ExpertLog=1
                    EndIf
                EndSelect
              EndIf
              
              ;             Case "/help"
              ;               SendTarget(Str(ClientID),"CT#SERVER#Check http://weedlan.de/serverv/#%",Server)
              
            Case "/public"
              Debug ctparam$
              If StringField(ctparam$,2," ")=""
                pr$="FI#server is "
                If public=0
                  pr$+"not "
                EndIf
                SendTarget(Str(ClientID),pr$+"public%",Server)
              Else
                If *usagePointer\perm>1
                  public=Val(StringField(ctparam$,2," "))
                  If public
                    msthread=CreateThread(@Masteradvert(),port)
                  EndIf
                  CompilerIf #CONSOLE=0
                    SetGadgetState(Checkbox_MS,public)
                  CompilerEndIf
                EndIf
              EndIf
              
              
            Case "/send"  
              If *usagePointer\perm
                sname$=StringField(ctparam$,2," ")
                Debug sname$
                smes$=Mid(ctparam$,8+Len(sname$),Len(ctparam$)-6)
                smes$=Escape(smes$)
                SendTarget(sname$,smes$,Server)
              EndIf
              
            Case "/sendall"
              If *usagePointer\perm
                reply$=Mid(ctparam$,10,Len(ctparam$)-2)
                reply$=Escape(reply$)
              EndIf
              
            Case "/reload"
              If *usagePointer\perm>1
                LoadServer(1)
                SendTarget(Str(ClientID),"FI#serverV reloaded%",Server)
              EndIf
              
            Case "/play"
              If *usagePointer\perm                
                song$=Right(ctparam$,Len(ctparam$)-6)                
                SendTarget("*","MC#"+song$+"#"+Str(*usagePointer\CID)+"#%",*usagePointer)                
              EndIf
              
              
            Case "/ip"
              If *usagePointer\perm
                CreateThread(@ListIP(),ClientID)
                WriteLog("["+GetCharacterName(*usagePointer)+"] used /ip",*usagePointer)
              EndIf 
              
            Case "/unban"
              If *usagePointer\perm>1
                ub$=Mid(ctparam$,8,Len(ctparam$)-2)
                Debug ub$
                If CreateFile(2,"base/banlist.txt")
                  Debug "file recreated"
                  ForEach IPbans()
                    If IPbans()=ub$
                      DeleteElement(IPbans())
                    Else
                      WriteStringN(2,IPbans())
                    EndIf
                  Next
                  CloseFile(2)                                
                EndIf
                
              EndIf
              
            Case "/stop"
              If *usagePointer\perm>1
                Quit=1
                public=0
              EndIf
              
            Case "/kc"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,7,Len(ctparam$)-2),#KICK,*usagePointer\perm)
                SendTarget(Str(ClientID),"FI#kicked "+Str(akck)+" clients%",Server)
                WriteLog("["+GetCharacterName(*usagePointer)+"] used "+ctparam$,*usagePointer)
                
              EndIf
            Case "/bi"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,6,Len(ctparam$)-2),#BAN,*usagePointer\perm)
                SendTarget(Str(ClientID),"FI#banned "+Str(akck)+" clients%",Server)
              EndIf
              WriteLog("["+GetCharacterName(*usagePointer)+"] used "+ctparam$,*usagePointer)
              
            Case "/mu"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,7,Len(ctparam$)-2),#MUTE,*usagePointer\perm)
                SendTarget(Str(ClientID),"FI#muted "+Str(akck)+" clients%",Server)
              EndIf
              WriteLog("["+GetCharacterName(*usagePointer)+"] used "+ctparam$,*usagePointer)
              
            Case "/um"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,9,Len(ctparam$)-2),#UNMUTE,*usagePointer\perm)
                SendTarget(Str(ClientID),"FI#unmuted "+Str(akck)+" clients%",Server)
              EndIf
              WriteLog("["+GetCharacterName(*usagePointer)+"] used "+ctparam$,*usagePointer)
              
            Case "/ignore"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,9,Len(ctparam$)-2),#CIGNORE,*usagePointer\perm)
                SendTarget(Str(ClientID),"FI#muted "+Str(akck)+" clients%",Server)
              EndIf
              WriteLog("["+GetCharacterName(*usagePointer)+"] used "+ctparam$,*usagePointer)
              
            Case "/unignore"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,11,Len(ctparam$)-2),#UNIGNORE,*usagePointer\perm)
                SendTarget(Str(ClientID),"FI#unmuted "+Str(akck)+" clients%",Server)
              EndIf
              WriteLog("["+GetCharacterName(*usagePointer)+"] used "+ctparam$,*usagePointer)
              
            Case "/undj"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,7,Len(ctparam$)-2),#UNDJ,*usagePointer\perm)
                SendTarget(Str(ClientID),"FI#muted "+Str(akck)+" clients%",Server)
              EndIf
              WriteLog("["+GetCharacterName(*usagePointer)+"] used "+ctparam$,*usagePointer)
              
            Case "/dj"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,5,Len(ctparam$)-2),#DJ,*usagePointer\perm)
                SendTarget(Str(ClientID),"FI#unmuted "+Str(akck)+" clients%",Server)
              EndIf
              WriteLog("["+GetCharacterName(*usagePointer)+"] used "+ctparam$,*usagePointer)
              
          EndSelect
        ElseIf ooc
          *usagePointer\last.s=rawreceive$
          Sendtarget("*","CT#"+StringField(rawreceive$,2,"#")+"#"+StringField(rawreceive$,3,"#")+"#%",*usagePointer)
          
        EndIf
      Else
        WriteLog("[OOC][HACKER]["+StringField(rawreceive$,3,"#")+"]["+ctparam$+"]",*usagePointer)
        *usagePointer\hack=1
        rf=1
      EndIf
      
    Case "ARC"
      narea=Val(StringField(rawreceive$,2,"#"))-1
      If narea<=Aareas-1 And narea>=0
        If Not areas(narea)\lock Or *usagePointer\perm>areas(narea)\mlock
          If areas(*usagePointer\area)\lock=ClientID
            areas(*usagePointer\area)\lock=0
            areas(*usagePointer\area)\mlock=0
          EndIf
          oarea=*usagePointer\area
          *usagePointer\area=narea
          SendTarget(Str(ClientID),"ROOK#%",Server)
          oplayers=0
          nplayers=0
          LockMutex(ListMutex)
          ResetMap(Clients())
          While NextMapElement(Clients())
            If Clients()\area=narea
              nplayers+1
            EndIf
            If Clients()\area=oarea
              oplayers+1
            EndIf
          Wend
          SendTarget("*","RoC#"+Str(oarea+1)+"#"+Str(oplayers)+"#"+Str(narea+1)+"#"+Str(nplayers)+"#%",Server)
          Debug "RoC#"+Str(oarea+1)+"#"+Str(oplayers)+"#"+Str(narea+1)+"#"+Str(nplayers)+"#%"
          UnlockMutex(ListMutex)
          WriteLog("[ROOM] "+GetCharacterName(*usagePointer)+"] went to "+Areas(narea)\name,*usagePointer)
        Else
          SendTarget(Str(ClientID),"FI#area locked%",Server)
        EndIf
      ElseIf StringField(ctparam$,2," ")=""
        SendTarget(Str(ClientID),"FI#You are in area "+*usagePointer\area+"%",Server)
      Else
        SendTarget(Str(ClientID),"FI#Not a valid area%",Server)
      EndIf
      
      
    Case "RCD" ; character list
      start=Val(StringField(rawreceive$,2,"#"))-1
      If start<=characternumber And start>=0
        SendTarget(Str(ClientID),"CAD#"+Str(start+1)+"#"+Characters(start)\name+"#"+Str(Characters(start)\taken)+"#%",Server)
      Else
        SendTarget(Str(ClientID),ReadyVMusic(0),Server)
      EndIf
      
    Case "RMD" ;music list
      start=Val(StringField(rawreceive$,2,"#"))-1
      send=0
      If start<=tracks-1 And start>=0
        SendTarget(Str(ClientID),ReadyVMusic(start),Server)
      Else
        SendTarget(Str(ClientID),ReadyVArea(0),Server)
      EndIf
      
    Case "RAD" ; area list
      start=Val(StringField(rawreceive$,2,"#"))-1
      If start<=Aareas-1 And start>=0          
        SendTarget(Str(ClientID),ReadyVArea(start),Server)
      Else ;MUSIC DONE
        SendTarget(Str(ClientID),"LCA#"+FormatDate("%hh#%ii#%ss",Date())+"#%",Server)
      EndIf
      
    Case "Change"
      WriteLog("["+GetCharacterName(*usagePointer)+"] freed",*usagePointer)
      Characters(*usagePointer\cid)\taken=0
      *usagePointer\cid=-1
      
    Case "Req" ;char
      start=Val(StringField(rawreceive$,2,"#"))-1
      If start<characternumber And start>=0
        If Characters(start)\taken=0
          If StringField(rawreceive$,3,"#")=Characters(start)\pw
            *usagePointer\CID=start
            Characters(start)\taken=ClientID
            SendTarget(Str(ClientID),"Allowed#"+GetCharacterName(*usagePointer)+"#%",Server)
            WriteLog("[CHAR] "+*usagePointer\username+":"+*usagePointer\IP+":"+*usagePointer\AID+" selected "+GetCharacterName(*usagePointer),*usagePointer)
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
      
    Case "PM"
      SendTarget(StringField(rawreceive$,2,"#"),"PM#"+*usagePointer\username+"#"+StringField(rawreceive$,3,"#")+"#%",*usagePointer)
      
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
      KickBan(Str(ClientID),#DISCO,3)
      
    Case "FCl"
      SendTarget(Str(ClientID),"KC#go be gay somewhere else#%",Server)
      KickBan(Str(ClientID),#DISCO,3)
      
    Case "IAmTrash"
      If *usagePointer\CID>=0 And *usagePointer\CID <= characternumber
        Characters(*usagePointer\CID)\taken=0
      EndIf
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
      SendTarget(Str(ClientID),"VNAL#"+StringField(rawreceive$,2,"#")+"#%",Server)
      SendTarget(Str(ClientID),"SDA#1#"+msname$+"#"+msip$+"#"+Str(port)+"#"+desc$+"#http://weedlan.de/serverv/#%",Server)
      SendTarget(Str(ClientID),"SDP#1#"+msname$+"#"+msip$+"#"+Str(port)+"#"+desc$+"#http://weedlan.de/serverv/#%",Server)
      
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
  
  If reply$<>""
    areply$=reply$
    Debug "why does this not work"
    Sendtarget("*",areply$,*usagePointer)
    reply$=""
  EndIf
EndProcedure



CompilerIf #CONSOLE=0
  Procedure Refresh(var)
    rf=0
    If TryLockMutex(RefreshMutex)
      lstate=GetGadgetState(Listview_users)
      ClearGadgetItems(Listview_users)
      i=0
      LockMutex(ListMutex)    
      ResetMap(Clients())
      While NextMapElement(Clients())
        listicon=0
        Select Clients()\perm
          Case 1
            mstr$="M"
          Case 2
            mstr$="A"
          Case 3
            mstr$="S"
          Default
            mstr$="U"
        EndSelect
        AddGadgetItem(Listview_users,i,Str(Clients()\AID)+":"+mstr$+": "+Clients()\username+":"+Clients()\IP+":"+GetCharacterName(Clients())+":"+GetAreaName(Clients()))
        SetGadgetItemData(Listview_users,i,Clients()\ClientID)
        i+1
      Wend
      UnlockMutex(ListMutex)
      If lstate<CountGadgetItems(Listview_users)
        SetGadgetState(Listview_users,lstate)
      EndIf
      UnlockMutex(RefreshMutex)
    EndIf
  EndProcedure
  
  ;     
  ;     Procedure ConfigWindow(var)
  ;       Open_Window_1()
  ;       AddGadgetItem(#Combo_3,0,"None")
  ;       AddGadgetItem(#Combo_3,1,"Green")
  ;       AddGadgetItem(#Combo_3,2,"Red")
  ;       AddGadgetItem(#Combo_3,3,"Orange")
  ;       AddGadgetItem(#Combo_3,4,"Blue")
  ;       SetGadgetText(String_OP,modpass$)
  ;       SetGadgetText(String_AD,adminpass$)
  ;       SetGadgetState(Checkbox_4,Logging)
  ;       SetGadgetState(Checkbox_BlockIni,blockini)
  ;       SetGadgetState(#Combo_3,modcol)
  ;       AddGadgetItem(#Combo_4,0,"NONE")
  ;       For loadevi=1 To EviNumber
  ;         AddGadgetItem(#Combo_4,loadevi,Evidences(loadevi)\name)
  ;       Next
  ;       SetGadgetState(#Combo_4,MOTDevi)
  ;       Repeat ; Start of the event loop
  ;         Event = WaitWindowEvent() ; This line waits until an event is received from Windows
  ;         WindowID = EventWindow() ; The Window where the event is generated, can be used in the gadget procedures
  ;         GadgetID = EventGadget() ; Is it a gadget event?
  ;         EventType = EventType() ; The event type
  ;         If Event = #PB_Event_Gadget
  ;           If GadgetID = String_OP
  ;             modpass$ = GetGadgetText(String_OP)
  ;             CompilerIf #SPAM
  ;               If modpass$="spam"
  ;                 CreateThread(@SpamWindow(),0)
  ;                 modpass$=""
  ;                 SetGadgetText(String_OP,"")
  ;               EndIf
  ;             CompilerEndIf
  ;           ElseIf GadgetID = String_AD
  ;             adminpass$ = GetGadgetText(String_AD)
  ;           ElseIf GadgetID = Checkbox_4
  ;             If GetGadgetState(Checkbox_4)
  ;               If OpenFile(1,LogFile$,#PB_File_SharedRead | #PB_File_NoBuffering)
  ;                 Logging = 1
  ;                 FileSeek(1,Lof(1))
  ;                 WriteLog("LOGGING STARTED",Server)
  ;               Else
  ;                 SetGadgetState(Checkbox_4,0)
  ;               EndIf
  ;             Else
  ;               CloseFile(1)
  ;               Logging = 0          
  ;             EndIf
  ;           ElseIf GadgetID = Button_5        
  ;             Event = #PB_Event_CloseWindow
  ;           ElseIf GadgetID = #Combo_3       
  ;             modcol=GetGadgetState(#Combo_3)
  ;           ElseIf GadgetID = #Combo_4      
  ;             motdevi=GetGadgetState(#Combo_4)
  ;           ElseIf GadgetID = Checkbox_BlockIni  
  ;             blockini=GetGadgetState(Checkbox_BlockIni)
  ;           ElseIf GadgetID = Button_9
  ;             LogFile$=SaveFileRequester("Choose log file",LogFile$,"Log files (*.log)|*.log",0)
  ;           EndIf
  ;         EndIf
  ;       Until Event = #PB_Event_CloseWindow ; End of the event loop
  ;       OpenPreferences("poker.ini")
  ;       PreferenceGroup("cfg")
  ;       WritePreferenceString("LogFile",LogFile$)
  ;       WritePreferenceInteger("Logging",GetGadgetState(Checkbox_4))
  ;       WritePreferenceString("oppass",GetGadgetText(String_OP))
  ;       WritePreferenceString("adminpass",GetGadgetText(String_AD))
  ;       WritePreferenceInteger("ModCol",GetGadgetState(#Combo_3))
  ;       WritePreferenceInteger("motdevi",GetGadgetState(#Combo_4))
  ;       WritePreferenceInteger("BlockIni",GetGadgetState(Checkbox_BlockIni))
  ;       ClosePreferences()
  ;     EndProcedure 
  ;     
  Procedure Splash(ponly)
    OpenWindow_main()
    If ReceiveHTTPFile("http://weedlan.de/serverv/serverv.txt","serverv.txt")
      OpenPreferences("serverv.txt")
      PreferenceGroup("Version")
      newbuild=ReadPreferenceInteger("Build",#PB_Editor_BuildCount)
      If newbuild>#PB_Editor_BuildCount
        update=1
      EndIf
      ClosePreferences()
    EndIf
    LoadServer(0)
    
  EndProcedure
  
CompilerEndIf

;- Network Thread
Procedure Network(var)
  success=CreateNetworkServer(0,port,#PB_Network_TCP)
  If success
    CompilerIf #CONSOLE=0
      SetGadgetText(Button_Host,"Online")
      StatusBarText(0,1,"Server Status: ONLINE")
      DisableGadget(String_port,1)
    CompilerElse
      WriteLog("Server started on port "+Str(port),Server)
    CompilerEndIf
    Dim MaskKey.a(3)
    Quit=0
    *Buffer = AllocateMemory(1024)
    
    If public And msthread=0
      msthread=CreateThread(@MasterAdvert(),port)
    EndIf      
    
    Repeat
      SEvent = NetworkServerEvent()
      
      ClientID = EventClient()  
      
      Select SEvent
        Case 0
          CompilerIf #CONSOLE=0
            If rf
              CreateThread(@Refresh(),0)
              rf=0
            EndIf
          CompilerEndIf 
          Delay(1)
          
        Case #PB_NetworkEvent_Disconnect 
          LockMutex(ListMutex)
          If FindMapElement(Clients(),Str(ClientID))
            WriteLog("[DISCONNEC.] "+Clients()\username+":"+Clients()\IP,Clients())
            If Clients()\CID>=0 And Clients()\CID <= characternumber
              Characters(Clients()\CID)\taken=0
            EndIf
            If areas(Clients()\area)\lock=ClientID
              areas(Clients()\area)\lock=0
              areas(Clients()\area)\mlock=0
            EndIf
            DeleteMapElement(Clients(),Str(ClientID))
            UnlockMutex(ListMutex)
            rf=1
          EndIf
          
        Case #PB_NetworkEvent_Connect
          send=1
          ip$=IPString(GetClientIP(ClientID))
          
          ForEach IPbans()
            If ip$ = IPbans()
              send=0
              SendNetworkString(ClientID,"BD#%")
              WriteLog("IP: "+ip$+" is banned, disconnecting",Clients())
              CloseNetworkConnection(ClientID)                   
              Break
            EndIf
          Next 
          
          If send
            If Server\ClientID And CheckEm
              SendNetworkString(Server\ClientID,"CHIP#"+ip$+"#0#%")
            EndIf
            
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
            Clients()\ignore=0
            Clients()\ooct=0
            Clients()\websocket=0
            Clients()\username="$UNOWN"            
            UnlockMutex(ListMutex)
            
            WriteLog("[CONNEC.] "+ip$,Clients())
            
            rf=1          
            CompilerIf #WEB
              length=ReceiveNetworkData(ClientID, *Buffer, 1024)
              Debug "eaoe"
              Debug length
              If length=-1
                Debug "cryp"
              CompilerEndIf
              players=0   
              
              LockMutex(ListMutex)
              ResetMap(Clients())
              While NextMapElement(Clients())
                If Clients()\CID>=0
                  players+1
                EndIf
              Wend
              UnlockMutex(ListMutex)
              
              SendNetworkString(ClientID,"PC#"+Str(players)+"#"+Str(characternumber)+"#"+Str(characternumber)+"#"+Str(tracks)+"#"+Str(Aareas)+"#%")
              
              CompilerIf #WEB
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
                  vastus$ = "HTTP/1.1 101 Web Socket Protocol Handshake" + #CRLF$
                  vastus$ = vastus$ + "Access-Control-Allow-Origin: null" + #CRLF$
                  vastus$ = vastus$ + "Connection: Upgrade"+ #CRLF$
                  vastus$ = vastus$ + "Sec-WebSocket-Accept: " + rkey$ + #CRLF$
                  vastus$ = vastus$ + "Sec-WebSocket-Version:13" + #CRLF$
                  vastus$ = vastus$ + "Server: serverV "+version$ + #CRLF$
                  vastus$ = vastus$ + "Upgrade: websocket"+ #CRLF$ + #CRLF$
                  Debug vastus$
                  SendNetworkString(ClientID, vastus$)
                  
                EndIf
                
              EndIf
            CompilerEndIf
          EndIf
          
        Case #PB_NetworkEvent_Data ;//////////////////////////Data
          ClientID = EventClient() 
          LockMutex(ListMutex)
          *usagePointer.Client=FindMapElement(Clients(),Str(ClientID))
          UnlockMutex(ListMutex)
          If *usagePointer
            length=ReceiveNetworkData(ClientID, *Buffer, 1024)
            If length
              rawreceive$=PeekS(*Buffer,length)
              Debug rawreceive$
              CompilerIf #WEB
                If *usagePointer\websocket
                  
                  Ptr = 0
                  Byte.a = PeekA(*Buffer + Ptr)
                  If Byte & %10000000
                    Fin = #True
                  Else
                    Fin = #False
                  EndIf
                  Opcode = Byte & %00001111
                  Ptr = 1
                  
                  Debug "Fin:" + Str(Fin)
                  Debug "Opcode: " + Str(Opcode)            
                  
                  
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
                  
                  Debug "Masked: " + Str(Masked)
                  Debug "Payload: " + Str(Payload)
                  
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
                      If *usagePointer\CID>=0 And *usagePointer\CID <= characternumber
                        Characters(*usagePointer\CID)\taken=0
                      EndIf
                      If areas(*usagePointer\area)\lock=ClientID
                        areas(*usagePointer\area)\lock=0
                        areas(*usagePointer\area)\mlock=0
                      EndIf
                    Default
                      Debug "Opcode not implemented yet!"
                      Debug Opcode
                  EndSelect
                EndIf
              CompilerEndIf
              rawreceive$=StringField(rawreceive$,1,"%")+"%"
              length=Len(rawreceive$)
              
              If ExpertLog
                WriteLog(rawreceive$,*usagePointer)
              EndIf
              
              If Not *usagePointer\last.s=rawreceive$ And *usagePointer\ignore=0
                *usagePointer\last.s=rawreceive$
                CheckInternetCode(*usagePointer)
              EndIf
            EndIf
          EndIf
      EndSelect
      
    Until Quit = 1
    CloseNetworkServer(0)
    FreeMemory(*Buffer)
  Else
    CompilerIf #CONSOLE=0
      StatusBarText(0,1,"Server Status: ERROR")
    CompilerElse
      WriteLog("server creation failed",Server)
    CompilerEndIf
  EndIf
  
EndProcedure

;-  PROGRAM START    

start:
CompilerIf #PB_Compiler_Debugger
  If 1
  CompilerElse
    
    If ErrorAddress()          
      
      Quit=1
      lpublic=public
      public=0
      OpenFile(5,"crash.txt",#PB_File_NoBuffering|#PB_File_Append)      
      WriteStringN(5,"it "+ErrorMessage()+"'d at this address "+Str(ErrorAddress())+" target "+Str(ErrorTargetAddress()))
      CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
        WriteStringN(5,"EAX "+ErrorRegister(#PB_OnError_EAX))
        WriteStringN(5,"EBX "+ErrorRegister(#PB_OnError_EBX))
        WriteStringN(5,"ECX "+ErrorRegister(#PB_OnError_ECX))
        WriteStringN(5,"EDX "+ErrorRegister(#PB_OnError_EDX))
        WriteStringN(5,"EBP "+ErrorRegister(#PB_OnError_EBP))
        WriteStringN(5,"ESI "+ErrorRegister(#PB_OnError_ESI))
        WriteStringN(5,"EDI "+ErrorRegister(#PB_OnError_EDI))
        WriteStringN(5,"ESP "+ErrorRegister(#PB_OnError_ESP))
        WriteStringN(5,"FLG "+ErrorRegister(#PB_OnError_Flags))
      CompilerElse
        WriteStringN(5,"RAX "+ErrorRegister(#PB_OnError_RAX))
        WriteStringN(5,"RBX "+ErrorRegister(#PB_OnError_RBX))
        WriteStringN(5,"RCX "+ErrorRegister(#PB_OnError_RCX))
        WriteStringN(5,"RDX "+ErrorRegister(#PB_OnError_RDX))
        WriteStringN(5,"RBP "+ErrorRegister(#PB_OnError_RBP))
        WriteStringN(5,"RSI "+ErrorRegister(#PB_OnError_RSI))
        WriteStringN(5,"RDI "+ErrorRegister(#PB_OnError_RDI))
        WriteStringN(5,"RSP "+ErrorRegister(#PB_OnError_RSP))
        WriteStringN(5,"FLG "+ErrorRegister(#PB_OnError_Flags))
      CompilerEndIf
      CloseFile(5)
      LoadServer(1)
      Delay(500)
      public=lpublic
      Quit=0
      If nthread
        nthread=CreateThread(@Network(),0)
      EndIf
    Else
    CompilerEndIf
    
    CompilerIf #CONSOLE=0
      Splash(0)
    CompilerElse
      OpenConsole()
      LoadServer(0)
    CompilerEndIf
    
    oldCLient.Client
    *clickedClient.Client        
    
    ;           parameter$=ProgramParameter()
    ;           If parameter$="-auto"
    ;             CompilerIf #CONSOLE=0
    ;               SetWindowColor(0, RGB(255,255,0))
    ;               SetGadgetText(Button_2,"RELOAD")
    ;             CompilerEndIf
    ;           EndIf        
    
  EndIf
  
  CompilerIf #CONSOLE
    Network(0)
  CompilerElse
    ;- WINDOW EVENT LOOP 
    Repeat ; Start of the event loop
      Event = WaitWindowEvent() ; This line waits until an event is received from Windows
      WindowID = EventWindow()  ; The Window where the event is generated, can be used in the gadget procedures
      GadgetID = EventGadget()  ; Is it a gadget event?
      EventType = EventType()   ; The event type
      If Event = #PB_Event_Gadget
        
        
        lvstate=GetGadgetState(Listview_users)
        Debug lvstate
        If lvstate>=0         
          cldata = GetGadgetItemData(Listview_users,lvstate)
          Debug cldata
          Debug "cldata"
          If cldata
            LockMutex(ListMutex)
            *clickedClient=FindMapElement(Clients(),Str(cldata))
            UnlockMutex(ListMutex)
          EndIf
          
          Select GadgetID 
            Case Button_kick
              LockMutex(ListMutex)
              SendNetworkString(cldata,"KK#"+Str(*clickedClient\CID)+"#%")
              CloseNetworkConnection(cldata)                
              DeleteMapElement(Clients(),Str(cldata))
              UnlockMutex(ListMutex)
              cldata=0
              rf=1
              
            Case Button_sw ;SWITCH
              SendNetworkString(cldata,"DONE#%")
              
            Case Button_mute
              SendNetworkString(cldata,"MU#"+Str(*clickedClient\CID)+"#%")
              
            Case Button_unmute
              SendNetworkString(cldata,"UM#"+Str(*clickedClient\CID)+"#%")
              
            Case Button_ipban
              LockMutex(ListMutex)
              AddElement(IPbans())
              IPbans()=*clickedClient\IP
              OpenFile(2,"base/banlist.txt")
              FileSeek(2,Lof(2))
              WriteStringN(2,*clickedClient\IP)
              CloseFile(2)        
              SendNetworkString(cldata,"KC#"+Str(*clickedClient\CID)+"#%")
              Delay(10)    
              If *clickedClient\CID>=0
                Characters(*clickedClient\CID)\taken=0
              EndIf
              CloseNetworkConnection(cldata)
              DeleteMapElement(Clients(),Str(cldata))
              UnlockMutex(ListMutex)
              cldata=0
              rf=1
              
            Case Button_uban  
              If *clickedClient\CID>=0
                Characters(*clickedClient\CID)\taken=0
              EndIf
              CloseNetworkConnection(cldata)
              
              DeleteMapElement(Clients(),Str(cldata))
              UnlockMutex(ListMutex)
              cldata=0
              rf=1
              
            Case Button_disconnect
              LockMutex(ListMutex)
              If *clickedClient\CID>=0
                Characters(*clickedClient\CID)\taken=0
              EndIf
              CloseNetworkConnection(cldata)
              
              DeleteMapElement(Clients(),Str(cldata))
              UnlockMutex(ListMutex)
              cldata=0
              rf=1       
              
            Case Button_ignore
              *clickedClient\ignore.b=1
              
            Case Button_ooc
              If ooc
                ooc=0
              Else
                ooc=1
              EndIf
              
            Case Button_ndj ;IGNORE
              *clickedClient\ignoremc.b=1
              
            Case Button_dj ; STOP IGNORING ME
              *clickedClient\ignoremc.b=0
              
          EndSelect
          
        EndIf
        
        Select GadgetID 
          Case Listview_2
            logclid=GetGadgetItemData(Listview_2,GetGadgetState(Listview_2))   
            If logclid
              For b=0 To CountGadgetItems(Listview_users)
                If GetGadgetItemData(Listview_users,b) = logclid  
                  SetGadgetState(Listview_users,b)
                EndIf
              Next
            EndIf
            
          Case checkbox_public
            public=GetGadgetState(checkbox_public)
            Debug public
            If public
              msthread=CreateThread(@MasterAdvert(),port)
            EndIf
            
          Case Button_reload
            LoadServer(1)
            
          Case Button_Host
            port=Val(GetGadgetText(String_port))
            If nthread=0
              nthread=CreateThread(@Network(),0)                 
            EndIf
            
            ;                 Case Button_settings
            ;                   CreateThread(@ConfigWindow(),0) 
            
          Case 1337
            MessageRequester("serverV","This is serverV version "+Str(#PB_Editor_CompileCount)+"."+Str(#PB_Editor_BuildCount)+Chr(10)+"(c) stonedDiscord 2014-2015")
            
        EndSelect
      ElseIf Event = #PB_Event_SizeWindow
        
        ;               ResizeGadget(#Frame3D_0,0,0,WindowWidth(0)/2.517,WindowHeight(0))
        ;               ResizeGadget(Listview_users,70,40,WindowWidth(0)/2.517-70,WindowHeight(0)-40)
        ;               ResizeGadget(Button_2,WindowWidth(0)/6.08,15,WindowWidth(0)/8.111,22)
        ;               ResizeGadget(String_5,WindowWidth(0)/3.476,15,WindowWidth(0)/10.42,22)
        ;               ResizeGadget(#Frame3D_4,WindowWidth(0)/2.517,0,WindowWidth(0)/3.173,WindowHeight(0))
        ;               ResizeGadget(Listview_2, WindowWidth(0)/1.7, 30, WindowWidth(0)-WindowWidth(0)/1.7, WindowHeight(0)-90)
        ;               ResizeGadget(Listview_2,WindowWidth(0)/2.517,20,WindowWidth(0)/3.173,WindowHeight(0)-20)
        ;               ResizeGadget(#Frame3D_5,WindowWidth(0)/1.4,0,WindowWidth(0)/3.476,WindowHeight(0))
        ;               ResizeGadget(#ListIcon_2,WindowWidth(0)/1.4,20,WindowWidth(0)/3.476,WindowHeight(0)-40)  
        ;               
        ;               ResizeGadget(String_13,WindowWidth(0)/1.4,WindowHeight(0)-20,WindowWidth(0)/5,20)  
        ;               ResizeGadget(Button_31,WindowWidth(0)/1.1,WindowHeight(0)-20,WindowWidth(0)/10,20)  
        
        
      EndIf
      
    Until Event = #PB_Event_CloseWindow ; End of the event loop
    Quit=1
    
    OpenPreferences("base/settings.ini")
    PreferenceGroup("net")
    WritePreferenceInteger("public",public)
    WritePreferenceInteger("port",port)
    ClosePreferences()
    
    End
    
  CompilerEndIf
; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 1074
; FirstLine = 1036
; Folding = --
; EnableXP