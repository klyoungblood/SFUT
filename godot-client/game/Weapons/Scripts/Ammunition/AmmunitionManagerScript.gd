extends Node3D

var ammoDict : Dictionary = { #key = ammo type, value = ammo start number
	"LightAmmo" : 200,
	"MediumAmmo" : 60,
	"HeavyAmmo" : 50,
	"ShellAmmo" : 128,
	"RocketAmmo" : 3,
	"GrenadeAmmo" : 12
}

var maxNbPerAmmoDict : Dictionary = { #key = ammo type, value = ammo max number
	"LightAmmo" : 50,
	"MediumAmmo" : 360,
	"HeavyAmmo" : 10,
	"ShellAmmo" : 640,
	"RocketAmmo" : 15,
	"GrenadeAmmo" : 60
}
