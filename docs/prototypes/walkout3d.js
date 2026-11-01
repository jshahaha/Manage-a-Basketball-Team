// Walkout cutscene in 3D: the same blocky R15-style player model and the same
// keyframe clips the game uses (src/shared/AnimClips.lua is generated from CLIPS).
// Sounds are fired from clip events on the animation clock, so they stay in sync.
(function(){
const T = window.THREE;
const BALL_R = .64; // a real ball is a little wider than a head
// ---------------- Rig (studs, Y up, facing +Z) ----------------
const RIG = {
  hipH: 2.45,
  // Slim athletic build (narrow torso, long thin limbs), so the ball reads at its real size.
  // Hands have a palm, four fingers and a thumb (js: blocky hands look wrong for wrist flicks).
  parts: [
    // name, parent joint, box size [w,h,d], center offset from joint, material slot
    ['LowerTorso','Root',[1.4,0.55,0.72],[0,0.27,0],'shorts'],
    ['UpperTorso','Waist',[1.5,1.6,0.78],[0,0.8,0],'jersey'],
    ['Head','Neck',[0.95,1.0,0.95],[0,0.55,0],'skin'],
    ['RUpperArm','RShoulder',[0.48,1.1,0.48],[0,-0.45,0],'skin'],
    ['RLowerArm','RElbow',[0.44,0.95,0.44],[0,-0.42,0],'skin'],
    ['RHand','RWrist',[0.2,0.32,0.42],[0,-0.17,0],'skin'],  // palm (faces the body at rest)
    ['RHandF1','RWrist',[0.12,0.25,0.09],[0.02,-0.435,-0.15],'skin',[0,0,12]],
    ['RHandF2','RWrist',[0.12,0.29,0.09],[0.02,-0.455,-0.05],'skin',[0,0,12]],
    ['RHandF3','RWrist',[0.12,0.28,0.09],[0.02,-0.450,0.05],'skin',[0,0,12]],
    ['RHandF4','RWrist',[0.12,0.23,0.09],[0.02,-0.425,0.15],'skin',[0,0,12]],
    ['RHandThumb','RWrist',[0.12,0.24,0.11],[0.06,-0.2,0.25],'skin',[-28,0,18]],
    ['LUpperArm','LShoulder',[0.48,1.1,0.48],[0,-0.45,0],'skin'],
    ['LLowerArm','LElbow',[0.44,0.95,0.44],[0,-0.42,0],'skin'],
    ['LHand','LWrist',[0.2,0.32,0.42],[0,-0.17,0],'skin'],  // palm (faces the body at rest)
    ['LHandF1','LWrist',[0.12,0.25,0.09],[-0.02,-0.435,-0.15],'skin',[0,0,-12]],
    ['LHandF2','LWrist',[0.12,0.29,0.09],[-0.02,-0.455,-0.05],'skin',[0,0,-12]],
    ['LHandF3','LWrist',[0.12,0.28,0.09],[-0.02,-0.450,0.05],'skin',[0,0,-12]],
    ['LHandF4','LWrist',[0.12,0.23,0.09],[-0.02,-0.425,0.15],'skin',[0,0,-12]],
    ['LHandThumb','LWrist',[0.12,0.24,0.11],[-0.06,-0.2,0.25],'skin',[-28,0,-18]],
    ['RUpperLeg','RHip',[0.6,1.15,0.6],[0,-0.55,0],'shorts'],
    ['RLowerLeg','RKnee',[0.52,1.0,0.52],[0,-0.5,0],'skin'],
    ['RFoot','RAnkle',[0.56,0.3,1.1],[0,-0.17,0.18],'shoe'],
    ['LUpperLeg','LHip',[0.6,1.15,0.6],[0,-0.55,0],'shorts'],
    ['LLowerLeg','LKnee',[0.52,1.0,0.52],[0,-0.5,0],'skin'],
    ['LFoot','LAnkle',[0.56,0.3,1.1],[0,-0.17,0.18],'shoe'],
  ],
  // joint, parent, offset from parent joint
  joints: [['Root',null,[0,0,0]],['Waist','Root',[0,0.55,0]],['Neck','Waist',[0,1.6,0]],
    ['RShoulder','Waist',[-1.0,1.42,0]],['RElbow','RShoulder',[0,-1.0,0]],
    ['LShoulder','Waist',[1.0,1.42,0]],['LElbow','LShoulder',[0,-1.0,0]],
    ['RHip','Root',[-0.38,0,0]],['RKnee','RHip',[0,-1.1,0]],
    ['LHip','Root',[0.38,0,0]],['LKnee','LHip',[0,-1.1,0]],
    ['RWrist','RElbow',[0,-0.86,0]],['LWrist','LElbow',[0,-0.86,0]],['RAnkle','RKnee',[0,-1.0,0]],['LAnkle','LKnee',[0,-1.0,0]]],
};
// ---------------- Clips ----------------
// Joint keys: [t, rx, ry, rz] in degrees. Raising an arm forward is negative X.
// Hip forward is negative X, knee bend is positive X, elbow bend is negative X.
// Root keys: [t, x, y, z, yaw, lean]. Ball keys: [t, where, ease, arc]. Events: [t, sound].
// Timings come from the movement study in docs/ANIMATIONS.md (jump shot: knee about 115 deg at the dip,
// release on the way up before the apex with the elbow about 20 deg short of straight, about 0.5 s in the air,
// ball about 1 s to the rim from deep; one-foot takeoff off the opposite foot with a long, low penultimate step;
// dribble 2.5 bounces a second; blockers meet the ball at the top of the jump).
const CLIPS = {
  Walk: { len: 1.0, loop: true,
    keys: {
      LHip:[[0,-24,0,0],[.5,22,0,0],[1,-24,0,0]], RHip:[[0,22,0,0],[.5,-24,0,0],[1,22,0,0]],
      LKnee:[[0,8,0,0],[.25,40,0,0],[.5,6,0,0],[.75,12,0,0],[1,8,0,0]], RKnee:[[0,6,0,0],[.25,12,0,0],[.5,8,0,0],[.75,40,0,0],[1,6,0,0]],
      LShoulder:[[0,20,0,6],[.5,-22,0,6],[1,20,0,6]], RShoulder:[[0,-22,0,-6],[.5,20,0,-6],[1,-22,0,-6]],
      LElbow:[[0,-15,0,0],[.5,-35,0,0],[1,-15,0,0]], RElbow:[[0,-35,0,0],[.5,-15,0,0],[1,-35,0,0]],
      Waist:[[0,0,-5,0],[.5,0,5,0],[1,0,-5,0]],
    },
    root: [[0,0,0,0,0,3],[.25,0,.12,0,0,3],[.5,0,0,0,0,3],[.75,0,.12,0,0,3],[1,0,0,0,0,3]],
  },
  // Jump shot, one motion: catch in the shot pocket (right foot a little ahead), dip with the ball,
  // the ball rises up the middle to a set point above the forehead with the wrist cocked (0.5),
  // release on the way up with a wrist snap (0.72), apex (0.82), land (1.08), and the
  // "goose neck" follow-through held until the ball drops. The guide hand stays on the side and quiet.
  Shoot: { len: 2.6, face: 90, view: -30, cam: [[3.5,5.6,21],[3.2,5.0,0]], shotHoop: true,
    keys: {
      RShoulder:[[0,-42,0,-10],[.3,-34,0,-8],[.5,-112,0,2],[.72,-148,0,0],[1.7,-146,0,0],[2.05,-80,0,-8],[2.6,-20,0,-8]],
      RElbow:[[0,-95,0,0],[.3,-100,0,0],[.5,-112,0,0],[.72,-16,0,0],[1.7,-12,0,0],[2.05,-30,0,0],[2.6,-15,0,0]],
      RWrist:[[0,-20,0,0],[.3,-25,0,0],[.5,-60,0,0],[.66,-50,0,0],[.76,55,0,0],[1.7,60,0,0],[2.05,10,0,0],[2.6,0,0,0]],
      LShoulder:[[0,-48,0,22],[.3,-40,0,22],[.5,-110,0,24],[.72,-118,0,30],[1.4,-112,0,30],[1.9,-50,0,14],[2.6,-15,0,6]],
      LElbow:[[0,-95,0,0],[.3,-98,0,0],[.5,-88,0,0],[.72,-50,0,0],[1.4,-46,0,0],[2.6,-15,0,0]],
      LWrist:[[0,-10,0,0],[.5,-15,0,0],[.72,0,0,0],[2.6,0,0,0]],
      LHip:[[0,2,0,10],[.3,-34,0,10],[.55,2,0,6],[.82,-4,0,6],[.95,-12,0,6],[1.08,-10,0,8],[1.18,-30,0,10],[1.6,0,0,10],[2.6,2,0,8]],
      RHip:[[0,-14,0,-10],[.3,-44,0,-10],[.55,-6,0,-6],[.82,-10,0,-6],[.95,-18,0,-6],[1.08,-16,0,-8],[1.18,-40,0,-10],[1.6,-12,0,-10],[2.6,-8,0,-8]],
      LKnee:[[0,16,0,0],[.3,62,0,0],[.55,4,0,0],[.82,10,0,0],[.95,22,0,0],[1.08,18,0,0],[1.18,52,0,0],[1.6,14,0,0],[2.6,8,0,0]],
      RKnee:[[0,18,0,0],[.3,66,0,0],[.55,4,0,0],[.82,12,0,0],[.95,24,0,0],[1.08,20,0,0],[1.18,56,0,0],[1.6,16,0,0],[2.6,8,0,0]],
      Waist:[[0,6,-8,0],[.3,10,-6,0],[.55,0,0,0],[1.08,4,0,0],[2.6,0,0,0]],
      Neck:[[0,-10,0,0],[.5,-18,0,0],[1.85,-18,0,0],[2.6,-2,0,0]],
    },
    root: [[0,0,-.15,0,90,5],[.3,0,-.58,0,90,10],[.55,0,.2,0,90,1],[.72,0,.85,0,90,-1],[.82,0,.95,0,90,-1],[.95,0,.8,0,90,0],[1.08,.1,.05,0,90,3],[1.18,.1,-.4,0,90,7],[1.6,.1,-.05,0,90,2],[2.6,.1,0,0,90,0]],
    ball: [[0,'both'],[.42,'both'],[.5,'RTip'],[.72,'RTip'],[1.75,'rim',0,4.6],[1.85,'net',0,0],[2.15,'floorUnderRim',2,0],[2.6,'gone']],
    events: [[.3,'ShoeSqueak'],[.72,'ShotRelease'],[1.08,'ShoeSqueak'],[1.85,'Swish'],[1.9,'CrowdCheerM']],
  },
  // Dunk off the left foot (right-handed): two jog steps, long low penultimate step on the right (0.42),
  // plant left (0.62), take off with the right knee driving up (0.82), slam (1.12), hang, land on both feet (1.78).
  Dunk: { len: 2.6, face: 90, view: -30, cam: [[3.5,5.6,21],[3.2,5.0,0]],
    keys: {
      LHip:[[0,24,0,0],[.2,-32,0,0],[.42,20,0,0],[.62,-40,0,0],[.82,-6,0,0],[1.05,0,0,0],[1.35,-30,0,0],[1.78,-36,0,0],[2.2,-6,0,0],[2.6,-4,0,0]],
      LKnee:[[0,50,0,0],[.2,20,0,0],[.42,55,0,0],[.62,60,0,0],[.82,4,0,0],[1.05,25,0,0],[1.35,30,0,0],[1.78,64,0,0],[2.2,10,0,0],[2.6,6,0,0]],
      RHip:[[0,-30,0,0],[.2,24,0,0],[.42,-40,0,0],[.62,14,0,0],[.82,-60,0,0],[1.05,-75,0,0],[1.35,-40,0,0],[1.78,-34,0,0],[2.2,-6,0,0],[2.6,-4,0,0]],
      RKnee:[[0,20,0,0],[.2,50,0,0],[.42,40,0,0],[.62,75,0,0],[.82,90,0,0],[1.05,100,0,0],[1.35,40,0,0],[1.78,58,0,0],[2.2,10,0,0],[2.6,6,0,0]],
      RShoulder:[[0,-30,0,-10],[.4,-40,0,-10],[.62,-70,0,-8],[.82,-150,0,-4],[1.02,-178,0,0],[1.14,-120,0,0],[1.35,-172,0,0],[1.6,-170,0,0],[1.78,-60,0,-10],[2.2,-80,0,-60],[2.6,-82,0,-62]],
      RElbow:[[0,-40,0,0],[.62,-70,0,0],[.82,-30,0,0],[1.02,-10,0,0],[1.14,-20,0,0],[1.35,-5,0,0],[1.78,-40,0,0],[2.2,-120,0,0],[2.6,-125,0,0]],
      LShoulder:[[0,20,0,8],[.4,-30,0,10],[.62,-70,0,10],[.82,-110,0,14],[1.02,-90,0,30],[1.35,-70,0,40],[1.78,-50,0,20],[2.2,-80,0,60],[2.6,-82,0,62]],
      LElbow:[[0,-30,0,0],[.62,-70,0,0],[1.02,-20,0,0],[1.78,-30,0,0],[2.2,-120,0,0],[2.6,-125,0,0]],
      Neck:[[0,-6,0,0],[.82,-20,0,0],[1.14,10,0,0],[1.78,0,0,0],[2.2,-10,0,0]],
    },
    root: [[0,-2.6,0,0,90,14],[.2,-1.9,.15,0,90,14],[.42,-1.1,-.3,0,90,15],[.62,-.4,-.45,0,90,16],[.82,.5,.6,0,90,6],[1.02,1.6,2.05,0,90,-4],[1.14,1.9,1.95,0,90,6],[1.35,2.0,1.9,0,90,0],[1.6,2.05,1.7,0,90,0],[1.78,2.15,-.35,0,90,10],[2.2,2.15,0,0,60,0],[2.6,2.15,0,0,30,0]],
    ball: [[0,'R'],[.6,'R'],[.62,'both'],[.82,'both'],[.84,'R'],[1.12,'R'],[1.2,'net',0,0],[1.5,'floorUnderRim',2,0],[1.8,'bounceUnderRim',1,0],[2.1,'floorUnderRim2',2,0],[2.6,'gone']],
    hoopAt: [1.12, 'R'], // the rim is placed where the right hand is at the slam
    events: [[.42,'ShoeSqueak'],[.62,'ShoeSqueak'],[1.12,'Dunk'],[1.13,'RimOut'],[1.18,'CrowdCheerL'],[1.5,'Dribble'],[1.79,'ShoeSqueak'],[2.1,'Dribble']],
  },
  // Block: load (0.35), two-foot jump (0.62), meet the ball at the top (0.76), land (1.22).
  Block: { len: 2.4, face: 70, view: -30, cam: [[1,5.8,21],[0.5,5.4,0]],
    keys: {
      RShoulder:[[0,-40,0,-24],[.35,-30,0,-20],[.62,-165,0,-6],[.75,-182,0,0],[.92,-176,0,-4],[1.4,-60,0,-20],[2.4,-20,0,-10]],
      RElbow:[[0,-50,0,0],[.35,-60,0,0],[.62,-20,0,0],[.75,-2,0,0],[1.4,-30,0,0],[2.4,-15,0,0]],
      LShoulder:[[0,-40,0,24],[.35,-30,0,20],[.62,-120,0,30],[.75,-140,0,40],[1.0,-110,0,40],[1.4,-50,0,20],[2.4,-20,0,10]],
      LElbow:[[0,-50,0,0],[.35,-60,0,0],[.75,-20,0,0],[1.4,-30,0,0],[2.4,-15,0,0]],
      LHip:[[0,-24,0,8],[.35,-46,0,8],[.62,-4,0,4],[.8,-12,0,2],[1.2,-40,0,6],[1.6,-10,0,6],[2.4,-4,0,6]],
      RHip:[[0,-24,0,-8],[.35,-46,0,-8],[.62,-2,0,-4],[.8,-8,0,-2],[1.2,-36,0,-6],[1.6,-10,0,-6],[2.4,-4,0,-6]],
      LKnee:[[0,40,0,0],[.35,78,0,0],[.62,6,0,0],[.8,24,0,0],[1.2,64,0,0],[1.6,14,0,0],[2.4,6,0,0]],
      RKnee:[[0,40,0,0],[.35,74,0,0],[.62,4,0,0],[.8,18,0,0],[1.2,60,0,0],[1.6,14,0,0],[2.4,6,0,0]],
      Neck:[[0,0,0,0],[.6,-24,0,0],[1.0,-10,0,0],[2.4,0,0,0]],
    },
    root: [[0,0,-.4,0,70,6],[.35,0,-.8,0,70,10],[.62,0,.6,0,70,-2],[.78,0,1.75,0,70,-4],[.95,0,1.6,0,70,-2],[1.15,0,-.1,0,70,6],[1.22,0,-.55,0,70,10],[1.6,0,0,0,70,2],[2.4,0,0,0,40,0]],
    ball: [[0,'gone'],[.3,'shotStart'],[.76,'RTip',0,1.2],[1.25,'swatAway',0,1.5],[1.3,'gone']],
    events: [[.36,'ShoeSqueak'],[.76,'Block'],[.76,'Dribble'],[.82,'CrowdOoh'],[1.23,'ShoeSqueak']],
  },
  Pose: { len: 1.2, face: 0, hold: true, cam: [[0,4.6,12.5],[0,4.0,0]],
    keys: {
      RShoulder:[[0,-30,0,-10],[.5,-80,0,-60],[1.2,-82,0,-62]], RElbow:[[0,-30,0,0],[.5,-125,0,0],[1.2,-128,0,0]],
      LShoulder:[[0,-30,0,10],[.5,-80,0,60],[1.2,-82,0,62]], LElbow:[[0,-30,0,0],[.5,-125,0,0],[1.2,-128,0,0]],
      LHip:[[0,-4,0,8],[1.2,-4,0,10]], RHip:[[0,-4,0,-8],[1.2,-4,0,-10]], LKnee:[[0,6,0,0],[1.2,6,0,0]], RKnee:[[0,6,0,0],[1.2,6,0,0]],
      Neck:[[0,0,0,0],[.5,8,0,0],[1.2,6,0,0]], Waist:[[0,0,0,0],[.5,-6,0,0],[1.2,-5,0,0]],
    },
    root: [[0,0,0,0,0,0],[.5,0,.05,0,0,-4],[1.2,0,0,0,0,-3]],
    events: [[.45,'CrowdCheerL']],
  },

  // ---------- In-game clips (match view) ----------
  // Ready stance: knees soft, weight on the balls of the feet, a slow breath.
  Idle: { len: 2.0, loop: true, face: 0, view: -30, cam: [[1.5,4.2,14],[0,3.0,0]],
    keys: {
      LHip:[[0,-14,0,6],[1,-16,0,6],[2,-14,0,6]], RHip:[[0,-14,0,-6],[1,-16,0,-6],[2,-14,0,-6]],
      LKnee:[[0,22,0,0],[1,26,0,0],[2,22,0,0]], RKnee:[[0,22,0,0],[1,26,0,0],[2,22,0,0]],
      LShoulder:[[0,-10,0,10],[1,-12,0,12],[2,-10,0,10]], RShoulder:[[0,-10,0,-10],[1,-12,0,-12],[2,-10,0,-10]],
      LElbow:[[0,-22,0,0],[1,-26,0,0],[2,-22,0,0]], RElbow:[[0,-22,0,0],[1,-26,0,0],[2,-22,0,0]],
      Waist:[[0,6,0,0],[1,8,0,0],[2,6,0,0]], Neck:[[0,-4,0,0],[1,-2,0,0],[2,-4,0,0]],
    },
    root: [[0,0,-.18,0,0,4],[1,0,-.24,0,0,5],[2,0,-.18,0,0,4]],
  },
  // Jog: 0.7 s stride (about 170 steps a minute), more knee lift and arm drive than the walk.
  Jog: { len: 0.7, loop: true, face: 90, view: -30, cam: [[1.5,4.2,16],[0,3.0,0]],
    keys: {
      LHip:[[0,-36,0,0],[.35,26,0,0],[.7,-36,0,0]], RHip:[[0,26,0,0],[.35,-36,0,0],[.7,26,0,0]],
      LKnee:[[0,18,0,0],[.12,30,0,0],[.25,85,0,0],[.35,30,0,0],[.5,18,0,0],[.7,18,0,0]],
      RKnee:[[0,30,0,0],[.15,18,0,0],[.35,18,0,0],[.47,30,0,0],[.6,85,0,0],[.7,30,0,0]],
      LShoulder:[[0,32,0,6],[.35,-38,0,6],[.7,32,0,6]], RShoulder:[[0,-38,0,-6],[.35,32,0,-6],[.7,-38,0,-6]],
      LElbow:[[0,-80,0,0],[.7,-80,0,0]], RElbow:[[0,-80,0,0],[.7,-80,0,0]],
      Waist:[[0,4,-8,0],[.35,4,8,0],[.7,4,-8,0]],
    },
    root: [[0,0,-.1,0,0,9],[.17,0,.25,0,0,9],[.35,0,-.1,0,0,9],[.52,0,.25,0,0,9],[.7,0,-.1,0,0,9]],
    events: [[0,'ShoeSqueak']],
  },
  // Defensive slide: wide, low, hands active. Push off the trail foot, never cross the feet.
  DefSlide: { len: 0.9, loop: true, face: 0, view: -20, cam: [[1,4.0,15],[0,2.6,0]],
    keys: {
      LHip:[[0,-40,0,30],[.22,-40,0,16],[.45,-40,0,30],[.67,-40,0,16],[.9,-40,0,30]],
      RHip:[[0,-40,0,-30],[.22,-40,0,-16],[.45,-40,0,-30],[.67,-40,0,-16],[.9,-40,0,-30]],
      LKnee:[[0,62,0,0],[.9,62,0,0]], RKnee:[[0,62,0,0],[.9,62,0,0]],
      LShoulder:[[0,-30,0,72],[.45,-38,0,62],[.9,-30,0,72]], RShoulder:[[0,-38,0,-62],[.45,-30,0,-72],[.9,-38,0,-62]],
      LElbow:[[0,-40,0,0],[.9,-40,0,0]], RElbow:[[0,-40,0,0],[.9,-40,0,0]],
      Waist:[[0,16,0,0],[.9,16,0,0]], Neck:[[0,-12,0,0],[.9,-12,0,0]],
    },
    root: [[0,0,-.85,0,0,8],[.22,.7,-.75,0,0,8],[.45,1.0,-.85,0,0,8],[.67,.3,-.75,0,0,8],[.9,0,-.85,0,0,8]],
    events: [[0,'ShoeSqueak'],[.45,'ShoeSqueak']],
  },
  // Right-hand layup off the left foot: gather (0), right step (0.15), plant left (0.32),
  // take off with the right knee up (0.5), release at the top (0.85), land (1.15).
  Layup: { len: 2.2, face: 90, view: -30, cam: [[2.5,6.4,23],[1.2,5.6,0]],
    keys: {
      LHip:[[0,20,0,0],[.15,24,0,0],[.32,-36,0,0],[.5,-4,0,0],[.85,2,0,0],[1.15,-20,0,0],[1.3,-34,0,0],[1.7,-6,0,0],[2.2,-4,0,0]],
      LKnee:[[0,50,0,0],[.15,60,0,0],[.32,55,0,0],[.5,6,0,0],[.85,30,0,0],[1.15,22,0,0],[1.3,56,0,0],[1.7,10,0,0],[2.2,6,0,0]],
      RHip:[[0,-30,0,0],[.15,-40,0,0],[.32,16,0,0],[.5,-60,0,0],[.85,-72,0,0],[1.15,-24,0,0],[1.3,-32,0,0],[1.7,-6,0,0],[2.2,-4,0,0]],
      RKnee:[[0,30,0,0],[.15,40,0,0],[.32,75,0,0],[.5,92,0,0],[.85,96,0,0],[1.15,24,0,0],[1.3,54,0,0],[1.7,10,0,0],[2.2,6,0,0]],
      RShoulder:[[0,-50,0,-8],[.32,-55,0,-8],[.5,-110,0,-4],[.85,-168,0,-2],[1.1,-150,0,-4],[1.5,-40,0,-8],[2.2,-15,0,-6]],
      RElbow:[[0,-90,0,0],[.32,-95,0,0],[.5,-60,0,0],[.85,-12,0,0],[1.1,-15,0,0],[1.5,-30,0,0],[2.2,-15,0,0]],
      LShoulder:[[0,-50,0,8],[.32,-55,0,8],[.5,-90,0,14],[.85,-70,0,30],[1.1,-50,0,26],[1.5,-20,0,10],[2.2,-15,0,6]],
      LElbow:[[0,-90,0,0],[.32,-95,0,0],[.5,-70,0,0],[.85,-50,0,0],[1.5,-25,0,0],[2.2,-15,0,0]],
      Neck:[[0,-6,0,0],[.5,-18,0,0],[1.1,-16,0,0],[1.7,0,0,0]],
    },
    root: [[0,-2.4,0,0,90,10],[.15,-1.6,-.2,0,90,12],[.32,-.8,-.45,0,90,14],[.5,0,.35,0,90,6],[.85,.9,1.55,0,90,-2],[1.0,1.15,1.35,0,90,0],[1.15,1.3,0,0,90,6],[1.3,1.35,-.45,0,90,10],[1.7,1.4,0,0,90,2],[2.2,1.4,0,0,90,0]],
    ball: [[0,'both'],[.5,'both'],[.85,'RTip'],[1.12,'rim',0,.5],[1.22,'net',0,0],[1.55,'floorUnderRim',2,0],[2.2,'gone']],
    hoopAt: [.85, 'R'], hoopOff: [.9, 1.4],
    events: [[.15,'ShoeSqueak'],[.32,'ShoeSqueak'],[.85,'LayupKiss'],[1.22,'Swish'],[1.15,'ShoeSqueak'],[1.25,'CrowdCheerM']],
  },
  // Chest pass: ball at the chest, step into it, arms extend and thumbs turn down, hands follow through.
  ChestPass: { len: 1.2, face: 90, view: -30, cam: [[2.5,4.4,16],[2.0,3.4,0]],
    keys: {
      RShoulder:[[0,-45,0,-12],[.25,-35,0,-16],[.45,-88,0,-6],[.6,-92,0,-4],[1.2,-20,0,-8]],
      RElbow:[[0,-100,0,0],[.25,-115,0,0],[.45,-8,0,0],[.6,-4,0,0],[1.2,-20,0,0]],
      LShoulder:[[0,-45,0,12],[.25,-35,0,16],[.45,-88,0,6],[.6,-92,0,4],[1.2,-20,0,8]],
      LElbow:[[0,-100,0,0],[.25,-115,0,0],[.45,-8,0,0],[.6,-4,0,0],[1.2,-20,0,0]],
      RWrist:[[0,-20,0,0],[.3,-30,0,0],[.45,40,0,0],[.7,40,0,0],[1.2,0,0,0]], LWrist:[[0,-20,0,0],[.3,-30,0,0],[.45,40,0,0],[.7,40,0,0],[1.2,0,0,0]],
      LHip:[[0,-10,0,6],[.25,-12,0,6],[.45,-34,0,6],[.7,-30,0,6],[1.2,-12,0,6]],
      RHip:[[0,-10,0,-6],[.25,-12,0,-6],[.45,12,0,-6],[.7,10,0,-6],[1.2,-10,0,-6]],
      LKnee:[[0,20,0,0],[.25,30,0,0],[.45,22,0,0],[1.2,20,0,0]], RKnee:[[0,20,0,0],[.25,30,0,0],[.45,24,0,0],[1.2,20,0,0]],
      Neck:[[0,-4,0,0],[1.2,-4,0,0]],
    },
    root: [[0,0,-.15,0,90,4],[.25,0,-.3,0,90,6],[.45,.6,-.2,0,90,10],[.7,.65,-.15,0,90,6],[1.2,.65,-.15,0,90,3]],
    ball: [[0,'both'],[.45,'both'],[.85,'passTarget',0,.2],[.9,'gone']],
    events: [[.45,'PassChest'],[.45,'ShoeSqueak']],
  },
  // Rebound: read the miss, load, two-foot jump, both hands high at the top, chin the ball with elbows out.
  Rebound: { len: 2.0, face: 0, view: -30, cam: [[1.5,5.4,17],[0,5.0,0]],
    keys: {
      RShoulder:[[0,-30,0,-14],[.45,-20,0,-14],[.62,-160,0,-4],[.75,-172,0,-2],[.95,-60,0,-40],[1.2,-55,0,-45],[2.0,-50,0,-40]],
      RElbow:[[0,-40,0,0],[.45,-30,0,0],[.75,-10,0,0],[.95,-110,0,0],[2.0,-115,0,0]],
      LShoulder:[[0,-30,0,14],[.45,-20,0,14],[.62,-160,0,4],[.75,-172,0,2],[.95,-60,0,40],[1.2,-55,0,45],[2.0,-50,0,40]],
      LElbow:[[0,-40,0,0],[.45,-30,0,0],[.75,-10,0,0],[.95,-110,0,0],[2.0,-115,0,0]],
      LHip:[[0,-20,0,10],[.45,-44,0,10],[.62,-4,0,6],[.85,-14,0,6],[1.0,-14,0,10],[1.12,-42,0,12],[1.5,-28,0,12],[2.0,-28,0,12]],
      RHip:[[0,-20,0,-10],[.45,-44,0,-10],[.62,-4,0,-6],[.85,-12,0,-6],[1.0,-12,0,-10],[1.12,-40,0,-12],[1.5,-28,0,-12],[2.0,-28,0,-12]],
      LKnee:[[0,30,0,0],[.45,74,0,0],[.62,4,0,0],[.85,24,0,0],[1.0,20,0,0],[1.12,66,0,0],[1.5,44,0,0],[2.0,44,0,0]],
      RKnee:[[0,30,0,0],[.45,72,0,0],[.62,4,0,0],[.85,20,0,0],[1.0,18,0,0],[1.12,62,0,0],[1.5,44,0,0],[2.0,44,0,0]],
      Neck:[[0,-20,0,0],[.75,-26,0,0],[.95,0,0,0],[2.0,0,0,0]],
      Waist:[[0,4,0,0],[1.12,14,0,0],[1.5,10,0,0],[2.0,10,0,0]],
    },
    root: [[0,0,-.3,0,0,4],[.45,0,-.8,0,0,10],[.62,0,.6,0,0,-2],[.75,0,1.6,0,0,-3],[.88,0,1.4,0,0,-1],[1.0,0,0,0,0,4],[1.12,0,-.7,0,0,10],[1.5,0,-.45,0,0,8],[2.0,0,-.45,0,0,8]],
    ball: [[0,'reboundIn'],[.75,'both',1,1.5],[2.0,'both']],
    events: [[.45,'ShoeSqueak'],[.75,'ReboundGrab'],[1.0,'ShoeSqueak']],
  },
};
// ---------- Ball handling (skilled style) ----------
// Every dribble move starts and ends in the same "catch" pose with the ball in the right hand,
// so moves chain into each other (the walkout combo below is built by chaining them).
// Style notes from the study: low and wide, chest up, eyes up (not on the ball), the off arm
// held out as an arm bar, the wrist snaps the ball down and the hand rides it back up,
// the body bobs on every push, and every crossover is low, quick and comes with a weight shift.
const P0 = {
  LHip:[-40,0,14], RHip:[-36,0,-14], LKnee:[62,0,0], RKnee:[60,0,0],
  Waist:[20,-6,0], Neck:[-24,0,0],
  RShoulder:[-34,0,-20], RElbow:[-75,0,0], RWrist:[-25,0,0],
  LShoulder:[-62,0,24], LElbow:[-85,0,0], LWrist:[0,0,0],
};
const ROOT0 = [0,-.9,0,0,6];
function withBase(c){
  for (const j in P0){
    if (!c.keys[j]) c.keys[j] = [[0, ...P0[j]], [c.len, ...P0[j]]];
    else {
      if (c.keys[j][0][0] > 0) c.keys[j].unshift([0, ...P0[j]]);
      if (c.keys[j][c.keys[j].length-1][0] < c.len) c.keys[j].push([c.len, ...P0[j]]);
    }
  }
  if (!c.root) c.root = [[0, ...ROOT0], [c.len, ...ROOT0]];
  return c;
}
function chain(names, extra){
  const out = Object.assign({ len: 0, keys: {}, root: [], ball: [], events: [] }, extra || {});
  for (const n of names){
    const c = CLIPS[n], o = out.len;
    const add = (dst, src) => src.forEach(k => { const kk = [k[0] + o, ...k.slice(1)]; if (dst.length && Math.abs(dst[dst.length-1][0] - kk[0]) < 1e-6) dst.pop(); dst.push(kk); });
    for (const j in c.keys){ out.keys[j] = out.keys[j] || []; add(out.keys[j], c.keys[j]); }
    add(out.root, c.root); add(out.ball, c.ball || []);
    (c.events || []).forEach(e => out.events.push([e[0] + o, e[1]]));
    out.len = +(o + c.len).toFixed(3);
  }
  return out;
}
const DRIBBLE_CAM = { face: 0, view: -28, cam: [[1.6,4.0,14.5],[0,2.6,0]] };

// Live dribble: two right-hand pounds, about 2.2 a second.
CLIPS.DribbleLive = withBase(Object.assign({ len: .9, loop: true,
  keys: {
    RShoulder:[[0,-34,0,-20],[.1,-20,0,-17],[.2,-22,0,-17],[.45,-34,0,-20],[.55,-20,0,-17],[.65,-22,0,-17],[.9,-34,0,-20]],
    RElbow:[[0,-75,0,0],[.1,-38,0,0],[.2,-42,0,0],[.45,-75,0,0],[.55,-38,0,0],[.65,-42,0,0],[.9,-75,0,0]],
    RWrist:[[0,-25,0,0],[.07,10,0,0],[.13,42,0,0],[.3,5,0,0],[.45,-25,0,0],[.52,10,0,0],[.58,42,0,0],[.75,5,0,0],[.9,-25,0,0]],
    Waist:[[0,20,-6,0],[.2,23,-8,0],[.45,20,-6,0],[.65,23,-8,0],[.9,20,-6,0]],
  },
  root: [[0,0,-.9,0,0,6],[.15,0,-.98,0,0,7],[.45,0,-.9,0,0,6],[.6,0,-.98,0,0,7],[.9,0,-.9,0,0,6]],
  ball: [[0,'R'],[.2,'floorR',2,0],[.45,'R',1,0],[.65,'floorR',2,0],[.9,'R',1,0]],
  events: [[.2,'Dribble'],[.65,'Dribble']],
}, DRIBBLE_CAM));

// Crossover: right to left low and quick with a hard step, one left pound, cross back.
CLIPS.Crossover = withBase(Object.assign({ len: 1.0,
  keys: {
    RShoulder:[[0,-34,0,-20],[.1,-24,0,4],[.18,-22,0,10],[.3,-60,0,-22],[.75,-62,0,-24],[.88,-50,0,-22],[1.0,-34,0,-20]],
    RElbow:[[0,-75,0,0],[.1,-42,0,0],[.18,-38,0,0],[.3,-85,0,0],[.88,-85,0,0],[1.0,-75,0,0]],
    RWrist:[[0,-25,0,0],[.08,15,0,0],[.15,45,0,0],[.3,0,0,0],[.9,0,0,0],[1.0,-25,0,0]],
    LShoulder:[[0,-62,0,24],[.18,-50,0,22],[.3,-34,0,20],[.42,-20,0,17],[.52,-22,0,17],[.75,-34,0,20],[.85,-24,0,-4],[.9,-22,0,-10],[1.0,-62,0,24]],
    LElbow:[[0,-85,0,0],[.18,-82,0,0],[.3,-75,0,0],[.42,-38,0,0],[.52,-42,0,0],[.75,-75,0,0],[.85,-42,0,0],[.9,-38,0,0],[1.0,-85,0,0]],
    LWrist:[[0,0,0,0],[.2,0,0,0],[.3,-25,0,0],[.38,15,0,0],[.45,42,0,0],[.6,5,0,0],[.75,-25,0,0],[.83,15,0,0],[.9,45,0,0],[1.0,0,0,0]],
    LHip:[[0,-40,0,14],[.3,-36,0,26],[.75,-38,0,24],[1.0,-40,0,14]],
    RHip:[[0,-36,0,-14],[.3,-40,0,-6],[.75,-40,0,-8],[1.0,-36,0,-14]],
    LKnee:[[0,62,0,0],[.3,70,0,0],[.75,66,0,0],[1.0,62,0,0]],
    Waist:[[0,20,-6,0],[.18,22,4,0],[.3,22,10,0],[.75,22,8,0],[.9,22,-4,0],[1.0,20,-6,0]],
  },
  root: [[0,0,-.9,0,0,6],[.18,.25,-1.0,0,6,8],[.3,.45,-.98,0,12,8],[.52,.5,-1.0,0,12,8],[.75,.45,-.95,0,10,7],[.9,.2,-1.0,0,0,8],[1.0,0,-.9,0,0,6]],
  ball: [[0,'R'],[.18,'floorMid',2,0],[.3,'L',1,0],[.52,'floorL',2,0],[.75,'L',1,0],[.9,'floorMid',2,0],[1.0,'R',1,0]],
  events: [[.18,'Dribble'],[.3,'ShoeSqueak'],[.52,'Dribble'],[.9,'Dribble'],[.95,'ShoeSqueak']],
}, DRIBBLE_CAM));

// Between the legs: left foot steps forward, the ball goes under the front leg to the left hand,
// one left pound, then a crossover back as the foot comes home.
CLIPS.BetweenLegs = withBase(Object.assign({ len: 1.1,
  keys: {
    LHip:[[0,-40,0,14],[.15,-62,0,16],[.75,-60,0,16],[1.1,-40,0,14]],
    LKnee:[[0,62,0,0],[.15,78,0,0],[.75,76,0,0],[1.1,62,0,0]],
    RHip:[[0,-36,0,-14],[.15,4,0,-14],[.75,2,0,-14],[1.1,-36,0,-14]],
    RKnee:[[0,60,0,0],[.15,58,0,0],[.75,58,0,0],[1.1,60,0,0]],
    RShoulder:[[0,-34,0,-20],[.15,-6,0,-6],[.25,4,0,8],[.38,-55,0,-22],[.85,-58,0,-22],[.98,-40,0,-20],[1.1,-34,0,-20]],
    RElbow:[[0,-75,0,0],[.15,-30,0,0],[.25,-20,0,0],[.38,-85,0,0],[.98,-80,0,0],[1.1,-75,0,0]],
    RWrist:[[0,-25,0,0],[.12,20,0,0],[.22,45,0,0],[.38,0,0,0],[1.1,-25,0,0]],
    LShoulder:[[0,-62,0,24],[.25,-30,0,26],[.38,-14,0,22],[.48,-18,0,18],[.62,-12,0,17],[.75,-20,0,18],[.88,-16,0,-6],[.95,-18,0,-10],[1.1,-62,0,24]],
    LElbow:[[0,-85,0,0],[.25,-60,0,0],[.38,-55,0,0],[.48,-40,0,0],[.62,-45,0,0],[.75,-62,0,0],[.88,-40,0,0],[1.1,-85,0,0]],
    LWrist:[[0,0,0,0],[.38,-25,0,0],[.5,40,0,0],[.62,0,0,0],[.75,-25,0,0],[.9,45,0,0],[1.1,0,0,0]],
    Waist:[[0,20,-6,0],[.25,24,2,0],[.75,24,4,0],[1.1,20,-6,0]],
  },
  root: [[0,0,-.9,0,0,6],[.15,.05,-1.05,.25,4,10],[.38,.05,-1.08,.3,6,10],[.75,.05,-1.05,.3,6,10],[1.1,0,-.9,0,0,6]],
  ball: [[0,'R'],[.25,'floorBetween',2,0],[.38,'L',1,0],[.62,'floorL',2,0],[.78,'L',1,0],[.95,'floorMid',2,0],[1.1,'R',1,0]],
  events: [[.15,'ShoeSqueak'],[.25,'Dribble'],[.62,'Dribble'],[.95,'Dribble'],[1.05,'ShoeSqueak']],
}, DRIBBLE_CAM));

// Behind the back: the right arm wraps the ball behind the hips to the left hand, then a crossover back.
CLIPS.BehindBack = withBase(Object.assign({ len: 1.15,
  keys: {
    RShoulder:[[0,-34,0,-20],[.12,10,0,-16],[.24,34,0,4],[.36,-50,0,-22],[.9,-58,0,-22],[1.02,-40,0,-20],[1.15,-34,0,-20]],
    RElbow:[[0,-75,0,0],[.12,-40,0,0],[.24,-55,0,0],[.36,-85,0,0],[1.02,-80,0,0],[1.15,-75,0,0]],
    RWrist:[[0,-25,0,0],[.12,10,0,0],[.22,40,0,0],[.36,0,0,0],[1.15,-25,0,0]],
    LShoulder:[[0,-62,0,24],[.24,-36,0,22],[.36,-28,0,20],[.46,-20,0,17],[.58,-22,0,17],[.8,-34,0,20],[.9,-24,0,-4],[.97,-22,0,-10],[1.15,-62,0,24]],
    LElbow:[[0,-85,0,0],[.36,-72,0,0],[.46,-40,0,0],[.58,-42,0,0],[.8,-75,0,0],[.9,-42,0,0],[1.15,-85,0,0]],
    LWrist:[[0,0,0,0],[.36,-25,0,0],[.46,40,0,0],[.62,5,0,0],[.8,-25,0,0],[.95,45,0,0],[1.15,0,0,0]],
    Waist:[[0,20,-6,0],[.2,20,-16,0],[.36,20,10,0],[.8,20,8,0],[1.15,20,-6,0]],
  },
  root: [[0,0,-.9,0,0,6],[.2,-.1,-.95,0,-8,6],[.36,.35,-.98,0,10,7],[.8,.4,-.95,0,10,7],[.97,.15,-1.0,0,0,8],[1.15,0,-.9,0,0,6]],
  ball: [[0,'R'],[.24,'floorBehind',2,0],[.38,'L',1,0],[.58,'floorL',2,0],[.8,'L',1,0],[.97,'floorMid',2,0],[1.15,'R',1,0]],
  events: [[.24,'Dribble'],[.36,'ShoeSqueak'],[.58,'Dribble'],[.97,'Dribble']],
}, DRIBBLE_CAM));

// Hesitation: stand up and slow the dribble to sell a pull-up, then drop and explode.
CLIPS.Hesitation = withBase(Object.assign({ len: 1.3,
  keys: {
    LHip:[[0,-40,0,14],[.4,-22,0,12],[.9,-22,0,12],[1.05,-46,0,14],[1.3,-40,0,14]],
    RHip:[[0,-36,0,-14],[.4,-18,0,-12],[.9,-18,0,-12],[1.05,-30,0,-14],[1.3,-36,0,-14]],
    LKnee:[[0,62,0,0],[.4,34,0,0],[.9,34,0,0],[1.05,72,0,0],[1.3,62,0,0]],
    RKnee:[[0,60,0,0],[.4,32,0,0],[.9,32,0,0],[1.05,64,0,0],[1.3,60,0,0]],
    Waist:[[0,20,-6,0],[.4,6,-2,0],[.9,6,-2,0],[1.05,26,-8,0],[1.3,20,-6,0]],
    Neck:[[0,-24,0,0],[.4,-6,0,0],[.9,-6,0,0],[1.05,-28,0,0],[1.3,-24,0,0]],
    RShoulder:[[0,-34,0,-20],[.1,-20,0,-17],[.2,-22,0,-17],[.5,-44,0,-20],[.65,-26,0,-17],[.75,-24,0,-17],[1.0,-36,0,-20],[1.07,-14,0,-18],[1.15,-14,0,-18],[1.3,-34,0,-20]],
    RElbow:[[0,-75,0,0],[.1,-38,0,0],[.2,-42,0,0],[.5,-88,0,0],[.65,-40,0,0],[.75,-44,0,0],[1.0,-75,0,0],[1.07,-30,0,0],[1.15,-34,0,0],[1.3,-75,0,0]],
    RWrist:[[0,-25,0,0],[.13,42,0,0],[.3,5,0,0],[.5,-30,0,0],[.62,40,0,0],[.85,5,0,0],[1.0,-25,0,0],[1.07,45,0,0],[1.3,-25,0,0]],
    LShoulder:[[0,-62,0,24],[.4,-40,0,18],[.9,-40,0,18],[1.05,-66,0,26],[1.3,-62,0,24]],
  },
  root: [[0,0,-.9,0,0,6],[.4,0,-.42,0,0,0],[.9,0,-.42,0,0,0],[1.05,.1,-1.0,.3,0,16],[1.3,0,-.9,0,0,6]],
  ball: [[0,'R'],[.2,'floorR',2,0],[.5,'R',1,0],[.75,'floorR',2,0],[1.0,'R',1,0],[1.12,'floorRFar',2,0],[1.3,'R',1,0]],
  events: [[.2,'Dribble'],[.75,'Dribble'],[1.05,'ShoeSqueak'],[1.12,'Dribble']],
}, DRIBBLE_CAM));

// Walkout combo for floor generals: pound, crossover, between the legs, behind the back.
CLIPS.Dribble = chain(['DribbleLive','Crossover','BetweenLegs','BehindBack'], DRIBBLE_CAM);
CLIPS.Dribble.events = CLIPS.Dribble.events.filter(e => e[1] !== 'ShoeSqueak' || e[0] > .5);

// Bounce pass: step in, push the ball down and out so it bounces about two thirds of the way.
CLIPS.BouncePass = { len: 1.2, face: 90, view: -30, cam: [[3,4.4,17],[2.6,3.0,0]],
  keys: {
    RShoulder:[[0,-45,0,-12],[.25,-38,0,-16],[.45,-58,0,-6],[.6,-56,0,-4],[1.2,-20,0,-8]],
    RElbow:[[0,-100,0,0],[.25,-112,0,0],[.45,-6,0,0],[.6,-4,0,0],[1.2,-20,0,0]],
    RWrist:[[0,-20,0,0],[.3,-30,0,0],[.45,40,0,0],[.7,40,0,0],[1.2,0,0,0]],
    LShoulder:[[0,-45,0,12],[.25,-38,0,16],[.45,-58,0,6],[.6,-56,0,4],[1.2,-20,0,8]],
    LElbow:[[0,-100,0,0],[.25,-112,0,0],[.45,-6,0,0],[.6,-4,0,0],[1.2,-20,0,0]],
    LWrist:[[0,-20,0,0],[.3,-30,0,0],[.45,40,0,0],[.7,40,0,0],[1.2,0,0,0]],
    LHip:[[0,-14,0,6],[.25,-16,0,6],[.45,-44,0,6],[.7,-40,0,6],[1.2,-16,0,6]],
    RHip:[[0,-14,0,-6],[.25,-16,0,-6],[.45,14,0,-6],[.7,12,0,-6],[1.2,-14,0,-6]],
    LKnee:[[0,26,0,0],[.25,36,0,0],[.45,40,0,0],[1.2,26,0,0]], RKnee:[[0,26,0,0],[.25,36,0,0],[.45,30,0,0],[1.2,26,0,0]],
    Waist:[[0,6,0,0],[.45,18,0,0],[1.2,8,0,0]], Neck:[[0,-10,0,0],[1.2,-8,0,0]],
  },
  root: [[0,0,-.25,0,90,6],[.25,0,-.4,0,90,8],[.45,.6,-.45,0,90,14],[.7,.65,-.35,0,90,8],[1.2,.65,-.25,0,90,4]],
  ball: [[0,'both'],[.45,'both'],[.7,'floorBounce',0,0],[1.0,'passTarget',1,.3],[1.05,'gone']],
  events: [[.45,'PassBounce'],[.45,'ShoeSqueak'],[.7,'Dribble']],
};

// ---------- Signature packages: shot styles, dunk packages, extra dribble moves ----------
// Each player gets one shot style, one dunk package and a set of dribble moves
// (src/shared/AnimSets.lua). Variants are built from the base clips so they share timing rules.
const clone = c => JSON.parse(JSON.stringify(c));
function retime(c, fn){
  for (const j in c.keys) c.keys[j].forEach(k => k[0] = +fn(k[0]).toFixed(3));
  ['root','ball','events'].forEach(f => (c[f] || []).forEach(k => k[0] = +fn(k[0]).toFixed(3)));
  if (c.hoopAt) c.hoopAt[0] = +fn(c.hoopAt[0]).toFixed(3);
  c.len = +fn(c.len).toFixed(3); return c;
}
function nudge(c, j, from, to, d){ (c.keys[j] || []).forEach(k => { if (k[0] >= from && k[0] <= to){ k[1] += d[0]; k[2] += d[1] || 0; k[3] += d[2] || 0; } }); }
function rootNudge(c, from, to, fn){ c.root.forEach(k => { if (k[0] >= from && k[0] <= to){ const d = fn(k[0]); for (let i = 0; i < d.length; i++) k[i+1] += d[i]; } }); }

// Quick release: the dip and set happen 30% faster and the set point is lower (in front of the face).
CLIPS.ShootQuick = retime(clone(CLIPS.Shoot), t => t <= .72 ? t * .7 : t - .216);
nudge(CLIPS.ShootQuick, 'RShoulder', .2, .4, [22]); nudge(CLIPS.ShootQuick, 'LShoulder', .2, .4, [20]);
nudge(CLIPS.ShootQuick, 'RElbow', .2, .4, [10]);
// High release: set point high above the head and a bigger jump.
CLIPS.ShootHigh = clone(CLIPS.Shoot);
nudge(CLIPS.ShootHigh, 'RShoulder', .45, 1.7, [-14]); nudge(CLIPS.ShootHigh, 'LShoulder', .45, 1.4, [-12]);
rootNudge(CLIPS.ShootHigh, .6, .96, t => [0, .3]);
// Fadeaway: drift away from the rim and lean back, front knee kicks up.
CLIPS.ShootFade = clone(CLIPS.Shoot);
rootNudge(CLIPS.ShootFade, .55, 2.6, t => [-Math.min(1, (t - .55) / .5) * .9, 0, 0, 0, t < 1.1 ? -14 : 0]);
nudge(CLIPS.ShootFade, 'LHip', .6, 1.0, [-30]); nudge(CLIPS.ShootFade, 'LKnee', .6, 1.0, [30]);
nudge(CLIPS.ShootFade, 'RShoulder', .5, 1.7, [-8]);
// Set shot: barely leaves the floor, quick push from the forehead.
CLIPS.ShootSet = clone(CLIPS.Shoot);
rootNudge(CLIPS.ShootSet, .55, 1.0, t => [0, -.6]);
nudge(CLIPS.ShootSet, 'LKnee', .25, .35, [-20]); nudge(CLIPS.ShootSet, 'RKnee', .25, .35, [-20]);
rootNudge(CLIPS.ShootSet, .25, .35, t => [0, .2]);

// Two-hand dunk: the left arm mirrors the right and both hands hold the ball to the rim.
CLIPS.DunkTwoHand = clone(CLIPS.Dunk);
CLIPS.DunkTwoHand.keys.LShoulder = CLIPS.Dunk.keys.RShoulder.map(k => [k[0], k[1], -k[2], -k[3]]);
CLIPS.DunkTwoHand.keys.LElbow = CLIPS.Dunk.keys.RElbow.map(k => [...k]);
CLIPS.DunkTwoHand.ball = [[0,'R'],[.6,'R'],[.62,'both'],[1.12,'both'],[1.2,'net',0,0],[1.5,'floorUnderRim',2,0],[1.8,'bounceUnderRim',1,0],[2.1,'floorUnderRim2',2,0],[2.6,'gone']];
// Tomahawk: the ball is cocked far behind the head at the top, then hammered down.
CLIPS.DunkTomahawk = clone(CLIPS.Dunk);
CLIPS.DunkTomahawk.keys.RShoulder = [[0,-30,0,-10],[.4,-40,0,-10],[.62,-70,0,-8],[.82,-160,0,-4],[.98,-205,0,-2],[1.04,-208,0,0],[1.12,-140,0,0],[1.35,-172,0,0],[1.6,-170,0,0],[1.78,-60,0,-10],[2.2,-80,0,-60],[2.6,-82,0,-62]];
CLIPS.DunkTomahawk.keys.RElbow = [[0,-40,0,0],[.62,-70,0,0],[.82,-60,0,0],[1.02,-110,0,0],[1.12,-10,0,0],[1.35,-5,0,0],[1.78,-40,0,0],[2.2,-120,0,0],[2.6,-125,0,0]];
CLIPS.DunkTomahawk.keys.Waist = [[0,0,0,0],[.98,-14,0,0],[1.12,16,0,0],[1.6,0,0,0]];
// Windmill: the ball swings down past the hip, back and all the way over before the slam.
CLIPS.DunkWindmill = clone(CLIPS.Dunk);
CLIPS.DunkWindmill.keys.RShoulder = [[0,-30,0,-10],[.4,-40,0,-10],[.62,-70,0,-8],[.8,-40,0,-12],[.88,20,0,-14],[.95,80,0,-10],[1.03,160,0,-4],[1.12,215,0,0],[1.35,188,0,0],[1.6,190,0,0],[1.78,300,0,-10],[2.2,280,0,-60],[2.6,278,0,-62]];
CLIPS.DunkWindmill.keys.RElbow = [[0,-40,0,0],[.62,-70,0,0],[.8,-10,0,0],[1.12,-8,0,0],[1.35,-5,0,0],[1.78,-40,0,0],[2.2,-120,0,0],[2.6,-125,0,0]];
// 360: a full turn in the air before the slam.
CLIPS.Dunk360 = clone(CLIPS.Dunk);
CLIPS.Dunk360.root = CLIPS.Dunk360.root.map(k => { const r = [...k]; if (k[0] >= 1.02) r[4] += 360; return r; });
CLIPS.Dunk360.root.splice(CLIPS.Dunk360.root.findIndex(k => k[0] === 1.02), 0, [.92,1.05,1.6,0,250,2]);
CLIPS.Dunk360.keys.RShoulder = [[0,-30,0,-10],[.4,-40,0,-10],[.62,-70,0,-8],[.82,-100,0,-10],[.95,-120,0,-14],[1.05,-175,0,-2],[1.12,-130,0,0],[1.35,-172,0,0],[1.6,-170,0,0],[1.78,-60,0,-10],[2.2,-80,0,-60],[2.6,-82,0,-62]];
CLIPS.Dunk360.ball = [[0,'R'],[.6,'R'],[.62,'both'],[.95,'both'],[.97,'R'],[1.12,'R'],[1.2,'net',0,0],[1.5,'floorUnderRim',2,0],[1.8,'bounceUnderRim',1,0],[2.1,'floorUnderRim2',2,0],[2.6,'gone']];

// In-and-out: fake the crossover with the hand rolling over the ball, then push it back out.
CLIPS.InAndOut = withBase(Object.assign({ len: .8,
  keys: {
    RShoulder:[[0,-34,0,-20],[.15,-26,0,2],[.28,-30,0,-4],[.45,-22,0,-24],[.6,-24,0,-22],[.8,-34,0,-20]],
    RElbow:[[0,-75,0,0],[.15,-50,0,0],[.28,-55,0,0],[.45,-38,0,0],[.6,-42,0,0],[.8,-75,0,0]],
    RWrist:[[0,-25,0,0],[.15,10,-40,0],[.28,30,-50,0],[.45,40,10,0],[.6,5,0,0],[.8,-25,0,0]],
    Waist:[[0,20,-6,0],[.2,22,10,0],[.45,24,-12,0],[.8,20,-6,0]],
    Neck:[[0,-24,0,0],[.2,-24,14,0],[.45,-24,-6,0],[.8,-24,0,0]],
  },
  root: [[0,0,-.9,0,0,6],[.2,.25,-.98,0,8,8],[.45,-.2,-1.0,.15,-6,10],[.8,0,-.9,0,0,6]],
  ball: [[0,'R'],[.2,'floorR',2,0],[.32,'R',1,0],[.55,'floorRFar',2,0],[.8,'R',1,0]],
  events: [[.2,'Dribble'],[.45,'ShoeSqueak'],[.55,'Dribble']],
}, DRIBBLE_CAM));
// Spin move: plant the left foot, pull the ball tight and turn all the way round.
CLIPS.Spin = withBase(Object.assign({ len: 1.0,
  keys: {
    RShoulder:[[0,-34,0,-20],[.15,-50,0,-10],[.3,-60,0,-6],[.65,-60,0,-6],[.85,-40,0,-20],[1.0,-34,0,-20]],
    RElbow:[[0,-75,0,0],[.15,-100,0,0],[.65,-100,0,0],[.85,-60,0,0],[1.0,-75,0,0]],
    LShoulder:[[0,-62,0,24],[.3,-40,0,50],[.65,-40,0,50],[1.0,-62,0,24]],
    LHip:[[0,-40,0,14],[.2,-50,0,10],[.65,-30,0,20],[1.0,-40,0,14]],
    RHip:[[0,-36,0,-14],[.3,-10,0,-30],[.65,-50,0,-20],[1.0,-36,0,-14]],
    Waist:[[0,20,-6,0],[.2,24,-20,0],[.6,20,10,0],[1.0,20,-6,0]],
  },
  root: [[0,0,-.9,0,0,6],[.2,.2,-1.0,.1,-30,8],[.45,.5,-.95,.2,-200,6],[.7,.8,-.95,.1,-330,8],[1.0,.9,-.9,0,-360,6]],
  ball: [[0,'R'],[.15,'floorR',2,0],[.3,'R',1,0],[.75,'R'],[.9,'floorR',2,0],[1.0,'R',1,0]],
  events: [[.15,'Dribble'],[.2,'ShoeSqueak'],[.7,'ShoeSqueak'],[.9,'Dribble']],
}, DRIBBLE_CAM));
// Step-back: hard dribble forward, then hop back into space and gather.
CLIPS.Stepback = withBase(Object.assign({ len: 1.0,
  keys: {
    RShoulder:[[0,-34,0,-20],[.15,-20,0,-17],[.3,-24,0,-17],[.55,-40,0,-18],[.75,-36,0,-20],[1.0,-34,0,-20]],
    RElbow:[[0,-75,0,0],[.15,-38,0,0],[.3,-45,0,0],[.55,-80,0,0],[1.0,-75,0,0]],
    RWrist:[[0,-25,0,0],[.13,42,0,0],[.3,5,0,0],[.55,-25,0,0],[1.0,-25,0,0]],
    LHip:[[0,-40,0,14],[.3,-60,0,14],[.5,-20,0,14],[.75,-46,0,14],[1.0,-40,0,14]],
    RHip:[[0,-36,0,-14],[.3,-20,0,-14],[.5,-10,0,-14],[.75,-44,0,-14],[1.0,-36,0,-14]],
    LKnee:[[0,62,0,0],[.3,75,0,0],[.5,40,0,0],[.75,72,0,0],[1.0,62,0,0]],
    RKnee:[[0,60,0,0],[.3,50,0,0],[.5,50,0,0],[.75,70,0,0],[1.0,60,0,0]],
  },
  root: [[0,0,-.9,0,0,6],[.3,0,-1.0,.5,0,14],[.5,0,-.55,-.2,0,-6],[.75,0,-1.0,-.7,0,6],[1.0,0,-.9,-.7,0,6]],
  ball: [[0,'R'],[.15,'floorR',2,0],[.3,'R',1,0],[.55,'R'],[.62,'both'],[1.0,'both']],
  events: [[.15,'Dribble'],[.3,'ShoeSqueak'],[.75,'ShoeSqueak']],
}, DRIBBLE_CAM));

window.WALKOUT_CLIPS = CLIPS;
const ACTIONS = { shoot:'Shoot', dunk:'Dunk', dribble:'Dribble', block:'Block' };

// Foot plant: flat on the floor when the ankle is low, toes pointed when it is in the air.
// Same formula as AnimPlayer.lua so the page and the game agree.
function footAngle(lean, hip, knee, rootY){
  const R = Math.PI/180, a1 = (lean + hip)*R, a2 = a1 + knee*R;
  const y = RIG.hipH + rootY - 1.1*Math.cos(a1) - 1.0*Math.cos(a2);
  const air = Math.min(1, Math.max(0, (y - .55) / .5));
  return -(lean + hip + knee)*(1-air) + 30*air;
}
// ---------------- Catmull-Rom interpolation ----------------
function sampleKeys(keys, t, n){
  if (t <= keys[0][0]) return keys[0].slice(1, 1+n);
  const last = keys[keys.length-1]; if (t >= last[0]) return last.slice(1, 1+n);
  let i = 0; while (keys[i+1][0] < t) i++;
  const k0 = keys[Math.max(0,i-1)], k1 = keys[i], k2 = keys[i+1], k3 = keys[Math.min(keys.length-1,i+2)];
  const u = (t - k1[0]) / (k2[0] - k1[0]);
  const out = [];
  for (let c = 1; c <= n; c++){
    const p0=k0[c], p1=k1[c], p2=k2[c], p3=k3[c];
    // tangents scaled by segment time so uneven spacing does not overshoot
    const d1 = k2[0]-k1[0];
    const m1 = (p2 - p0) / Math.max(1e-3, k2[0]-k0[0]) * d1 * 0.9;
    const m2 = (p3 - p1) / Math.max(1e-3, k3[0]-k1[0]) * d1 * 0.9;
    const u2=u*u, u3=u2*u;
    out.push((2*u3-3*u2+1)*p1 + (u3-2*u2+u)*m1 + (-2*u3+3*u2)*p2 + (u3-u2)*m2);
  }
  return out;
}

// ---------------- Model ----------------
function makeModel(){
  const group = new T.Group(), joints = {}, meshes = [];
  for (const [name, parent, off] of RIG.joints){
    const j = new T.Group(); j.name = name; j.position.set(off[0], off[1], off[2]);
    (parent ? joints[parent] : group).add(j); joints[name] = j;
  }
  joints.Root.position.y = RIG.hipH;
  const geoCache = {};
  for (const [name, joint, size, c, slot, rot] of RIG.parts){
    const key = size.join(','); const g = geoCache[key] || (geoCache[key] = roundedBox(size[0], size[1], size[2], Math.min(size[0],size[1],size[2])*0.18));
    const m = new T.Mesh(g, new T.MeshBasicMaterial({ color: 0x000000 })); m.renderOrder = 10; m.material.transparent = true;
    m.position.set(c[0], c[1], c[2]); m.userData.slot = slot; m.name = name;
    if (rot) m.rotation.set(rot[0]*Math.PI/180, rot[1]*Math.PI/180, rot[2]*Math.PI/180);
    // glow shell for the silhouette rim light
    const shell = new T.Mesh(g, new T.MeshBasicMaterial({ color: 0xffffff, side: T.BackSide, transparent: true, opacity: .95 }));
    shell.scale.setScalar(1.09); shell.userData.shell = true; m.add(shell);
    joints[joint].add(m); meshes.push(m);
  }
  // hand anchors
  const rh = new T.Object3D(); rh.position.set(0,-.3,0); joints.RWrist.add(rh);
  const lh = new T.Object3D(); lh.position.set(0,-.3,0); joints.LWrist.add(lh);
  return { group, joints, meshes, rh, lh };
}
function roundedBox(w,h,d,r){
  // simple bevelled box: a box with slightly rounded look via extruded rounded rect
  const s = new T.Shape(), x=-w/2, y=-h/2;
  s.moveTo(x+r,y); s.lineTo(x+w-r,y); s.quadraticCurveTo(x+w,y,x+w,y+r); s.lineTo(x+w,y+h-r); s.quadraticCurveTo(x+w,y+h,x+w-r,y+h);
  s.lineTo(x+r,y+h); s.quadraticCurveTo(x,y+h,x,y+h-r); s.lineTo(x,y+r); s.quadraticCurveTo(x,y,x+r,y);
  const g = new T.ExtrudeGeometry(s,{ depth: d-2*r*0.6, bevelEnabled: true, bevelThickness: r*0.6, bevelSize: r*0.5, bevelSegments: 2, curveSegments: 3 });
  g.translate(0,0,-(d-2*r*0.6)/2); g.computeVertexNormals(); return g;
}

// ---------------- Scene ----------------
function Walkout(container){
  const W = container.clientWidth || 800, H = container.clientHeight || 450;
  const renderer = new T.WebGLRenderer({ antialias: true, alpha: true, preserveDrawingBuffer: true });
  renderer.setPixelRatio(Math.min(2, window.devicePixelRatio || 1)); renderer.setSize(W, H);
  renderer.domElement.className = 'po-3d'; container.appendChild(renderer.domElement);
  const scene = new T.Scene();
  const cam = new T.PerspectiveCamera(36, W/H, .1, 200);
  const amb = new T.AmbientLight(0xffffff, .0); scene.add(amb);
  const key = new T.DirectionalLight(0xffffff, 0); key.position.set(4, 12, 10); scene.add(key);
  const rim = new T.DirectionalLight(0xffffff, 0); rim.position.set(-6, 8, -6); scene.add(rim);
  // floor
  const floor = new T.Mesh(new T.PlaneGeometry(60, 30), new T.MeshLambertMaterial({ color: 0xA8692F }));
  floor.rotation.x = -Math.PI/2; scene.add(floor);
  const floorDark = new T.Mesh(new T.PlaneGeometry(60, 30), new T.MeshBasicMaterial({ color: 0x05070f, transparent: true, opacity: 1 }));
  floorDark.rotation.x = -Math.PI/2; floorDark.position.y = .01; scene.add(floorDark);
  // tunnel arch behind
  const tunnel = new T.Mesh(new T.CylinderGeometry(3.4, 3.4, .6, 32, 1, false, 0, Math.PI), new T.MeshBasicMaterial({ color: 0x1b2140 }));
  tunnel.rotation.z = Math.PI/2; tunnel.rotation.y = Math.PI/2; tunnel.position.set(0, 4.6, -12); scene.add(tunnel);
  const tunnelHole = new T.Mesh(new T.PlaneGeometry(6, 9.2), new T.MeshBasicMaterial({ color: 0x0b0f22 })); tunnelHole.position.set(0, 4.6, -12.3); scene.add(tunnelHole);
  // spotlight cone (fake volumetric)
  const cone = new T.Mesh(new T.ConeGeometry(5, 18, 32, 1, true), new T.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0, side: T.DoubleSide, depthWrite: false, blending: T.AdditiveBlending }));
  cone.position.set(0, 9, 0); cone.renderOrder = 0; scene.add(cone);
  // hoop
  const hoop = new T.Group();
  const board = new T.Mesh(new T.BoxGeometry(.2, 4.0, 7), new T.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: .25 }));
  board.position.set(1.9, 1.1, 0); hoop.add(board);
  const boardEdge = new T.LineSegments(new T.EdgesGeometry(new T.BoxGeometry(.2, 4.0, 7)), new T.LineBasicMaterial({ color: 0x8a94bf })); boardEdge.position.copy(board.position); hoop.add(boardEdge);
  const ring = new T.Mesh(new T.TorusGeometry(1.15, .09, 8, 28), new T.MeshBasicMaterial({ color: 0xFF7A1A })); ring.rotation.x = Math.PI/2; hoop.add(ring);
  const net = new T.Mesh(new T.CylinderGeometry(1.15, .7, 1.6, 14, 1, true), new T.MeshBasicMaterial({ color: 0xdfe6ff, wireframe: true, transparent: true, opacity: .6 }));
  net.position.y = -.8; hoop.add(net);
  const pole = new T.Mesh(new T.BoxGeometry(.4, 8, .4), new T.MeshBasicMaterial({ color: 0x3a4570 })); pole.position.set(3.6, -4, 0); hoop.add(pole);
  const arm = new T.Mesh(new T.BoxGeometry(1.6, .3, .3), new T.MeshBasicMaterial({ color: 0x3a4570 })); arm.position.set(2.8, 0, 0); hoop.add(arm);
  hoop.visible = false;
  // ball
  const ball = new T.Mesh(new T.SphereGeometry(BALL_R, 24, 16), new T.MeshBasicMaterial({ color: 0x000000 }));
  const ballShell = new T.Mesh(new T.SphereGeometry(BALL_R, 16, 12), new T.MeshBasicMaterial({ color: 0xffffff, side: T.BackSide })); ballShell.scale.setScalar(1.12); ball.add(ballShell);
  const model = makeModel(); scene.add(model.group); model.group.add(ball); model.group.add(hoop);
  const tmp = new T.Vector3(), tmp2 = new T.Vector3();
  let clip = null, clipT = 0, clipStart = 0, onSound = ()=>{}, lastT = 0, mode = 'sil', glow = new T.Color('#FF8A1F'), raf = 0, walking = null, hoopPos = new T.Vector3(8, 8, 0);
  let speed = 1, loopClip = false;
  let camFrom = null, camTo = null, camT0 = 0, camDur = 1;

  function setGlow(hex){ glow.set(hex); model.meshes.forEach(m=>m.children.forEach(s=>{ if(s.userData.shell) s.material.color.copy(glow); })); ballShell.material.color.copy(glow); cone.material.color.copy(glow); }
  function setLit(kit){
    mode = 'lit';
    const mats = { jersey: new T.MeshLambertMaterial({ color: kit.jersey }), shorts: new T.MeshLambertMaterial({ color: kit.shorts }), skin: new T.MeshLambertMaterial({ color: kit.skin }), shoe: new T.MeshLambertMaterial({ color: kit.shoe }) };
    model.meshes.forEach(m=>{ m.material = mats[m.userData.slot]; m.children.forEach(s=>{ if(s.userData.shell){ s.material.color.set(0x000000); s.scale.setScalar(1.04); } }); });
    // face on the front of the head
    if (kit.faceCanvas){
      const tex = new T.CanvasTexture(kit.faceCanvas);
      const face = new T.Mesh(new T.PlaneGeometry(.92, .92), new T.MeshBasicMaterial({ map: tex, transparent: true }));
      face.position.set(0, 0, .5); model.meshes.find(m=>m.name==='Head').add(face);
    }
    // number on the jersey
    if (kit.numberCanvas){
      const t2 = new T.CanvasTexture(kit.numberCanvas);
      const num = new T.Mesh(new T.PlaneGeometry(1.1, .8), new T.MeshBasicMaterial({ map: t2, transparent: true }));
      num.position.set(0, 0, .41); model.meshes.find(m=>m.name==='UpperTorso').add(num);
    }
    ball.material = new T.MeshLambertMaterial({ color: 0xE8641A }); ballShell.material.color.set(0x000000); ballShell.scale.setScalar(1.05);
    amb.intensity = .75; key.intensity = .9; rim.intensity = .6; floorDark.material.opacity = .55;
  }
  function reset(){
    mode = 'sil'; model.group.parent || scene.add(model.group);
    model.meshes.forEach(m=>{ m.material = new T.MeshBasicMaterial({ color: 0x000000 }); m.children.slice().forEach(c=>{ if(!c.userData.shell) m.remove(c); else { c.scale.setScalar(1.09); } }); });
    ball.material = new T.MeshBasicMaterial({ color: 0x000000 });
    amb.intensity = 0; key.intensity = 0; rim.intensity = 0; floorDark.material.opacity = 1; cone.material.opacity = 0;
    hoop.visible = false; ball.visible = false; clip = null; walking = null;
    model.group.position.set(0, 0, -11); model.group.rotation.set(0, 0, 0);
    cam.position.set(0, 4.4, 15); cam.lookAt(0, 3.8, 0); camFrom = camTo = null;
    applyPose('Walk', 0);
  }
  function applyPose(name, t){
    const c = CLIPS[name];
    for (const jn in model.joints){ if (jn !== 'Root') model.joints[jn].rotation.set(0,0,0); }
    for (const jn in c.keys){
      const v = sampleKeys(c.keys[jn], t, 3), j = model.joints[jn];
      j.rotation.set(v[0]*Math.PI/180, v[1]*Math.PI/180, v[2]*Math.PI/180, 'YXZ');
    }
    const r = c.root ? sampleKeys(c.root, t, 5) : [0,0,0,0,0];
    model.joints.Root.position.set(r[0], RIG.hipH + r[1], r[2]);
    model.joints.Root.rotation.set(r[4]*Math.PI/180, r[3]*Math.PI/180, 0, 'YXZ');
    model.group.updateMatrixWorld(true);
    footPlant(c, r[4]);
  }
  // Feet: when a clip has no ankle keys, a foot near the floor stays flat on it and a foot in the
  // air points its toes. AnimPlayer.lua does the same, so clips never need ankle keys by hand.
  function footPlant(c, lean){
    const rootY = model.joints.Root.position.y - RIG.hipH, D = 180/Math.PI;
    for (const side of ['R','L']){
      if (c.keys[side+'Ankle']) continue;
      const hip = model.joints[side+'Hip'].rotation.x*D, knee = model.joints[side+'Knee'].rotation.x*D;
      const a = model.joints[side+'Ankle'];
      a.rotation.set(footAngle(lean, hip, knee, rootY)/D, 0, 0);
    }
    model.group.updateMatrixWorld(true);
  }

  // Everything below is in the model group's local space (the clip's own frame).
  const loc = o => model.group.worldToLocal(o.getWorldPosition(new T.Vector3()));
  function handPos(which){
    if (which === 'both'){ const a = loc(model.rh), b = loc(model.lh); a.add(b).multiplyScalar(.5);
      const f = new T.Vector3(0,0,.35).applyQuaternion(model.joints.Root.quaternion); return a.add(f); }
    if (which === 'RTip') return loc(model.rh).add(new T.Vector3(0,BALL_R+.02,0));
    if (which === 'LTip') return loc(model.lh).add(new T.Vector3(0,BALL_R+.02,0));
    return loc(which === 'L' ? model.lh : model.rh).add(new T.Vector3(0,-(BALL_R-.05),0));
  }
  function spotFor(where, c){
    // world position of a ball key target at the time it is sampled
    if (where === 'R' || where === 'L' || where === 'both' || where === 'RTip' || where === 'LTip') return handPos(where);
    const rootW = model.joints.Root.position.clone();
    const q = new T.Quaternion().setFromEuler(new T.Euler(0, model.joints.Root.rotation.y, 0));
    const loc = (x,y,z)=> new T.Vector3(x,0,z).applyQuaternion(q).add(new T.Vector3(rootW.x, 0, rootW.z)).setY(y);
    if (where === 'floorR') return loc(-1.2, BALL_R, 1.1);
    if (where === 'floorL') return loc(1.2, BALL_R, 1.1);
    if (where === 'floorMid') return loc(0, BALL_R, 1.25);
    if (where === 'floorBetween') return loc(0, BALL_R, .1);
    if (where === 'floorBehind') return loc(0, BALL_R, -1.1);
    if (where === 'floorRFar') return loc(-1.7, BALL_R, 1.6);
    if (where === 'floorBounce') return loc(0, BALL_R, 5.5);
    if (where === 'rim') return hoopPos.clone().add(new T.Vector3(0,.6,0));
    if (where === 'net') return hoopPos.clone().add(new T.Vector3(0,-1.3,0));
    if (where === 'floorUnderRim') return new T.Vector3(hoopPos.x-.6, BALL_R, hoopPos.z+.6);
    if (where === 'bounceUnderRim') return new T.Vector3(hoopPos.x-1.4, 2.4, hoopPos.z+1.0);
    if (where === 'floorUnderRim2') return new T.Vector3(hoopPos.x-2.2, BALL_R, hoopPos.z+1.4);
    if (where === 'shotStart') return new T.Vector3(rootW.x + 9, 5.5, rootW.z + 1);
    if (where === 'passTarget') return loc(0, 3.4, 11);
    if (where === 'reboundIn') return new T.Vector3(rootW.x + 6, 11, rootW.z - 2);
    if (where === 'swatAway') return new T.Vector3(rootW.x - 9, 9.5, rootW.z + 3);
    return null;
  }
  function placeHoop(c){
    if (c.hoopAt){ const o = c.hoopOff || [.25, -.15]; applyPose(c.name, c.hoopAt[0]); hoopPos.copy(handPos(c.hoopAt[1])).add(new T.Vector3(o[0], o[1], 0)); }
    else if (c.shotHoop){ hoopPos.set(7.5, 7.8, 0); }
    hoop.position.copy(hoopPos); hoop.visible = !!(c.hoopAt || c.shotHoop);
    model.group.rotation.y = (c.view || 0) * Math.PI/180;
  }
  function ballAt(c, t){
    const ks = c.ball; if (!ks) { ball.visible = false; return; }
    let i = 0; while (i < ks.length-1 && ks[i+1][0] <= t) i++;
    const k0 = ks[i], k1 = ks[Math.min(i+1, ks.length-1)];
    if (k0[1] === 'gone' || (k0 === k1 && k0[1] === 'gone')) { ball.visible = false; return; }
    ball.visible = true;
    const held = ['R','L','both','RTip','LTip'];
    if (k0 === k1 || (k0[1] === k1[1] && held.includes(k0[1]))) { ball.position.copy(spotFor(k0[1], c)); return; }
    if (k1[1] === 'gone') { ball.position.copy(spotFor(k0[1], c) || ball.position); return; }
    // between two different spots: sample both ends at their own times
    const tNow = t; applyPose(c.name, k0[0]); const a = spotFor(k0[1], c); applyPose(c.name, k1[0]); const b = spotFor(k1[1], c); applyPose(c.name, tNow);
    let u = (t - k0[0]) / (k1[0] - k0[0]); const ease = k1[2] || 0;
    if (ease === 2) u = u*u; else if (ease === 1) u = 1-(1-u)*(1-u);
    const p = a.clone().lerp(b, u); const arc = k1[3] || 0; p.y += arc * 4 * u * (1-u);
    ball.position.copy(p);
  }
  function fireEvents(c, t0, t1){
    (c.events||[]).forEach(e=>{ if (e[0] >= t0 && e[0] < t1) onSound(e[1]); });
  }
  function frame(now){
    raf = requestAnimationFrame(frame);
    const t = (now - clipStart) / 1000 * speed;
    if (walking){
      const w = walking, u = Math.min(1, t / w.dur);
      const z = w.z0 + (w.z1 - w.z0) * (u < 1 ? u : 1);
      applyPose('Walk', (t % 1));
      model.group.position.set(0, 0, z); model.group.rotation.y = 0;
      if (u >= 1 && !w.done){ w.done = true; applyPose('Walk', 0); w.resolve(); }
      if (w.done){ applyPose('Pose', 0); }
    } else if (clip && (clip.loop || loopClip) && !clip.hold){
      const tt = t % clip.len;
      if (tt + 1e-6 < lastT){ fireEvents(clip, lastT, clip.len + 1); lastT = 0; }
      applyPose(clip.name, tt); ballAt(clip, tt); fireEvents(clip, lastT, tt + 1e-6); lastT = tt + 1e-6;
      if (!clip.done){ clip.done = true; clip.resolve && clip.resolve(); }
    } else if (clip){
      const tt = Math.min(t, clip.len);
      applyPose(clip.name, tt); ballAt(clip, tt); fireEvents(clip, lastT, t <= clip.len ? tt + 1e-6 : clip.len + 1);
      lastT = tt + 1e-6;
      if (t >= clip.len && !clip.done){ clip.done = true; clip.resolve && clip.resolve(); }
    }
    if (camTo){ const u = Math.min(1, (now - camT0) / (camDur*1000)), e = u<.5?2*u*u:1-Math.pow(-2*u+2,2)/2;
      cam.position.lerpVectors(camFrom.p, camTo.p, e); const look = camFrom.l.clone().lerp(camTo.l, e); cam.lookAt(look); }
    renderer.render(scene, cam);
  }
  function moveCam(p, l, dur){ const cur = new T.Vector3(); cam.getWorldDirection(cur); camFrom = { p: cam.position.clone(), l: cam.position.clone().add(cur.multiplyScalar(18)) }; camTo = { p: new T.Vector3(...p), l: new T.Vector3(...l) }; camT0 = performance.now(); camDur = dur; }
  function play(name){
    const c = Object.assign({ name }, CLIPS[name]); placeHoop(c); applyPose(name, 0);
    if (c.cam) moveCam(c.cam[0], c.cam[1], .8);
    return new Promise(res=>{ c.resolve = res; clip = c; walking = null; clipStart = performance.now(); lastT = 0; });
  }
  function walkIn(dur){
    return new Promise(res=>{ walking = { z0: -11, z1: 0, dur, resolve: res }; clip = null; clipStart = performance.now(); });
  }
  reset(); raf = requestAnimationFrame(frame);
  return {
    reset, setGlow, setLit, play, walkIn, moveCam,
    setSpeed(s){ const now = performance.now(), cur = (now - clipStart) / 1000 * speed; speed = s; clipStart = now - cur * 1000 / s; },
    setLoop(on){ loopClip = !!on; },
    spot(on){ cone.material.opacity = on ? .07 : 0; },
    onSound(fn){ onSound = fn; },
    resize(){ const w = container.clientWidth, h = container.clientHeight; renderer.setSize(w, h); cam.aspect = w/h; cam.updateProjectionMatrix(); },
    stop(){ cancelAnimationFrame(raf); },
    // jump to a point (used by tests and skip)
    seek(name, t){ const c = Object.assign({ name }, CLIPS[name]); placeHoop(c); if (c.cam){ camTo = null; cam.position.set(...c.cam[0]); cam.lookAt(...c.cam[1]); } clip = c; walking = null; clipStart = performance.now() - t*1000/speed; lastT = t; c.done = true; model.group.position.set(0,0,0); },
    canvas: renderer.domElement,
  };
}
window.Walkout3D = { create: Walkout, ACTIONS, CLIPS, RIG };
})();
