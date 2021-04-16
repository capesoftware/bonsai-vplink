# Tools for Bonsai/VPLink integration

The tools in this directory can be used by existing VP Link users to create VP Link loadables from their simulations.

These tools are not necessary to run the [samples](../samples/README.md), as each sample already has a VP Link loadable file.

Further documentation can be found in the associated .html file or with the --help option.

To use the tools, download this directory, then put the .exe and .html files in your %ProgramFiles%\CapeSoftware\VPLink3 folder. That's the 64-bit location.

## CreateBonsaiInterface

Creates the 'vplink_interface.json' file neede by Bonsai which is embedded in a VP Link loadable file.
While this does not need VP Link to be running, it does work much better if it can talk to a running VP Link database.

## CreateBonsaiLoadable

Creates the VP Link loadable file from the source directory.

## VPLinkSim_Bonsai3.exe

Connects VP Link servers to Bonsai as unmanaged simulators.  Only works if you have VP Link installed locally.\
See the associated help file for more information.

