;EnableExplicit
; yes this is the legIt serverV source code please report bugfixes/modifications/feature requests to sD/trtukz on skype
CompilerIf #PB_Compiler_OS <> #PB_OS_Windows
  #MB_ICONERROR=0
CompilerEndIf

#CROSS=0
Global version$="1.3"
Global view$
Global Logging.b=0
Global public.b=0
Global CheckEm.b=0
Global LogFile$="log.txt"
Global modpass$=""
Global adminpass$=""
Global ooc.b=1
Global Quit=0
Global defbar$="10"
Global probar$="10"
Global port=6541
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
Global msuser$
Global mspass$
Global blockini.b=0
Global ExpertLog=0
Global tracks=0
Global itemamount
Global msthread=0
Global LoginReply$="MODOK#%"
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
Global NewList Userbans.s()
Global NewList SDbans.s()
Global Dim ReadyVItem.s(100)
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
Global Dim Items.ItemData(100)
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
  Debug port
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
  ReDim Characters.ACharacter(characternumber)
  For loadchars=0 To characternumber
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
      ReadyVMusic(readytracks) = "MD#" + Str(readytracks+1) + "#" + Music()\TrackName
      If NextElement(Music())
        ReadyVMusic(readytracks) + "#" + Str(readytracks+2) + "#" + Music()\TrackName
        PreviousElement(Music())
      EndIf
      ReadyVMusic(readytracks)+"#%"
      readytracks+1
    Until readytracks=tracks
    
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
        SDbans()=hdban$
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
        IPbans()=ipban$
      EndIf
    Wend
    CloseFile(2)
  EndIf
  
  If ReadFile(2, "banuser.txt")
    ClearList(Userbans())
    While Eof(2) = 0
      ipban$=ReadString(2)
      If ipban$<>""
        AddElement(Userbans())
        Userbans()=ipban$
      EndIf
    Wend
    CloseFile(2)
  EndIf
  
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
            DeleteMapElement(Clients())
            SendNetworkString(kclid,"KC#"+Str(kcid)+"#%")
            CloseNetworkConnection(kclid)          
            akck+1
            
          Case #BAN
            AddElement(IPbans())
            IPbans()=Clients()\IP
            If OpenFile(2,"banip.txt")
              FileSeek(2,Lof(2))
              WriteStringN(2,Clients()\IP)
              CloseFile(2)
            EndIf
            kclid=Clients()\ClientID
            DeleteMapElement(Clients())
            SendNetworkString(kclid,"KC#"+Str(kcid)+"#%")
            CloseNetworkConnection(kclid)  
            akck+1
          Case #IDBAN
            AddElement(Userbans())
            Userbans()=Clients()\username
            If OpenFile(2,"banuser.txt")
              FileSeek(2,Lof(2))
              WriteStringN(2,Clients()\username)
              CloseFile(2)
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
  CheckEm=ReadPreferenceInteger("Check",0)
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
            StatusBarText(0,0,"AS Connection: ERROR, TRYING TO RECONNECT")
          CompilerEndIf
        ElseIf NEvent=#PB_NetworkEvent_Data
          msinfo=ReceiveNetworkData(msID,*null,100)
          If msinfo=-1
            sr=-1
            CompilerIf #CONSOLE=0
              StatusBarText(0,0,"AS Connection: ERROR, TRYING TO RECONNECT")
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
                  StatusBarText(0,0,"AS Connection: ERROR, WRONG VERSION")
                CompilerEndIf
                public=0
              Case "VNAL"
                sr=SendNetworkString(msID,"RequestPub#"+msname$+"#"+Str(port)+"#"+desc$+"#"+www$+"#%")
              Case "No"
                WriteLog("Wrong master credentials",Server)
              Case "VNOBD"
                WriteLog("Banned from master",Server)
                CompilerIf #CONSOLE=0
                  StatusBarText(0,0,"AS Connection: ERROR, ACCOUNT BANNED")
                CompilerEndIf
                public=0
              Case "NOPUB"
                WriteLog("Banned from hosting",Server)
                CompilerIf #CONSOLE=0
                  StatusBarText(0,0,"AS Connection: ERROR, NO HOSTING ACCOUNT")
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
                    If ReadFile(7,"base/scene/"+scene$+"/PlayerData/"+Clients()\username+".txt")
                      While Eof(7) = 0
                        Clients()\Inventory[ir]=Val(ReadString(7))
                        ir+1
                      Wend
                      
                      CloseFile(7)
                    EndIf
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


