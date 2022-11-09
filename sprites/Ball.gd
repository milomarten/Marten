extends RigidBody2D

func hit(player: Player):
	var force = self.position - player.get_ow_position()
	var rel_force = 64 + (force.length() * 12)
	self.apply_impulse(force.normalized() * rel_force, Vector2.ZERO)
