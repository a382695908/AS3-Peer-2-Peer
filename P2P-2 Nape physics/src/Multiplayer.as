package
{
	import com.reyco1.multiuser.data.UserObject;
	import com.reyco1.multiuser.debug.Logger;
	import com.reyco1.multiuser.MultiUserSession;
	import com.senocular.utils.KeyObject;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.geom.Rectangle;
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.phys.Material;
	import nape.shape.Circle;
	import nape.shape.Polygon;
	import nape.space.Space;
	import nape.util.ShapeDebug;
	
	/**
	 * ...
	 * @author Aleksandar Bosnjak
	 */
	[SWF(frameRate="30", width="640", height="480")] 
	public class Multiplayer extends MovieClip
	{
		private const SERVER:String = "rtmfp://p2p.rtmfp.net/";
		private const DEVKEY:String = "2e4f1e49a504d482f21682ed-fddaff8318f2"; // TODO: add your Cirrus key here. You can get a key from here : http://labs.adobe.com/technologies/cirrus/
		private const SERV_KEY:String = SERVER + DEVKEY;
		
		private var muSession:MultiUserSession;
		public var balls:Object = { };
		private var key:KeyObject;
		
		private var localID:String;
		
		// NAPE Physics
		private const DEBUG:Boolean = true;
		private static var space:Space;
		private var floorPhysicsBody:Body;
		private var debug:ShapeDebug;
		
		private var txtField:TextField = new TextField();
		
		
		public function Multiplayer()
		{
			this.key = new KeyObject(stage);
			
			initilaze();
		}
		
		public function initilaze():void
		{
			
			initPhysicsBodies();
			
			muSession = new MultiUserSession(SERV_KEY, "multiuser/test");
			
			var username:String = "user " + muSession.userCount;
			
			muSession.onConnect = handleConnect;
			muSession.onUserAdded = handleUserAdded;
			muSession.onUserRemoved = handleUserRemoved;
			muSession.onObjectRecieve = handleObjectRecive;
			
			muSession.connect(username, {x:Math.random()*500+20, y:Math.random()*20+20, radius: Math.random()*5+15, color:Math.random() * 0xFFFFFF, uname: username});
			
			
			addChild(txtField);
			trace("initilazing.... local player..");
		}
		
		private function initPhysicsBodies():void {
			var w:uint = stage.stageWidth;
            var h:uint = stage.stageHeight;
			
			space = new Space(new Vec2(0, 0));		// nema grav
			
			if (DEBUG) {
				debug = new ShapeDebug(stage.stageWidth, stage.stageHeight);
				addChild(debug.display);
			}
			
			// init stage frame
			floorPhysicsBody = new Body(BodyType.STATIC);
			floorPhysicsBody.shapes.add(new Polygon(Polygon.rect(0, 0, w, -1)));
            floorPhysicsBody.shapes.add(new Polygon(Polygon.rect(0, h, w, 1)));
            floorPhysicsBody.shapes.add(new Polygon(Polygon.rect(0, 0, -1, h)));
            floorPhysicsBody.shapes.add(new Polygon(Polygon.rect(w, 0, 1, h)));		// frame physics body... not floor.. :)
			floorPhysicsBody.space = space;		// adding to space
			
			var s:Shape = new Shape();
			s.graphics.beginFill(0xbaff1e);
			s.graphics.drawCircle(0, 0, 22);
			s.graphics.endFill();
			
			// init stage ball
			var footBall:Body = new Body(BodyType.DYNAMIC);
			var soccerBall:SoccerBall = new SoccerBall();
			footBall.shapes.add(new Circle(22, null, new Material(1.75)));
			footBall.userData.graphic = s;
			footBall.position.x = 150;
			footBall.position.y = 150;
			footBall.space = space;
			
			// render physics..
			addEventListener(Event.ENTER_FRAME, renderPhysics);		// render physics
		}
				
		protected function handleUserRemoved(theUser:UserObject):void
		{
			space.bodies.remove(balls[theUser.id]);
			removeChild(balls[theUser.id].userData.graphic);
			delete balls[theUser.id];
		}
		
		
		protected function handleConnect(theUser:UserObject):void
		{			
			var ball:Ball = new Ball(theUser.details.x, theUser.details.y, theUser.details.radius, theUser.details.color, theUser.id, theUser.details.uname);
			var ballPhysicsBody:Body = new Body(BodyType.DYNAMIC, new Vec2(theUser.details.x, theUser.details.y));
			var material:Material = new Material(1.75);
			
			localID = theUser.id;
			
			ballPhysicsBody.shapes.add(new Circle(theUser.details.radius, null, material));
			ballPhysicsBody.userData.graphic = ball;
			ballPhysicsBody.space = space;
			
			balls[theUser.id] = ballPhysicsBody;
			
			addChild(ball);
			
			Movement.init(balls[theUser.id], this, theUser.id, stage);
			
			trace("[[[local connection handled...]]]");
		}
		
		protected function handleUserAdded(theUser:UserObject):void
		{
			var ball:Ball = new Ball(theUser.details.x, theUser.details.y, theUser.details.radius, theUser.details.color, theUser.id, "user "+muSession.userCount);
			var ballPhysicsBody:Body = new Body(BodyType.DYNAMIC, new Vec2(theUser.details.x, theUser.details.y));
			var material:Material = new Material(1.75);
			
			ballPhysicsBody.shapes.add(new Circle(theUser.details.radius, null, material));
			ballPhysicsBody.userData.graphic = ball;
			ballPhysicsBody.space = space;
			
			balls[theUser.id] = ballPhysicsBody;
			
			addChild(ball);
			
			//sendPosition(ballPhysicsBody);
			
			txtField.text = "users online: " + muSession.userCount;
			
			trace("[[[new user added handled...]]]");
		}
		
		
		public function update(ball:Ball):void
		{
			//sendPosition(ball);
		}
		
		public function sendPosition(ball:Body, impulse:Vec2):void 
		{
			muSession.sendObject( { op:"MOVE", impulse: impulse, x:ball.position.x, y:ball.position.y } );
		}
		
		protected function handleObjectRecive(theUserId :String, theData :Object):void
		{
			switch(theData.op) {
				case "MOVE":
					syncPosition(theUserId, theData);
					break;
			}
			
		}
		
		private function syncPosition(theUserId:String, theData:Object):void 
		{
			balls[theUserId].applyImpulse(toVec2(theData.impulse));
			
			if(balls[theUserId].velocity.length > Movement.maxSpeed) {	// security check on recieving data
				balls[theUserId].velocity.length = Movement.maxSpeed;
			}
			
		}
		
		
		private function renderPhysics(e:Event):void {
		if (DEBUG) debug.clear();
			
			space.step(1 / stage.frameRate);
			space.liveBodies.foreach(updateGraphics);
			
			if (DEBUG) debug.draw(space);
			if (DEBUG) debug.flush();
		}
		
		private function updateGraphics(b:Body):void {
			var graphic:DisplayObject = b.userData.graphic;
			graphic.x = b.position.x; 
			graphic.y = b.position.y;
			graphic.rotation = (b.rotation * 180 / Math.PI) % 360;
		}
		
		private function toVec2(obj:Object):Vec2 {
			var ret:Vec2 = new Vec2(obj.x, obj.y);
			
			ret.angle = obj.angle;
			//ret.length = obj.length;
			ret.zpp_disp = obj.zpp_disp;
			//ret.zpp_inner = obj.zpp_inner;
			ret.zpp_pool = obj.zpp_pool;
			
			return ret;
		}
		
	}

}