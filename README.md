# serverV
A homebrew server for Visual Novel Online

Quote from the VNO Server Guidelines and Rules:

> Server Rules
> Note: Server rules go into 3 categories:
> Hard rules: Breaking these results in an **instant, undiscutable and unnegotiable removal of your host priviledges**, and depending on the reason, you might also get insta account-banned or VNO-wide IP ban.
>
> Mid rules: Same as hard rules, except those are **negotiable** to get your host privileges back.
>
> Soft rules: Those will get you **warnings**, unlisting and if persisting, removal of your host priviledges (negotiable).
>
> Negotiations happen on skype -> venecity.kalissto
>
> See rules in the page bellow!
> And please read the special note regarding content.
> HARD RULES
> 1. Servers which contains ANY nsfw material OR prejorative material in their provided link, content, name or description will instantly get action taken.
>   * Shock, screamer, pornography, insult, harassment etc.
> 2. **Use of any modded server is strictly forbidden, if you want new features for hosting, talk to me instead.**

Seeing these rules as "End User License Agreement" (the stuff you never read when installing anything), makes my server ... illegal i guess.

There is enough reasons to do it anyway, Fiercy is not easy to talk to and this server is open source and written in a programming language that has a lot of advantages over Delphi, one being multiplatform and small binary sizes.

I created it by reverse engineering the server and client binaries, that means this server is "cleanroom-designed" and perfectly legal in the EU.

Using this server on the official Master/Account Server will most likely get you banned though, so don't use your main account for this.

Support Requests à la "i got banned" and "help fiercy is mad" will be ignored.

#VNO: How to host

1. Read the [Server Guidelines and Rules](https://docs.google.com/document/d/1iW6dY6ak_mHxjrJuD1MwS12C3fmfi4vGxzTNOcJqrBw/edit) (protip: you are breaking them)

2. Open your desired port from your router. [Guide](http://portforward.com/english/routers/port_forwarding/)

3. Launch VNO_SERVER.exe.
  * At this point, the log at the right tells you if your version is up to date, ~~only go on if it is.~~

4. Connect into your VNO account.
  * You must first create an account via the client.

5. ~~Enter your port in the box next to host.~~ (removed in version 1.004)
It’s preseted from the port in settings.ini

#AS notes
Starting from version 1.004 the Account Server IP is hardcoded in the vanilla servers and clients.
serverV will read it from AS.ini like the old versions did.
You can change the vanilla server and clients AS IP using [Ressource Hacker](http://www.angusj.com/resourcehacker/), it is at the end of the TForm3 RCDATA section.
serverV can act as a temporary AS, it lets anyone log in with any username/password connection and shows itself in the server list.