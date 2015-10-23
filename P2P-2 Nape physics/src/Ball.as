package 
{
	import com.senocular.utils.KeyObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import flash.display.MovieClip;

	/**
	 * ...
	 * @author Aleksandar Bosnjak
	 */
	public class Ball extends Sprite
	{
		
		private var radius:uint;
		private var color:uint;
		
		public var id:String;
		public var uname:String;
		
		private var tf:TextField = new TextField();
		private var key:KeyObject;
		private var speed:int = 5;
		
				
		public function Ball(x:int, y:int, radius:uint, color:uint, id:String, uname:String) {
			
			this.x = x;
			this.y = y;
			this.radius = radius;
			this.id = id;
			this.color = color;
			this.uname = uname;
			this.tf.text = uname + "";
			//this.key = new KeyObject(stageRef);
			
			//addEventListener(Event.ENTER_FRAME, loop, false, 0, true);
			
			initGraphics();
		}
		
		private function initGraphics():void 
		{
			var ballShape:Shape = new Shape();
			
			ballShape.graphics.beginFill(color, 1);
			ballShape.graphics.drawCircle(0, 0, radius);
			ballShape.graphics.endFill();
			
			this.tf.textColor = 151515;
			this.tf.wordWrap = true;
			
			addChild(ballShape);
			//addChild(tf);
		}
		
		
	}

}