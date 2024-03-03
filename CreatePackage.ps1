$PSStyle.OutputRendering = [System.Management.Automation.OutputRendering]::PlainText;

$package_name = "Klemmbaustein-Tether-0.0.1"

mkdir Build/$package_name/mods/Klemmbaustein.Tether/ -fo

cp TetherInstaller/NorthstarInstaller/Data Build/$package_name/plugins/bin -r -fo

cp -r -fo GameScripts/* Build/$package_name/mods/Klemmbaustein.Tether/

if ($args[1] -ne "")
{
	cp -r -fo Build/$package_name $args[0]\$args[1]\packages\
}