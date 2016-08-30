# serverV
A homebrew server for Visual Novel Online

I created it by reverse engineering the server and client binaries, that means this server is "cleanroom-designed" and perfectly legal in the EU.

Using this server on the official Master/Account Server will most likely get you banned though, so don't use your main account for this.

Support Requests � la "i got banned" and "help fiercy is mad" will be ignored.

#VNO: How to host

1. Read the [Server Guidelines and Rules](https://docs.google.com/document/d/1iW6dY6ak_mHxjrJuD1MwS12C3fmfi4vGxzTNOcJqrBw/edit) (protip: you are breaking them)

2. Open your desired port from your router. [Guide](http://portforward.com/english/routers/port_forwarding/)

3. Launch VNO_SERVER.exe.
  * At this point, the log at the right tells you if your version is up to date, ~~only go on if it is.~~

4. Connect into your VNO account.
  * You must first create an account via the client.

5. ~~Enter your port in the box next to host.~~ (removed in version 1.004)
It�s preseted from the port in settings.ini

#AS notes
Starting from version 1.004 the Account Server IP is hardcoded in the vanilla servers and clients.
serverV will read it from AS.ini like the old versions did.
You can change the vanilla server and clients AS IP using [Ressource Hacker](http://www.angusj.com/resourcehacker/), it is at the end of the TForm3 RCDATA section.
serverV can act as a temporary AS, it lets anyone log in with any username/password connection and shows itself in the server list.