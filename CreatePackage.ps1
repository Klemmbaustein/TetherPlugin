$PSStyle.OutputRendering = [System.Management.Automation.OutputRendering]::PlainText;

$package_name = "Klemmbaustein-Tether-0.0.1"

mkdir Build/$package_name/mods/Klemmbaustein.Tether/ -fo

cp TetherInstaller/NorthstarInstaller/Data Build/$package_name/plugins/bin/ -r -fo
cp TetherInstaller/KlemmUI/lib/Release/SDL2.dll Build/$package_name/plugins/bin/

cp -r -fo GameScripts/* Build/$package_name/mods/Klemmbaustein.Tether/

$profile_name = $args[1]
$game_dir = $args[0]

if ($profile_name -ne "")
{
	echo "Installing to $game_dir\$profile_name"
	cp -r -fo Build/$package_name $game_dir\$profile_name\packages\
}