Procedure SwitchAreas(*usagePointer.Client,narea$)
  Define ir,oarea,narea
  Define sendd=0
  narea=Val(narea$)
  For ir=1 To Aareas
    Debug areas(ir)\name
    If areas(ir)\name = narea$
      narea = ir
      Break
    EndIf
  Next
  If narea<=Aareas And narea>=1
    oarea=*usagePointer\area
    LockMutex(ListMutex)
    Areas(oarea)\players=0
    Areas(narea)\players=0
    PushMapPosition(Clients())
    ResetMap(Clients())
    While NextMapElement(Clients())
      If Clients()\CID=*usagePointer\CID And Clients()\ClientID<>*usagePointer\ClientID
        If Clients()\area=Val(narea$) Or MultiChar=0
          sendd=1
        EndIf
      EndIf
      If Clients()\area=narea
        Areas(narea)\players+1
      EndIf
      If Clients()\area=oarea
        Areas(oarea)\players+1
      EndIf
    Wend
    PopMapPosition(Clients())
    UnlockMutex(ListMutex)   
    
    If Not areas(Val(narea$))\lock Or *usagePointer\perm>areas(Val(narea$))\mlock
      
      If areas(*usagePointer\area)\lock=*usagePointer\ClientID
        areas(*usagePointer\area)\lock=0
        areas(*usagePointer\area)\mlock=0
      EndIf
      areas(*usagePointer\area)\players-1
      *usagePointer\area=narea
      areas(*usagePointer\area)\players+1
      If sendd=1
        *usagePointer\CID=-1
        ;SendDone(*usagePointer)
      Else
        SendTarget(Str(*usagePointer\ClientID),"ROOK#"+Str(areas(*usagePointer\area)\good)+"#"+Str(areas(*usagePointer\area)\evil)+"#%",Server)
      EndIf
      SendTarget(Str(*usagePointer\ClientID),"RoC#"+Str(oarea)+"#"+Str(areas(*usagePointer\area)\players)+"#"+Str(narea)+"#"+Str(areas(0)\players+1)+"#%",Server)
    Else
      SendTarget(Str(*usagePointer\ClientID),"FI#area locked#%",Server)
    EndIf
    
  Else
    SendTarget(Str(*usagePointer\ClientID),"FI#Not a valid area#%",Server)
  EndIf
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
    areas(adareas)\players=APlayers(adareas)
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
        Sendtarget("Area"+Str(*usagePointer\area),msreply$,*usagePointer)
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
          Sendtarget("Area"+Str(*usagePointer\area),"MC#"+GetCharacterName(*usagePointer)+"#"+StringField(rawreceive$,3,"#")+"#"+areas(*usagePointer\area)\bg+"#"+Str(*usagePointer\CID)+"#%",*usagePointer)
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
      WriteLog("[OOC]["+GetCharacterName(*usagePointer)+"]["+StringField(rawreceive$,2,"#")+"]["+ctparam$+"]",*usagePointer)
      
      Debug ctparam$
      ;       If Left(ctparam$,1)="/"
      ;         Select StringField(ctparam$,1," ")
      ;           Case "/ps"
      ;             If modpass$=Mid(ctparam$,5)
      ;               If modpass$<>""
      ;                 SendTarget(Str(ClientID),LoginReply$,Server)
      ;                 *usagePointer\perm=1
      ;                 *usagePointer\ooct=1
      ;               EndIf
      ;             ElseIf adminpass$=Mid(ctparam$,5)
      ;               If adminpass$<>""
      ;                 SendTarget(Str(ClientID),LoginReply$,Server)
      ;                 SendTarget(Str(ClientID),"UM#"+Str(*usagePointer\CID)+"#%",Server)
      ;                 *usagePointer\perm=2
      ;                 *usagePointer\ooct=1
      ;               EndIf
      ;             EndIf
      ;             send=0
      ;             
      ;           Case "/ooc"
      ;             If *usagePointer\perm
      ;               ooc=1
      ;             EndIf
      ;             
      ;           Case "/nooc"
      ;             If *usagePointer\perm
      ;               ooc=0
      ;             EndIf
      ;             
      ;           Case "/toggle"
      ;             If *usagePointer\perm
      ;               Select StringField(ctparam$,2," ")
      ;                 Case "WTCE"
      ;                   If rt
      ;                     rt=0
      ;                   Else
      ;                     rt=1
      ;                   EndIf
      ;                   pr$="FI#WTCE is "
      ;                   If rt=1
      ;                     pr$+"enabled%"
      ;                   Else
      ;                     pr$+"disabled%"
      ;                   EndIf
      ;                   SendTarget(Str(ClientID),pr$,Server)
      ;                 Case "LogHD"
      ;                   If loghd
      ;                     loghd=0
      ;                   Else
      ;                     loghd=1
      ;                   EndIf
      ;                 Case "ExpertLog"
      ;                   If ExpertLog
      ;                     ExpertLog=0
      ;                   Else
      ;                     ExpertLog=1
      ;                   EndIf
      ;               EndSelect
      ;             EndIf
      ;             
      ;             ;             Case "/help"
      ;             ;               SendTarget(Str(ClientID),"CT#SERVER#Check http://stoned.ddns.net/#%",Server)
      ;             
      ;           Case "/public"
      ;             Debug ctparam$
      ;             If StringField(ctparam$,2," ")=""
      ;               pr$="FI#server is "
      ;               If public=0
      ;                 pr$+"not "
      ;               EndIf
      ;               SendTarget(Str(ClientID),pr$+"public%",Server)
      ;             Else
      ;               If *usagePointer\perm>1
      ;                 public=Val(StringField(ctparam$,2," "))
      ;                 If public
      ;                   msthread=CreateThread(@Masteradvert(),port)
      ;                 EndIf
      ;                 CompilerIf #CONSOLE=0
      ;                   SetGadgetState(Checkbox_MS,public)
      ;                 CompilerEndIf
      ;               EndIf
      ;             EndIf
      ;             
      ;             
      ;           Case "/send"  
      ;             If *usagePointer\perm
      ;               sname$=StringField(ctparam$,2," ")
      ;               Debug sname$
      ;               smes$=Mid(ctparam$,8+Len(sname$),Len(ctparam$)-6)
      ;               smes$=Escape(smes$)
      ;               SendTarget(sname$,smes$,Server)
      ;             EndIf
      ;             
      ;           Case "/sendall"
      ;             If *usagePointer\perm
      ;               reply$=Mid(ctparam$,10,Len(ctparam$)-2)
      ;               reply$=Escape(reply$)
      ;             EndIf
      ;             
      ;           Case "/reload"
      ;             If *usagePointer\perm>1
      ;               LoadServer(1)
      ;               SendTarget(Str(ClientID),"FI#serverV reloaded%",Server)
      ;             EndIf
      ;             
      ;           Case "/play"
      ;             If *usagePointer\perm                
      ;               song$=Right(ctparam$,Len(ctparam$)-6)                
      ;               SendTarget("*","MC#"+song$+"#"+Str(*usagePointer\CID)+"#%",*usagePointer)                
      ;             EndIf
      ;             
      ;             
      ;           Case "/ip"
      ;             If *usagePointer\perm
      ;               CreateThread(@ListIP(),ClientID)
      ;               WriteLog("["+GetCharacterName(*usagePointer)+"] used /ip",*usagePointer)
      ;             EndIf 
      ;             
      ;           Case "/unban"
      ;             If *usagePointer\perm>1
      ;               ub$=Mid(ctparam$,8,Len(ctparam$)-2)
      ;               Debug ub$
      ;               If CreateFile(2,"base/banlist.txt")
      ;                 Debug "file recreated"
      ;                 ForEach IPbans()
      ;                   If IPbans()=ub$
      ;                     DeleteElement(IPbans())
      ;                   Else
      ;                     WriteStringN(2,IPbans())
      ;                   EndIf
      ;                 Next
      ;                 CloseFile(2)                                
      ;               EndIf
      ;               
      ;             EndIf
      ;             
      ;           Case "/stop"
      ;             If *usagePointer\perm>1
      ;               Quit=1
      ;               public=0
      ;             EndIf
      ;             
      ;           Case "/kc"
      ;             If *usagePointer\perm
      ;               akck=KickBan(Mid(ctparam$,7,Len(ctparam$)-2),#KICK,*usagePointer\perm)
      ;               SendTarget(Str(ClientID),"FI#kicked "+Str(akck)+" clients%",Server)
      ;               WriteLog("["+GetCharacterName(*usagePointer)+"] used "+ctparam$,*usagePointer)
      ;               
      ;             EndIf
      ;           Case "/bi"
      ;             If *usagePointer\perm
      ;               akck=KickBan(Mid(ctparam$,6,Len(ctparam$)-2),#BAN,*usagePointer\perm)
      ;               SendTarget(Str(ClientID),"FI#banned "+Str(akck)+" clients%",Server)
      ;             EndIf
      ;             WriteLog("["+GetCharacterName(*usagePointer)+"] used "+ctparam$,*usagePointer)
      ;             
      ;           Case "/mu"
      ;             If *usagePointer\perm
      ;               akck=KickBan(Mid(ctparam$,7,Len(ctparam$)-2),#MUTE,*usagePointer\perm)
      ;               SendTarget(Str(ClientID),"FI#muted "+Str(akck)+" clients%",Server)
      ;             EndIf
      ;             WriteLog("["+GetCharacterName(*usagePointer)+"] used "+ctparam$,*usagePointer)
      ;             
      ;           Case "/um"
      ;             If *usagePointer\perm
      ;               akck=KickBan(Mid(ctparam$,9,Len(ctparam$)-2),#UNMUTE,*usagePointer\perm)
      ;               SendTarget(Str(ClientID),"FI#unmuted "+Str(akck)+" clients%",Server)
      ;             EndIf
      ;             WriteLog("["+GetCharacterName(*usagePointer)+"] used "+ctparam$,*usagePointer)
      ;             
      ;           Case "/ignore"
      ;             If *usagePointer\perm
      ;               akck=KickBan(Mid(ctparam$,9,Len(ctparam$)-2),#CIGNORE,*usagePointer\perm)
      ;               SendTarget(Str(ClientID),"FI#muted "+Str(akck)+" clients%",Server)
      ;             EndIf
      ;             WriteLog("["+GetCharacterName(*usagePointer)+"] used "+ctparam$,*usagePointer)
      ;             
      ;           Case "/unignore"
      ;             If *usagePointer\perm
      ;               akck=KickBan(Mid(ctparam$,11,Len(ctparam$)-2),#UNIGNORE,*usagePointer\perm)
      ;               SendTarget(Str(ClientID),"FI#unmuted "+Str(akck)+" clients%",Server)
      ;             EndIf
      ;             WriteLog("["+GetCharacterName(*usagePointer)+"] used "+ctparam$,*usagePointer)
      ;             
      ;           Case "/undj"
      ;             If *usagePointer\perm
      ;               akck=KickBan(Mid(ctparam$,7,Len(ctparam$)-2),#UNDJ,*usagePointer\perm)
      ;               SendTarget(Str(ClientID),"FI#muted "+Str(akck)+" clients%",Server)
      ;             EndIf
      ;             WriteLog("["+GetCharacterName(*usagePointer)+"] used "+ctparam$,*usagePointer)
      ;             
      ;           Case "/dj"
      ;             If *usagePointer\perm
      ;               akck=KickBan(Mid(ctparam$,5,Len(ctparam$)-2),#DJ,*usagePointer\perm)
      ;               SendTarget(Str(ClientID),"FI#unmuted "+Str(akck)+" clients%",Server)
      ;             EndIf
      ;             WriteLog("["+GetCharacterName(*usagePointer)+"] used "+ctparam$,*usagePointer)
      ;             
      ;         EndSelect
      ;     Else
      If ooc
        *usagePointer\last.s=rawreceive$
        Sendtarget("*","CT#"+StringField(rawreceive$,2,"#")+"#"+StringField(rawreceive$,3,"#")+"#%",*usagePointer)
        AddGadgetItem(Memo_ooc,-1,StringField(rawreceive$,2,"#")+": "+StringField(rawreceive$,3,"#"))
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
        SendTarget(Str(ClientID),ReadyVMusic(0),Server)
      EndIf
      
      
    Case "RMD" ;music list
      start=Val(StringField(rawreceive$,2,"#"))-1
      send=0
      If start<=tracks-1 And start>=0
        SendTarget(Str(ClientID),ReadyVMusic(start),Server)
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
          SendTarget("Area"+Str(*usagePointer\area),"HP#GOOD#"+Str(Areas(*usagePointer\area)\good)+"#%",*usagePointer)
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
          SendTarget("Area"+Str(*usagePointer\area),"HP#EVIL#"+Str(Areas(*usagePointer\area)\evil)+"#%",*usagePointer)
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
      SendTarget("Area"+Str(*usagePointer\area),"FI#"+GetCharacterName(*usagePointer)+" rolled: "+Str(rolls)+"d"+Str(dicemax)+", Result: "+Str(random)+"#"+FormatDate("%hh:%ii:%ss",Date())+"#%",*usagePointer)
      
    Case "FB"
      SendTarget(Str(ClientID),"KC#go be gay somewhere else#%",Server)
      KickBan(Str(ClientID),#DISCO,3)
      
    Case "FCl"
      SendTarget(Str(ClientID),"KC#go be gay somewhere else#%",Server)
      KickBan(Str(ClientID),#DISCO,3)
      
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
      *usagePointer\type=#MASTER
      SendTarget(Str(ClientID),"VNAL#"+StringField(rawreceive$,2,"#")+"#%",Server)
      SendTarget(Str(ClientID),"SDA#1#"+msname$+"#"+msip$+"#"+Str(port)+"#"+desc$+"#http://stoned.ddns.net/#%",Server)
      SendTarget(Str(ClientID),"SDP#0#"+msname$+"#"+msip$+"#"+Str(port)+"#"+desc$+"#http://stoned.ddns.net/#%",Server)
      
    Case "VER"
      *usagePointer\type=#MASTER
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
      lstate=GetGadgetState(Listbox_users)
      ClearGadgetItems(Listbox_users)
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
        AddGadgetItem(Listbox_users,i,Str(Clients()\AID)+":"+mstr$+": "+Clients()\username+":"+Clients()\IP+":"+GetCharacterName(Clients())+":"+GetAreaName(Clients()))
        SetGadgetItemData(Listbox_users,i,Clients()\ClientID)
        i+1
      Wend
      UnlockMutex(ListMutex)
      If lstate<CountGadgetItems(Listbox_users)
        SetGadgetState(Listbox_users,lstate)
      EndIf
      UnlockMutex(RefreshMutex)
    EndIf
  EndProcedure
  
  
  Procedure Splash(ponly)
    OpenForm3()
    AddKeyboardShortcut(Form3, #PB_Shortcut_Return, 1)
    If ReceiveHTTPFile("https://raw.githubusercontent.com/stonedDiscord/serverV/master/serverv.txt","serverv.txt")
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
      StatusBarText(0,1,"Server Status: ONLINE")
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
            If areas(Clients()\area)\lock=ClientID
              areas(Clients()\area)\lock=0
              areas(Clients()\area)\mlock=0
              areas(Clients()\area)\players-1
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
            Clients()\area=1
            Areas(1)\players+1
            Clients()\ignore=0
            Clients()\ooct=0
            Clients()\type=0
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
              
              SendNetworkString(ClientID,"PC#"+Str(players)+"#"+Str(characternumber)+"#"+Str(characternumber)+"#"+Str(tracks)+"#"+Str(Aareas)+"#"+Str(itemamount)+"#%")
              
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
            If length=-1
              LockMutex(ListMutex)
              If FindMapElement(Clients(),Str(ClientID))
                WriteLog("[DISCONNEC.] "+Clients()\username+":"+Clients()\IP,Clients())
                If areas(Clients()\area)\lock=ClientID
                  areas(Clients()\area)\lock=0
                  areas(Clients()\area)\mlock=0
                EndIf
                DeleteMapElement(Clients(),Str(ClientID))
                UnlockMutex(ListMutex)
                rf=1
              EndIf
            ElseIf length
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
              KickBan(Str(cldata),#KICK,3)
              
            Case Button_mute
              KickBan(Str(cldata),#MUTE,3)
              
            Case Button_unmute
              KickBan(Str(cldata),#UNMUTE,3)
              
            Case Button_ipban
              KickBan(Str(cldata),#BAN,3)
              
            Case Button_uban  
              KickBan(Str(cldata),#IDBAN,3)
              
            Case Button_disconnect
              KickBan(Str(cldata),#DISCO,3)     
              
            Case Button_ignore
              *clickedClient\ignore.b=1
              
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
            If nthread=0
              nthread=CreateThread(@Network(),0)                 
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
            MessageRequester("serverV","This is serverV version "+Str(#PB_Editor_CompileCount)+"."+Str(#PB_Editor_BuildCount)+Chr(10)+"(c) stonedDiscord 2014-2015")
            
        EndSelect
      ElseIf Event = #PB_Event_Menu
        adch$=GetGadgetText(edit_ooc)
        If adch$<>""
          Server\last = "CT#$ADMIN#"+adch$+"#%"
          CheckInternetCode(Server)
        EndIf

      EndIf
      
    Until Event = #PB_Event_CloseWindow ; End of the event loop
    Quit=1
    
    End
    
  CompilerEndIf
; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 837
; FirstLine = 828
; Folding = --
; EnableXP