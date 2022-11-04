extends RigidBody2D

func hit(player, force):
	var rel_force = 64 + (force.length() * 12)
	self.apply_impulse(force.normalized() * rel_force, Vector2.ZERO)
