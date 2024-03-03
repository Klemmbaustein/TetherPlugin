# Tether Installer Northstar Plugin/mod

Based on [Uniboi's Northstar plugin template](https://github.com/uniboi/NSPluginTemplate).
Very WIP.

Integrates [the Tether mod manager](https://github.com/Klemmbaustein/TetherInstaller)
for [Northstar](https://northstar.tf/) into the game, using a squirrel mod and
a plugin written in C.

How to build:

1. Run `Setup.ps1` in RepoDir/TetherInstaller/
2. Adjust configuration settings in [the Directory.Build.props file](./Directory.Build.props) if necessary.
3. Build the solution file.

In the Build/ Directory, a built package will be generated.