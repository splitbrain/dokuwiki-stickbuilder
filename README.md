Portable Apache Builder for DokuWiki on a Stick
===============================================

This is a build script to extract the needed files for a minimal Apache server
with PHP for the use with DokuWiki. It's meant to be run on Linux but builds
a 64 bit Windows version of the server.

End users are not supposed to run this. Instead chose the "DokuWiki on a Stick"
option at http://download.dokuwiki.org - this is merely a reminder in script
form for the maintainers.

The script creates the server part only. It needs to be completed by placing
a "dokuwiki" folder in the root dir.

Note: you can get a Win11 VM directly from Microsoft for testing:

    wget https://aka.ms/windev_VM_virtualbox
