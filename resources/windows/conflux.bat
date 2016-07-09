:: This file is copied to C:\Program Files\conflux\bin upon successful installation of the toolbelt.
:: Calling' 'conflux <ARGS>' from your command prompt actually just calls this file (assuming your PATH
:: has been modified to include C:\Program Files\conflux\bin), which in turn invokes the 'ruby' command 
:: and passes your 'conflux <ARGS>' statment into it as arguments.
@echo off
ruby "%~dpn0" %*