package uk.co.homletmoo.ld30.entity 
{
	import flash.geom.Point;
	import net.flashpunk.Entity;
	import net.flashpunk.FP;
	import net.flashpunk.graphics.Emitter;
	import net.flashpunk.graphics.Image;
	import net.flashpunk.utils.Ease;
	import net.flashpunk.utils.Input;
	import uk.co.homletmoo.ld30.assets.Sounds;
	import uk.co.homletmoo.ld30.Controls;
	import uk.co.homletmoo.ld30.assets.Images;
	import uk.co.homletmoo.ld30.Main;
	import uk.co.homletmoo.ld30.Utils;
	
	/**
	 * A marble that accelerates with the arrow keys.
	 * 
	 * @author Homletmoo
	 */
	public class Marble extends Entity
	{
		// This stuff was worked out on paper, so trust me - it works.
		public static const G:Number = 980; // Pixels per second per second.
		public static const MU:Number = 0.08;
		public static const RESTITUTION:Number = 0.4;
		public static const SLOPE:Number = (1 - MU * Math.sqrt(3)) / 2;
		
		private var emitter:Emitter;
		private var image:Image;
		
		private var start_pos:Point;
		private var velocity:Point;
		
		public function Marble(x:int, y:int) 
		{
			super(x + 4, y + 4);
			setHitbox(24, 24, -4, -4);
			type = "marble";
			
			emitter = new Emitter(Images.scale(Images.MARBLE_PARTS, Main.SCALE), 32, 32);
			emitter.relative = false;
			emitter.newType("death", [0, 1, 2, 3, 4]);
			emitter.setMotion("death", 0, 0, 0.45);
			emitter.newType("spawn", [5, 6, 7, 8]);
			emitter.setMotion("spawn", 0, 20, 0.5, 360, 50, 0.5, Ease.cubeOut);
			addGraphic(emitter);
			emit("spawn", 8);
			
			image = new Image(Images.MARBLE);
			image.scale = Main.SCALE;
			addGraphic(image);
			
			start_pos = new Point(x + 4, y + 4);
			velocity = new Point();
		}
		
		public function reset(hole:Hole=null):void
		{
			if (hole != null)
			{
				x = hole.x + 4;
				y = hole.y + 4;
				emit("death", 1);
			}
			x = start_pos.x;
			y = start_pos.y;
			emit("spawn", 8);
			velocity = new Point();
		}
		
		public function emit(type:String, amount:uint):void
		{
			for (var i:int = 0; i < amount; i++)
			{
				emitter.emit(type, x, y);
			}
		}
		
		override public function update():void
		{
			var up:Boolean = Input.check(Controls.UP);
			var left:Boolean = Input.check(Controls.LEFT);
			var down:Boolean = Input.check(Controls.DOWN);
			var right:Boolean = Input.check(Controls.RIGHT);
			
			if (up)   { velocity.y -= G * SLOPE * FP.elapsed; }
			if (down) { velocity.y += G * SLOPE * FP.elapsed; }
			if (left)  { velocity.x -= G * SLOPE * FP.elapsed; }
			if (right) { velocity.x += G * SLOPE * FP.elapsed; }
			
			var friction:Number = G * MU * FP.elapsed;
			if (!Utils.xor(up, down))
			{
				if (Math.abs(velocity.y) > friction > 0)
				{
					velocity.y -= friction * (velocity.y / Math.abs(velocity.y));
				} else
				{
					velocity.y = 0;
				}
			}
			if (!Utils.xor(left, right))
			{
				if (Math.abs(velocity.x) > friction > 0)
				{
					velocity.x -= friction * (velocity.x / Math.abs(velocity.x));
				} else
				{
					velocity.x = 0;
				}
			}
			
			var dx:int = int(right) - int(left);
			var dy:int = int(down) - int(up);
			if (Utils.xor(left, right) || Utils.xor(up, down))
			{
				Main.instance.tilt(3, Math.atan2(dx, dy) / Math.PI * 180);
			} else
			{
				Main.instance.tilt(0);
			}
			
			moveBy(velocity.x * FP.elapsed, velocity.y * FP.elapsed, ["wall", "marble"]);
		}
		
		override public function moveCollideX(other:Entity):Boolean 
		{
			if (Math.abs(velocity.x) > 30)
			{
				velocity.x *= -RESTITUTION;
			} else
			{
				velocity.x = 0;
			}
			
			hit_sound(velocity.x);
			
			return true;
		}
		
		override public function moveCollideY(other:Entity):Boolean 
		{
			if (Math.abs(velocity.y) > 30)
			{
				velocity.y *= -RESTITUTION;
			} else
			{
				velocity.y = 0;
			}
			
			hit_sound(velocity.y);
			
			return true;
		}
		
		private function hit_sound(vel:Number):void
		{
			vel = Math.abs(vel);
			if (vel > 35)
			{
				Sounds.play_next(Sounds.HITS, vel / 130, Utils.pan(x, Main.WIDTH));
			}
		}
		
		public function get_speed():Number
		{
			return velocity.length;
		}
	}
}
