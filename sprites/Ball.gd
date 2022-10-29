extends RigidBody2D

func hit(player, force):
	var rel_force = 64 + (force.length() * 12)
	self.apply_impulse(Vector2.ZERO, force.normalized() * rel_force)
