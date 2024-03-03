$PSStyle.OutputRendering = [System.Management.Automation.OutputRendering]::PlainText;

$package_name = "Klemmbaustein-Tether-0.0.1"

mkdir Build/$package_name/mods/Klemmbaustein.Tether/ -fo
cp -r -fo GameScripts/* Build/$package_name/mods/Klemmbaustein.Tether/

cp -r -fo Build/$package_name D:\EA\Titanfall2\R2Northstar\packages\