# DeviceManager

The Device Manager is a voting system component that is part of the ElectOS election technology framework. The Device Manager (DM) manages the configuration of the ElectOS components that perform functions of ballot casting and counting.  There are currently three components:
- Central Ballot Counter (CBC)
- Precinct Ballot Counter (PBC)
- Tabulator (Tab).

The DeviceManager manages the configuration and creation of the 3 tools above.  It requires an Election Data File during the configuration, then acquires configuration for the selected tool (e.g. CBC), tars and compresses the EDF and config file onto the pre-prepared ISO and writes the combined ISO+Data to a new bootable DVD.  When the DVD boots, it boots directly into the given tool, which reclaims* the configuration and EDF and performs its job.

The DeviceManager resides at /opt/OSET/bin/deviceMgr.sh.  This is the entry point to the various configuration tools.  Those configuration tools are not meant to be run individually.


*** Tested, but unimplemented - see /opt/OSET/bin/recoverPiggyBackData.sh for details.**


## Getting Started

These instructions will get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

This software is based on Fedora Workstation v26.  That version can be found [here.](https://download.fedoraproject.org/pub/fedora/linux/releases/26/Workstation/x86_64/iso/Fedora-Workstation-Live-x86_64-26-1.5.iso "here")

After installing Fedora 26, you'll need this project.  Git clone it to your local workstation and you will have the following layout:

/opt/OSET

&nbsp;&nbsp;&nbsp;&nbsp;bin

&nbsp;&nbsp;&nbsp;&nbsp;ISO

&nbsp;&nbsp;&nbsp;&nbsp;LiveISO

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;rpmRepo

The bin directory contains most of the scripts and executables.  The ISO directory (**should** - see footnote) contains prebuilt ISOs for the DM, the PBC, CBC, and Tabulator.  The LiveISO directory contains scripts to build the aforementioned ISOs, as well as create the repository of required RPMs that support the creation of bootable ISOs.


Also required (install with the given dnf commands):

- Lorax

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;dnf install lorax

- Anaconda

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;dnf install anaconda

- xml lint

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;dnf install libxml2

- dialog

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;dnf install dialog

Your Fedora v26 distribution probably already has these, but just in case isosize and sha512sum don't work, install these, too:

- sha512sum

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;dnf install coreutils

- isosize

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;dnf install util-linux

These last two are only used when reclaiming the EDF and tool configuration json files as piggyback data, which is really unimplemented at this point, but just in case you're curious and want to play with it.


I think that's all... Please let me know if I missed any!

## Building ISOs

If you'd like to rebuild the ISOs, ensure you've installed the prerequisites, then go to the /opt/OSET/LiveISO directory and run makeLiveISO.sh with the tool abbreviation name as a command line input:  If you need to know the abbreviation, just run the command without a command line arg and you'll get usage info:
./makeLiveISO.sh
    Usage: makeLiveISO.sh [dm|tab|cbc|pbc]

So, for example, running the command ./makeLiveISO.sh pbc, you'll recreate the PBC ISO using the PBC kickstart configuration, lorax, anaconda, etc.  The kickstart will use the rpmRepo as the repository; you can build the ISO without being connected to a network, which is intended to create more secure, reproducible builds since the inputs are git controlled and you're not picking up stray rpms.

When the build completes, look at the end of the output and it will tell you where the final ISO was placed (it's a randomly named directory).  Copy that ISO to /opt/OSET/ISO and you're done.

## Running the DeviceManager
You can run the DM directly, without recreating the ISO by running the deviceMgr.sh script in the bin directory:
    cd /opt/OSET/bin
    ./deviceMgr.sh

The UI will require an Election Data File.  There are examples of good and bad EDFs in the /opt/OSET/bin directory.  Navigate there to select either one.  The XML EDF is validated against the XSD (in /opt/OSET/bin) using XML Lint.


## Burn your DVD
You can burn your ISO to DVD many ways.  I found wodim to be useful and quick.  Try this:
    sudo wodim -v speed=2 dev=/dev/sr0 -dao <path to your ISO>
You man need to install wodim:
&nbsp;&nbsp;dnf install cdrkit
## Testing the ISO in a VM
You could burn the ISO immediately to disc and boot from it, but that takes a few minutes and may waste a DVD.  The majority of testing was done using Qemu as a VM.
You can install qemu with this command:
&nbsp;&nbsp;&nbsp;&nbsp;dnf install qemu

Create an image file (this is a one-time requirement):

    dd if=/dev/zero of=image.raw bs=1M count=5000
This will create a 5GB image file you can use in the next step.


Once installed, use this command to start a VM with your ISO:

    qemu-system-x86_64 -drive file=<path to your image file>,format=raw -boot d -cdrom <path to your ISO file> -m 2048

This should pop up a VM window and let you select an Image to boot - select the topmost choice and continue.  Once fully booted and you arrive at the command prompt, log in with a username and password of "osetuser" (without quotes).  You should immediately see the tool's UI; if you're testing the DM ISO, you'll be in the DM's UI.

## Author(s)

- **Bret Schuhmacher** - initial work - [https://github.com/oset-bschuhma](https://github.com/oset-bschuhma)

Please feel free to provide feedback on any items required and missing in this "how-to".  I *really* hate a README that isn't complete or leaves questions unanswered!!

See also the list of [contributors](https://github.com/orgs/TrustTheVote-Project/people) who participated in this project.


## For more information
- [Lorax site](https://rhinstaller.github.io/lorax/lorax.html "Lorax site")
- [Anaconda Wiki](https://fedoraproject.org/wiki/Anaconda "Anaconda Wiki")
- [QEMU](https://www.qemu.org/ "QEMU")
- [Dialog](http://invisible-island.net/dialog/dialog.html "Dialog")


Footnote
------------

**** NOTE regarding prebuilt ISO images
**	I am currently tyring to check in the prebuilt ISO images.  As ISOs, they are quite large - too large for git to handle natively.  They require git lfs (large file storage), which, by default requires payment to GitHub.  It was decided to put the files in S3, but git lfs and S3 support is not well supported; the 2 git lfs s3 implementations I found are years old, the git lfs spec has changed, and neither app has been maintained.  The authors of the apps are not responding to email requests, either.  I wanted to get the basic stuff I could get into git out there and then continue work on git lfs s3 support in the background.  I didn't want putting the ISOs under source code control to block other development for those working on SELinux issues or other items.  You will have to build your own ISOs until I get the ISOs checked into S3.  Sorry. :-(
