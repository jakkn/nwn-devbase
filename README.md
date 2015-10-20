# nwn-devbase
This repository is meant to function as a base setup for anyone who wants to version control their module development for the game Neverwinter Nights.

### Background
Neverwinter Nights is an RPG developed by BioWare and released in 2001. BioWare designed NWN as a game where players may create their own game worlds, and share their work with the community. Module development is done through the use of the Aurora Toolset that BioWare released with NWN. BioWare also released server software for launching and hosting modules online so that players may connect to and play the modules created and hosted by module developers.

NWN was discontinued 7 years after release, and the final patch is version 1.69, released 9 July 2008. Even though the game was discontinued by the developer, the community is still big, and due to the game's easily hackable design new game content is continually released.

### What's the point of this repository
Aurora stores all module content in file archives with the .mod extension. git does not handle .mod archives well, and so for git to be of any use the .mod archive must first be unpacked. The process of unpacking and repacking module content may be cumbersome to some, and so I've created this repository in an attempt to share the work I've done with anyone who may find it useful, and to reuse for my own use should I ever need it. As such, the basis for this work and some of the documentation is the work I've already done on an existing server - Bastion of Peace.

### How to use this repository
1. Fork this repository
2. Place your .mod archive in the appropriate directory
3. Run the unpack script

That's it. Of course, if you're not familiar with version control I strongly suggest you read up on git and familiarize yourself with what it is, how to use it, and best practices.

### Feedback
Feedback is greatly appreciated. If you have any thoughts, suggestions or ideas about how to improve the content of this project, please feel free to contact me, or even better create a pull request.
