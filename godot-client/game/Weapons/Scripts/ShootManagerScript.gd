extends Node3D

var cW #current weapon
var pointOfCollision : Vector3 = Vector3.ZERO

var leftLast := false

@onready var weapM : WeaponManager = %WeaponManager #weapon manager

func getCurrentWeapon(currWeap):
	#get current weapon resources
	cW = currWeap
	
func shoot(altfire=false):
	if cW.canShoot and weapM.ammoManager.ammoDict[cW.ammoType] > 0:
		cW.canShoot = false
		var nshots = cW.nbProjShots
		
		#number of successive shots (for example if 3, the weapon will shot 3 times in a row)
		for i in range(nshots):
			#same conditions has before, are checked before every shot
			if weapM.ammoManager.ammoDict[cW.ammoType] > 0:
				weapM.weaponSoundManagement(cW.shootSound, cW.shootSoundSpeed)
							
				#number projectiles shots at the same time (for example, 
				#a shotgun shell is constituted of ~ 20 pellets that are spread across the target, 
				#so 20 projectiles shots at the same time)
				weapM.ammoManager.ammoDict[cW.ammoType] -= 1
				
				var nbullets = cW.nbProjShotsAtSameTime
				
				# altfire on the machine guns, both barrels at once, double ammo usage
				if altfire and cW.altmode==cW.altModes.BOTHBARRELS:
					weapM.ammoManager.ammoDict[cW.ammoType] -= 1
					nbullets *=2
				
				for j in range(0, nbullets):
					if cW.allAmmoInMag: weapM.ammoManager.ammoDict[cW.ammoType] -= 1
					else: cW.totalAmmoInMag -= 1
						
					#get the collision point
					pointOfCollision = getCameraPOV()
	
					#call the fonction corresponding to the selected type
					if cW.type == cW.types.HITSCAN: hitscanShot(pointOfCollision)
					elif cW.type == cW.types.PROJECTILE: projectileShot(pointOfCollision)
					
				weapM.displayMuzzleFlash()

				await get_tree().create_timer(cW.timeBetweenShots).timeout
				
			else:
				print("Not enought ammunitions to shoot")
				
		cW.canShoot = true

func getCameraPOV():  
	var gunport
	if cW.port == cW.ports.CENTER:
		gunport = %Gunports/Center
	elif cW.port == cW.ports.SIDE and leftLast:
		gunport = %Gunports/Right
		leftLast = false
	elif cW.port == cW.ports.SIDE:
		gunport = %Gunports/Left
		leftLast = true
	
	var _window : Window = get_window()
	var viewport : Vector2i

	viewport = get_viewport().get_visible_rect().size
			
	#Start raycast in camera position, and launch it in camera direction 
	var raycastStart = gunport.project_ray_origin(viewport/2)
	var raycastEnd
	if cW.type == cW.types.HITSCAN: raycastEnd = raycastStart + gunport.project_ray_normal(viewport/2) * cW.maxRange 
	if cW.type == cW.types.PROJECTILE: raycastEnd = raycastStart + gunport.project_ray_normal(viewport/2) * 280
	
	#Create intersection space to contain possible collisions 
	var newIntersection = PhysicsRayQueryParameters3D.create(raycastStart, raycastEnd)
	var intersection = get_world_3d().direct_space_state.intersect_ray(newIntersection)
	
	#If the raycast has collide with something, return collision point transform properties
	if !intersection.is_empty():
		var collisionPoint = intersection.position
		return collisionPoint 
	#Else, return the end of the raycast (so nothing, because he hasn't collide with anything) 
	else:
		return raycastEnd 
		
