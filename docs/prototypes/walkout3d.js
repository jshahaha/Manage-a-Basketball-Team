// Walkout cutscene in 3D: the same blocky R15-style player model and the same
// keyframe clips the game uses (src/shared/AnimClips.lua is generated from CLIPS).
// Sounds are fired from clip events on the animation clock, so they stay in sync.
(function(){
const T = window.THREE;
// ---------------- Rig (studs, Y up, facing +Z) ----------------
const RIG = {
  hipH: 2.45,
  parts: [
    // name, parent joint, box size [w,h,d], center offset from joint, material slot
    ['LowerTorso','Root',[2,0.55,1],[0,0.27,0],'shorts'],
    ['UpperTorso','Waist',[2,1.6,1],[0,0.8,0],'jersey'],
    ['Head','Neck',[1.15,1.2,1.15],[0,0.62,0],'skin'],
    ['RUpperArm','RShoulder',[0.85,1.1,0.85],[0,-0.45,0],'skin'],
    ['RLowerArm','RElbow',[0.78,0.95,0.78],[0,-0.42,0],'skin'],
    ['RHand','RElbow',[0.7,0.35,0.7],[0,-1.02,0],'skin'],
    ['LUpperArm','LShoulder',[0.85,1.1,0.85],[0,-0.45,0],'skin'],
    ['LLowerArm','LElbow',[0.78,0.95,0.78],[0,-0.42,0],'skin'],
    ['LHand','LElbow',[0.7,0.35,0.7],[0,-1.02,0],'skin'],
    ['RUpperLeg','RHip',[0.95,1.15,0.95],[0,-0.55,0],'shorts'],
    ['RLowerLeg','RKnee',[0.88,1.0,0.88],[0,-0.5,0],'skin'],
    ['RFoot','RKnee',[0.9,0.35,1.35],[0,-1.17,0.2],'shoe'],
    ['LUpperLeg','LHip',[0.95,1.15,0.95],[0,-0.55,0],'shorts'],
    ['LLowerLeg','LKnee',[0.88,1.0,0.88],[0,-0.5,0],'skin'],
    ['LFoot','LKnee',[0.9,0.35,1.35],[0,-1.17,0.2],'shoe'],
  ],
  // joint, parent, offset from parent joint
  joints: [['Root',null,[0,0,0]],['Waist','Root',[0,0.55,0]],['Neck','Waist',[0,1.6,0]],
    ['RShoulder','Waist',[-1.42,1.42,0]],['RElbow','RShoulder',[0,-1.0,0]],
    ['LShoulder','Waist',[1.42,1.42,0]],['LElbow','LShoulder',[0,-1.0,0]],
    ['RHip','Root',[-0.5,0,0]],['RKnee','RHip',[0,-1.1,0]],
    ['LHip','Root',[0.5,0,0]],['LKnee','LHip',[0,-1.1,0]]],
};
// ---------------- Clips ----------------
// Joint keys: [t, rx, ry, rz] in degrees. Raising an arm forward is negative X.
// Hip forward is negative X, knee bend is positive X, elbow bend is negative X.
// Root keys: [t, x, y, z, yaw, lean]. Ball keys: [t, where, ease, arc]. Events: [t, sound].
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
  Shoot: { len: 2.3, face: 90, view: -30, cam: [[3.5,5.6,21],[3.2,5.0,0]],
    keys: {
      RShoulder:[[0,-55,0,-8],[.35,-60,0,-8],[.62,-150,0,-4],[.78,-172,0,-2],[1.0,-170,0,-2],[1.5,-150,0,-4],[2.3,-20,0,-6]],
      RElbow:[[0,-85,0,0],[.35,-95,0,0],[.62,-95,0,0],[.78,-8,0,0],[1.5,-10,0,0],[2.3,-15,0,0]],
      LShoulder:[[0,-55,0,8],[.35,-60,0,8],[.62,-140,0,14],[.78,-145,0,20],[1.1,-110,0,22],[2.3,-15,0,6]],
      LElbow:[[0,-85,0,0],[.35,-95,0,0],[.62,-80,0,0],[.78,-40,0,0],[2.3,-15,0,0]],
      LHip:[[0,-6,0,0],[.35,-40,0,0],[.62,-4,0,0],[1.0,-14,0,0],[1.32,-38,0,0],[1.7,-8,0,0],[2.3,-4,0,0]],
      RHip:[[0,-6,0,0],[.35,-40,0,0],[.62,-4,0,0],[1.0,-10,0,0],[1.32,-34,0,0],[1.7,-8,0,0],[2.3,-4,0,0]],
      LKnee:[[0,10,0,0],[.35,70,0,0],[.62,4,0,0],[1.0,20,0,0],[1.32,62,0,0],[1.7,10,0,0],[2.3,6,0,0]],
      RKnee:[[0,10,0,0],[.35,66,0,0],[.62,4,0,0],[1.0,16,0,0],[1.32,58,0,0],[1.7,10,0,0],[2.3,6,0,0]],
      Neck:[[0,-8,0,0],[.62,-14,0,0],[1.0,-14,0,0],[2.3,0,0,0]],
    },
    root: [[0,0,0,0,90,4],[.35,0,-.55,0,90,10],[.62,0,.35,0,90,0],[.8,0,1.15,0,90,-2],[1.0,0,1.05,0,90,-2],[1.25,0,.1,0,90,4],[1.32,0,-.45,0,90,8],[1.7,0,0,0,90,2],[2.3,0,0,0,90,0]],
    ball: [[0,'both'],[.78,'both'],[1.5,'rim',0,4.2],[1.62,'net',0,0],[1.9,'floorUnderRim',2,0],[2.3,'gone']],
    events: [[.35,'ShoeSqueak'],[1.5,'CrowdCheerM'],[1.33,'ShoeSqueak']],
  },
  Dunk: { len: 2.6, face: 90, view: -30, cam: [[3.5,5.6,21],[3.2,5.0,0]],
    keys: {
      LHip:[[0,-30,0,0],[.2,26,0,0],[.4,-34,0,0],[.6,-45,0,0],[.82,-10,0,0],[1.05,-70,0,0],[1.35,-40,0,0],[1.78,-36,0,0],[2.2,-6,0,0],[2.6,-4,0,0]],
      RHip:[[0,26,0,0],[.2,-34,0,0],[.4,24,0,0],[.6,-30,0,0],[.82,-4,0,0],[1.05,-10,0,0],[1.35,-30,0,0],[1.78,-34,0,0],[2.2,-6,0,0],[2.6,-4,0,0]],
      LKnee:[[0,20,0,0],[.2,50,0,0],[.4,20,0,0],[.6,72,0,0],[.82,6,0,0],[1.05,95,0,0],[1.35,40,0,0],[1.78,64,0,0],[2.2,10,0,0],[2.6,6,0,0]],
      RKnee:[[0,50,0,0],[.2,20,0,0],[.4,50,0,0],[.6,62,0,0],[.82,4,0,0],[1.05,30,0,0],[1.35,30,0,0],[1.78,58,0,0],[2.2,10,0,0],[2.6,6,0,0]],
      RShoulder:[[0,-30,0,-10],[.4,-40,0,-10],[.6,-70,0,-8],[.82,-150,0,-4],[1.02,-178,0,0],[1.14,-120,0,0],[1.35,-172,0,0],[1.6,-170,0,0],[1.78,-60,0,-10],[2.2,-80,0,-60],[2.6,-82,0,-62]],
      RElbow:[[0,-40,0,0],[.6,-70,0,0],[.82,-30,0,0],[1.02,-10,0,0],[1.14,-20,0,0],[1.35,-5,0,0],[1.78,-40,0,0],[2.2,-120,0,0],[2.6,-125,0,0]],
      LShoulder:[[0,20,0,8],[.4,-30,0,10],[.6,-70,0,10],[.82,-110,0,14],[1.02,-90,0,30],[1.35,-70,0,40],[1.78,-50,0,20],[2.2,-80,0,60],[2.6,-82,0,62]],
      LElbow:[[0,-30,0,0],[.6,-70,0,0],[1.02,-20,0,0],[1.78,-30,0,0],[2.2,-120,0,0],[2.6,-125,0,0]],
      Neck:[[0,-6,0,0],[.82,-20,0,0],[1.14,10,0,0],[1.78,0,0,0],[2.2,-10,0,0]],
    },
    root: [[0,-2.6,0,0,90,14],[.2,-1.9,.15,0,90,14],[.4,-1.1,0,0,90,14],[.6,-.4,-.45,0,90,16],[.82,.5,.6,0,90,6],[1.02,1.6,2.05,0,90,-4],[1.14,1.9,1.95,0,90,6],[1.35,2.0,1.9,0,90,0],[1.6,2.05,1.7,0,90,0],[1.78,2.15,-.35,0,90,10],[2.2,2.15,0,0,60,0],[2.6,2.15,0,0,30,0]],
    ball: [[0,'R'],[.6,'R'],[.62,'both'],[.82,'both'],[.84,'R'],[1.12,'R'],[1.2,'net',0,0],[1.5,'floorUnderRim',2,0],[1.8,'bounceUnderRim',1,0],[2.1,'floorUnderRim2',2,0],[2.6,'gone']],
    hoopAt: [1.12, 'R'], // the rim is placed where the right hand is at the slam
    events: [[.0,'ShoeSqueak'],[.4,'ShoeSqueak'],[.6,'ShoeSqueak'],[1.13,'RimOut'],[1.18,'CrowdCheerL'],[1.5,'Dribble'],[1.79,'ShoeSqueak'],[2.1,'Dribble']],
  },
  Dribble: { len: 2.4, face: 0, view: -28, cam: [[1.2,3.4,12.5],[0,2.7,0]],
    keys: {
      LHip:[[0,-34,0,10],[2.4,-34,0,10]], RHip:[[0,-34,0,-10],[2.4,-34,0,-10]],
      LKnee:[[0,58,0,0],[2.4,58,0,0]], RKnee:[[0,58,0,0],[2.4,58,0,0]],
      Waist:[[0,18,-8,0],[.8,18,6,0],[1.2,18,12,0],[2.0,18,-4,0],[2.4,18,-8,0]],
      RShoulder:[[0,-38,0,-14],[.2,-18,0,-12],[.4,-38,0,-14],[.6,-18,0,-12],[.8,-30,0,10],[1.2,-8,0,-8],[1.6,-8,0,-8],[2.0,-30,0,-14],[2.2,-18,0,-12],[2.4,-38,0,-14]],
      RElbow:[[0,-62,0,0],[.2,-22,0,0],[.4,-62,0,0],[.6,-22,0,0],[.8,-30,0,0],[1.2,-20,0,0],[2.0,-62,0,0],[2.2,-22,0,0],[2.4,-62,0,0]],
      LShoulder:[[0,-8,0,8],[.8,-10,0,8],[1.0,-38,0,14],[1.2,-38,0,14],[1.4,-18,0,12],[1.6,-38,0,14],[1.8,-18,0,12],[2.0,-30,0,-10],[2.4,-8,0,8]],
      LElbow:[[0,-20,0,0],[.8,-20,0,0],[1.0,-62,0,0],[1.2,-62,0,0],[1.4,-22,0,0],[1.6,-62,0,0],[1.8,-22,0,0],[2.0,-30,0,0],[2.4,-20,0,0]],
      Neck:[[0,-10,0,0],[2.4,-10,0,0]],
    },
    root: [[0,.25,-.75,0,0,0],[.8,.3,-.8,0,-6,0],[1.0,-.25,-.75,0,8,0],[1.8,-.3,-.8,0,10,0],[2.0,.25,-.75,0,-4,0],[2.4,.25,-.75,0,0,0]],
    ball: [[0,'R'],[.2,'floorR',2,0],[.4,'R',1,0],[.6,'floorR',2,0],[.8,'floorMid',2,0],[1.0,'L',1,0],[1.2,'floorL',2,0],[1.4,'L',1,0],[1.6,'floorL',2,0],[1.8,'floorMid',2,0],[2.0,'R',1,0],[2.2,'floorR',2,0],[2.4,'R',1,0]],
    events: [[.2,'Dribble'],[.6,'Dribble'],[.8,'Dribble'],[1.2,'Dribble'],[1.6,'Dribble'],[1.8,'Dribble'],[2.2,'Dribble'],[.8,'ShoeSqueak'],[1.8,'ShoeSqueak']],
    repeat: 1,
  },
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
    events: [[.36,'ShoeSqueak'],[.76,'Dribble'],[.82,'CrowdOoh'],[1.23,'ShoeSqueak']],
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
};
window.WALKOUT_CLIPS = CLIPS;
const ACTIONS = { shoot:'Shoot', dunk:'Dunk', dribble:'Dribble', block:'Block' };

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
  for (const [name, joint, size, c, slot] of RIG.parts){
    const key = size.join(','); const g = geoCache[key] || (geoCache[key] = roundedBox(size[0], size[1], size[2], Math.min(size[0],size[1],size[2])*0.18));
    const m = new T.Mesh(g, new T.MeshBasicMaterial({ color: 0x000000 })); m.renderOrder = 10; m.material.transparent = true;
    m.position.set(c[0], c[1], c[2]); m.userData.slot = slot; m.name = name;
    // glow shell for the silhouette rim light
    const shell = new T.Mesh(g, new T.MeshBasicMaterial({ color: 0xffffff, side: T.BackSide, transparent: true, opacity: .95 }));
    shell.scale.setScalar(1.09); shell.userData.shell = true; m.add(shell);
    joints[joint].add(m); meshes.push(m);
  }
  // hand anchors
  const rh = new T.Object3D(); rh.position.set(0,-1.15,.15); joints.RElbow.add(rh);
  const lh = new T.Object3D(); lh.position.set(0,-1.15,.15); joints.LElbow.add(lh);
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
  const board = new T.Mesh(new T.BoxGeometry(.2, 3.6, 6), new T.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: .25 }));
  board.position.set(1.5, .9, 0); hoop.add(board);
  const boardEdge = new T.LineSegments(new T.EdgesGeometry(new T.BoxGeometry(.2, 3.6, 6)), new T.LineBasicMaterial({ color: 0x8a94bf })); boardEdge.position.copy(board.position); hoop.add(boardEdge);
  const ring = new T.Mesh(new T.TorusGeometry(.75, .08, 8, 24), new T.MeshBasicMaterial({ color: 0xFF7A1A })); ring.rotation.x = Math.PI/2; hoop.add(ring);
  const net = new T.Mesh(new T.CylinderGeometry(.75, .45, 1.2, 12, 1, true), new T.MeshBasicMaterial({ color: 0xdfe6ff, wireframe: true, transparent: true, opacity: .6 }));
  net.position.y = -.6; hoop.add(net);
  const pole = new T.Mesh(new T.BoxGeometry(.4, 8, .4), new T.MeshBasicMaterial({ color: 0x3a4570 })); pole.position.set(3.2, -4, 0); hoop.add(pole);
  const arm = new T.Mesh(new T.BoxGeometry(1.8, .3, .3), new T.MeshBasicMaterial({ color: 0x3a4570 })); arm.position.set(2.4, 0, 0); hoop.add(arm);
  hoop.visible = false;
  // ball
  const ball = new T.Mesh(new T.SphereGeometry(.42, 20, 14), new T.MeshBasicMaterial({ color: 0x000000 }));
  const ballShell = new T.Mesh(new T.SphereGeometry(.42, 16, 12), new T.MeshBasicMaterial({ color: 0xffffff, side: T.BackSide })); ballShell.scale.setScalar(1.12); ball.add(ballShell);
  const model = makeModel(); scene.add(model.group); model.group.add(ball); model.group.add(hoop);
  const tmp = new T.Vector3(), tmp2 = new T.Vector3();
  let clip = null, clipT = 0, clipStart = 0, onSound = ()=>{}, lastT = 0, mode = 'sil', glow = new T.Color('#FF8A1F'), raf = 0, walking = null, hoopPos = new T.Vector3(8, 8, 0);
  let camFrom = null, camTo = null, camT0 = 0, camDur = 1;

  function setGlow(hex){ glow.set(hex); model.meshes.forEach(m=>m.children.forEach(s=>{ if(s.userData.shell) s.material.color.copy(glow); })); ballShell.material.color.copy(glow); cone.material.color.copy(glow); }
  function setLit(kit){
    mode = 'lit';
    const mats = { jersey: new T.MeshLambertMaterial({ color: kit.jersey }), shorts: new T.MeshLambertMaterial({ color: kit.shorts }), skin: new T.MeshLambertMaterial({ color: kit.skin }), shoe: new T.MeshLambertMaterial({ color: kit.shoe }) };
    model.meshes.forEach(m=>{ m.material = mats[m.userData.slot]; m.children.forEach(s=>{ if(s.userData.shell){ s.material.color.set(0x000000); s.scale.setScalar(1.04); } }); });
    // face on the front of the head
    if (kit.faceCanvas){
      const tex = new T.CanvasTexture(kit.faceCanvas);
      const face = new T.Mesh(new T.PlaneGeometry(1.1, 1.1), new T.MeshBasicMaterial({ map: tex, transparent: true }));
      face.position.set(0, 0, .6); model.meshes.find(m=>m.name==='Head').add(face);
    }
    // number on the jersey
    if (kit.numberCanvas){
      const t2 = new T.CanvasTexture(kit.numberCanvas);
      const num = new T.Mesh(new T.PlaneGeometry(1.4, 1.0), new T.MeshBasicMaterial({ map: t2, transparent: true }));
      num.position.set(0, 0, .52); model.meshes.find(m=>m.name==='UpperTorso').add(num);
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
  }
  // Everything below is in the model group's local space (the clip's own frame).
  const loc = o => model.group.worldToLocal(o.getWorldPosition(new T.Vector3()));
  function handPos(which){
    if (which === 'both'){ const a = loc(model.rh), b = loc(model.lh); a.add(b).multiplyScalar(.5);
      const f = new T.Vector3(0,0,.45).applyQuaternion(model.joints.Root.quaternion); return a.add(f); }
    if (which === 'RTip') return loc(model.rh).add(new T.Vector3(0,.2,0));
    return loc(which === 'L' ? model.lh : model.rh).add(new T.Vector3(0,-.3,0));
  }
  function spotFor(where, c){
    // world position of a ball key target at the time it is sampled
    if (where === 'R' || where === 'L' || where === 'both' || where === 'RTip') return handPos(where);
    const rootW = model.joints.Root.position.clone();
    const q = new T.Quaternion().setFromEuler(new T.Euler(0, model.joints.Root.rotation.y, 0));
    const loc = (x,y,z)=> new T.Vector3(x,0,z).applyQuaternion(q).add(new T.Vector3(rootW.x, 0, rootW.z)).setY(y);
    if (where === 'floorR') return loc(-1.35, .42, 1.0);
    if (where === 'floorL') return loc(1.35, .42, 1.0);
    if (where === 'floorMid') return loc(0, .42, 1.25);
    if (where === 'rim') return hoopPos.clone().add(new T.Vector3(0,.45,0));
    if (where === 'net') return hoopPos.clone().add(new T.Vector3(0,-1.1,0));
    if (where === 'floorUnderRim') return new T.Vector3(hoopPos.x-.6, .42, hoopPos.z+.6);
    if (where === 'bounceUnderRim') return new T.Vector3(hoopPos.x-1.4, 2.4, hoopPos.z+1.0);
    if (where === 'floorUnderRim2') return new T.Vector3(hoopPos.x-2.2, .42, hoopPos.z+1.4);
    if (where === 'shotStart') return new T.Vector3(rootW.x + 9, 5.5, rootW.z + 1);
    if (where === 'swatAway') return new T.Vector3(rootW.x - 9, 9.5, rootW.z + 3);
    return null;
  }
  function placeHoop(c){
    if (c.hoopAt){ applyPose(c.name, c.hoopAt[0]); hoopPos.copy(handPos(c.hoopAt[1])).add(new T.Vector3(.25, -.15, 0)); }
    else if (c.name === 'Shoot'){ hoopPos.set(7.5, 7.8, 0); }
    hoop.position.copy(hoopPos); hoop.visible = (c.name === 'Shoot' || c.name === 'Dunk');
    model.group.rotation.y = (c.view || 0) * Math.PI/180;
  }
  function ballAt(c, t){
    const ks = c.ball; if (!ks) { ball.visible = false; return; }
    let i = 0; while (i < ks.length-1 && ks[i+1][0] <= t) i++;
    const k0 = ks[i], k1 = ks[Math.min(i+1, ks.length-1)];
    if (k0[1] === 'gone' || (k0 === k1 && k0[1] === 'gone')) { ball.visible = false; return; }
    ball.visible = true;
    const held = ['R','L','both','RTip'];
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
    const t = (now - clipStart) / 1000;
    if (walking){
      const w = walking, u = Math.min(1, t / w.dur);
      const z = w.z0 + (w.z1 - w.z0) * (u < 1 ? u : 1);
      applyPose('Walk', (t % 1));
      model.group.position.set(0, 0, z); model.group.rotation.y = 0;
      if (u >= 1 && !w.done){ w.done = true; applyPose('Walk', 0); w.resolve(); }
      if (w.done){ applyPose('Pose', 0); }
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
    spot(on){ cone.material.opacity = on ? .07 : 0; },
    onSound(fn){ onSound = fn; },
    resize(){ const w = container.clientWidth, h = container.clientHeight; renderer.setSize(w, h); cam.aspect = w/h; cam.updateProjectionMatrix(); },
    stop(){ cancelAnimationFrame(raf); },
    // jump to a point (used by tests and skip)
    seek(name, t){ const c = Object.assign({ name }, CLIPS[name]); placeHoop(c); if (c.cam){ camTo = null; cam.position.set(...c.cam[0]); cam.lookAt(...c.cam[1]); } clip = c; walking = null; clipStart = performance.now() - t*1000; lastT = t; c.done = true; model.group.position.set(0,0,0); },
    canvas: renderer.domElement,
  };
}
window.Walkout3D = { create: Walkout, ACTIONS, CLIPS, RIG };
})();
