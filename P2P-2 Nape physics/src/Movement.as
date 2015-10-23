package 
{
	import com.senocular.utils.KeyObject;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import nape.geom.Vec2;
	import nape.phys.Body;
	/**
	 * ...
	 * @author Aleksandar Bosnjak
	 */
	public class Movement 
	{
		private static var multiPlayer:Multiplayer;
		private static var key:KeyObject;
		private static var localID:String;
		private static var stageRef:Stage;
		
		private static var speed:Number = 0.25;
		private static var vx:Number = 0;
		private static var vy:Number = 0;
		private static var friction:Number = 0.83;
		
		// NAPE physics
		private static const acceleration:Number = 100;
		private static const delta:Number = 1 / 20;
		public static const maxSpeed:Number = 150;
		
		private static var moved:Boolean = false;
		
		public function Movement() 
		{
		}
		
		public static function init(ball:Body, multiplayer:Multiplayer, localId:String, stage:Stage):void {
			multiPlayer = multiplayer;
			localID = localId;
			stageRef = stage;
			key = new KeyObject(stageRef);
			
			stageRef.addEventListener(Event.ENTER_FRAME, renderMovement);
		}
		
		public static function renderMovement(e:Event):void {		// local peer movement implementation...
			var impulse:Vec2 = new Vec2();
			
			moved = false;
			
			if (key.isDown(key.LEFT)) {
				impulse.x = -acceleration * delta;
				moved = true;
			}
			else if (key.isDown(key.RIGHT)) {
				impulse.x = +acceleration * delta;
				moved = true;
			}
				
			if (key.isDown(key.UP)) {
				impulse.y = -acceleration * delta;
				moved = true;
			}
			else if (key.isDown(key.DOWN)) {
				impulse.y = acceleration * delta;
				moved = true;
			}
				
			multiPlayer.balls[localID].applyImpulse(impulse);
			
			if(multiPlayer.balls[localID].velocity.length > maxSpeed) {
				multiPlayer.balls[localID].velocity.length = maxSpeed;
			}
			
			multiPlayer.sendPosition(multiPlayer.balls[localID], impulse);						// inform other peers about ur movement..
		}

	}

}