func hitscanShot(pointOfCollisionHitscan : Vector3):
	#set up weapon shot sprad 
	var spread = Vector3(weapM.rng.randf_range(cW.minSpread, cW.maxSpread), weapM.rng.randf_range(cW.minSpread, cW.maxSpread), weapM.rng.randf_range(cW.minSpread, cW.maxSpread))
	
	#calculate direction of the hitscan bullet 
	var hitscanBulletDirection = (pointOfCollisionHitscan - cW.weSl.attackPoint.get_global_transform().origin).normalized()
	
	#create new intersection space to contain possibe collisions 
	var newIntersection = PhysicsRayQueryParameters3D.create(cW.weSl.attackPoint.get_global_transform().origin, pointOfCollisionHitscan + spread + hitscanBulletDirection * 2)
	newIntersection.set_exclude([weapM.playChar.get_rid()])
	newIntersection.collide_with_areas = true
	newIntersection.collide_with_bodies = true 
	var hitscanBulletCollision = get_world_3d().direct_space_state.intersect_ray(newIntersection)

	#if the raycast has collide
	if hitscanBulletCollision: 
		var collider = hitscanBulletCollision.collider
		var colliderPoint = hitscanBulletCollision.position
		var colliderNormal = hitscanBulletCollision.normal 
		var finalDamage : int
	
		# NOTE: Added
		var source = get_multiplayer_authority()
		#print('DEBUG COLLIDER: ', collider)
		if collider.is_in_group("Enemies") and collider.has_method("hitscanHit"):
			finalDamage = cW.damagePerProj * cW.damageDropoff.sample(pointOfCollisionHitscan.distance_to(global_position) / cW.maxRange)
			collider.hitscanHit(finalDamage, hitscanBulletDirection, hitscanBulletCollision.position, source)
			weapM.playChar.signal_hit_success.emit()
		elif collider.is_in_group("EnemiesHead") and collider.has_method("hitscanHit"):
			finalDamage = cW.damagePerProj * cW.headshotDamageMult * cW.damageDropoff.sample(pointOfCollisionHitscan.distance_to(global_position) / cW.maxRange)
			collider.hitscanHit(finalDamage, hitscanBulletDirection, hitscanBulletCollision.position, source)
			weapM.playChar.signal_hit_success.emit(true)
		elif collider.is_in_group("HitableObjects") and collider.has_method("hitscanHit"): 
			finalDamage = cW.damagePerProj * cW.damageDropoff.sample(pointOfCollisionHitscan.distance_to(global_position) / cW.maxRange)
			collider.hitscanHit(finalDamage/6.0, hitscanBulletDirection, hitscanBulletCollision.position, source)
			weapM.playChar.signal_hit_success.emit()
		else:
			weapM.displayBulletHole(colliderPoint, colliderNormal)

# NOTE: Unchanged legacy version			
#func projectileShot(pointOfCollisionProjectile : Vector3):
	##set up weapon shot sprad 
	#var spread = Vector3(weapM.rng.randf_range(cW.minSpread, cW.maxSpread), weapM.rng.randf_range(cW.minSpread, cW.maxSpread), weapM.rng.randf_range(cW.minSpread, cW.maxSpread))
	#
	##Calculate direction of the projectile
	#var projectileDirection = ((pointOfCollisionProjectile - cW.weSl.attackPoint.get_global_transform().origin).normalized() + spread)
	#
	##Instantiate projectile
	#var projInstance = cW.projRef.instantiate()
	#
	##set projectile properties 
	#projInstance.global_transform = cW.weSl.attackPoint.global_transform
	#projInstance.direction = projectileDirection
	#projInstance.damage = cW.damagePerProj
	#projInstance.timeBeforeVanish = cW.projTimeBeforeVanish
	#projInstance.gravity_scale = cW.projGravityVal
	#projInstance.isExplosive = cW.isProjExplosive
	#
	#get_tree().get_root().add_child(projInstance)
	#
	#projInstance.set_linear_velocity(projectileDirection * cW.projMoveSpeed)

func projectileShot(pointOfCollisionProjectile : Vector3):
	#set up weapon shot sprad 
	var spread = Vector3(weapM.rng.randf_range(cW.minSpread, cW.maxSpread), weapM.rng.randf_range(cW.minSpread, cW.maxSpread), weapM.rng.randf_range(cW.minSpread, cW.maxSpread))
	var _source = get_multiplayer_authority()

	#Calculate direction of the projectile
	var projectileDirection = ((pointOfCollisionProjectile - cW.weSl.attackPoint.get_global_transform().origin).normalized() + spread)
	
	#Instantiate projectile (LEGACY)
	#var projInstance = cW.projRef.instantiate()

	#projInstance.global_transform = cW.weSl.attackPoint.global_transform
	#projInstance.damage = cW.damagePerProj
	#projInstance.timeBeforeVanish = cW.projTimeBeforeVanish
	#projInstance.gravity_scale = cW.projGravityVal
	#projInstance.isExplosive = cW.isProjExplosive
	# Movespeed
	
	#NOTE: Borrowd normal to carry over decal
	var _normal = Vector3.ONE
	var newIntersection = PhysicsRayQueryParameters3D.create(cW.weSl.attackPoint.get_global_transform().origin, pointOfCollisionProjectile + spread + projectileDirection * 2)
	newIntersection.collide_with_areas = true
	newIntersection.collide_with_bodies = true 
	var hitscanBulletCollision = get_world_3d().direct_space_state.intersect_ray(newIntersection)
	if hitscanBulletCollision.has('normal'):
		_normal = hitscanBulletCollision.normal

	# TODO: Projectiles coming soon. 
	
	# NOTE: Networked version - AD
	var _projInstanceName = cW.projRef.get_state().get_node_name(0)
	var _cWArray = [cW.weSl.attackPoint.global_transform,  cW.damagePerProj, cW.projTimeBeforeVanish, cW.projGravityVal, cW.isProjExplosive, cW.projMoveSpeed]
	#Hub.projectile_system.add_new_projectile.rpc(cWArray, projectileDirection, projInstanceName, _normal, source)
