// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  static const Color _success = Color(0xFF198754);
  static const Color _danger  = Color(0xFFDC3545);
  static const String _viewId = 'posenet-camera-view';

  bool _registered = false;

  static const String _poseHtml = '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { background: #0A0A15; overflow: hidden; font-family: sans-serif; }
  #container { position: relative; width: 100vw; height: 100vh; display: flex; align-items: center; justify-content: center; }
  video  { position: absolute; width: 100%; height: 100%; object-fit: contain; transform: scaleX(-1); }
  canvas { position: absolute; width: 100%; height: 100%; object-fit: contain; transform: scaleX(-1); }
  #status { position: absolute; top: 12px; left: 50%; transform: translateX(-50%);
    background: rgba(0,0,0,0.6); color: white; padding: 6px 14px;
    border-radius: 20px; font-size: 13px; z-index: 10; }
  #score { position: absolute; top: 12px; right: 12px;
    background: rgba(0,0,0,0.6); padding: 6px 12px;
    border-radius: 8px; font-size: 13px; font-weight: bold; z-index: 10; }
  #alert { position: absolute; bottom: 12px; left: 50%; transform: translateX(-50%);
    padding: 8px 20px; border-radius: 20px; font-size: 13px; font-weight: 600;
    z-index: 10; transition: all 0.3s; white-space: nowrap; }
</style>
</head>
<body>
<div id="container">
  <video id="video" autoplay playsinline muted></video>
  <canvas id="canvas"></canvas>
  <div id="status">Cargando modelo de IA...</div>
  <div id="score" style="color:#198754">Postura: --</div>
  <div id="alert" style="background:rgba(25,135,84,0.15);color:#198754;border:1px solid #198754">
    Iniciando detección...
  </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/@tensorflow/tfjs@4.10.0/dist/tf.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/@tensorflow-models/posenet@2.2.2/dist/posenet.min.js"></script>
<script>
const video   = document.getElementById('video');
const canvas  = document.getElementById('canvas');
const ctx     = canvas.getContext('2d');
const status  = document.getElementById('status');
const scoreEl = document.getElementById('score');
const alertEl = document.getElementById('alert');

const CONEXIONES = [
  ['leftEar','leftEye'],['rightEar','rightEye'],
  ['leftEye','nose'],['rightEye','nose'],
  ['leftShoulder','rightShoulder'],
  ['leftShoulder','leftElbow'],['leftElbow','leftWrist'],
  ['rightShoulder','rightElbow'],['rightElbow','rightWrist'],
  ['leftShoulder','leftHip'],['rightShoulder','rightHip'],
  ['leftHip','rightHip'],
  ['leftHip','leftKnee'],['leftKnee','leftAnkle'],
  ['rightHip','rightKnee'],['rightKnee','rightAnkle'],
];

function angulo(a, b, c) {
  const rad = Math.atan2(c.y - b.y, c.x - b.x) - Math.atan2(a.y - b.y, a.x - b.x);
  let deg = Math.abs(rad * 180 / Math.PI);
  if (deg > 180) deg = 360 - deg;
  return deg;
}

function calcularScore(keypoints) {
  const kp = {};
  keypoints.forEach(k => { kp[k.part] = k; });
  let pen = 0;

  if (kp.leftShoulder && kp.rightShoulder &&
      kp.leftShoulder.score > 0.4 && kp.rightShoulder.score > 0.4) {
    const diffY = Math.abs(kp.leftShoulder.position.y - kp.rightShoulder.position.y) / canvas.height;
    if (diffY > 0.05) pen += Math.min(diffY * 200, 30);
  }
  if (kp.nose && kp.leftShoulder && kp.rightShoulder && kp.nose.score > 0.4) {
    const cx    = (kp.leftShoulder.position.x + kp.rightShoulder.position.x) / 2;
    const diffX = Math.abs(kp.nose.position.x - cx) / canvas.width;
    if (diffX > 0.06) pen += Math.min(diffX * 150, 25);
  }
  if (kp.leftEar && kp.leftShoulder && kp.leftHip &&
      kp.leftEar.score > 0.3 && kp.leftShoulder.score > 0.4 && kp.leftHip.score > 0.4) {
    const ang = angulo(kp.leftEar.position, kp.leftShoulder.position, kp.leftHip.position);
    if (ang < 40) pen += Math.min((40 - ang) * 0.8, 20);
    if (ang > 80) pen += Math.min((ang - 80) * 0.5, 15);
  }
  if (kp.leftShoulder && kp.leftHip && kp.leftKnee &&
      kp.leftShoulder.score > 0.4 && kp.leftHip.score > 0.4 && kp.leftKnee.score > 0.3) {
    const ang = angulo(kp.leftShoulder.position, kp.leftHip.position, kp.leftKnee.position);
    if (ang < 150) pen += Math.min((150 - ang) * 0.4, 20);
  }
  return Math.max(0, Math.min(100, 100 - pen));
}

const scoreHistory = [];
function suavizar(v) {
  scoreHistory.push(v);
  if (scoreHistory.length > 12) scoreHistory.shift();
  return scoreHistory.reduce((a, b) => a + b, 0) / scoreHistory.length;
}

function dibujar(keypoints, color) {
  const kp = {};
  keypoints.forEach(k => { kp[k.part] = k; });
  ctx.strokeStyle = color; ctx.lineWidth = 2.5; ctx.globalAlpha = 0.85;
  CONEXIONES.forEach(([a, b]) => {
    if (!kp[a] || !kp[b] || kp[a].score < 0.4 || kp[b].score < 0.4) return;
    ctx.beginPath();
    ctx.moveTo(kp[a].position.x, kp[a].position.y);
    ctx.lineTo(kp[b].position.x, kp[b].position.y);
    ctx.stroke();
  });
  ctx.fillStyle = color; ctx.globalAlpha = 1;
  keypoints.forEach(k => {
    if (k.score < 0.4) return;
    ctx.beginPath();
    ctx.arc(k.position.x, k.position.y, 4, 0, 2 * Math.PI);
    ctx.fill();
  });
}

async function iniciarCamara() {
  try {
    const stream = await navigator.mediaDevices.getUserMedia({
      video: { facingMode: 'user', width: 1280, height: 720 }
    });
    video.srcObject = stream;
    await new Promise(r => video.onloadedmetadata = r);
    canvas.width  = video.videoWidth;
    canvas.height = video.videoHeight;
    return true;
  } catch(e) {
    status.textContent = 'Error: ' + e.message;
    return false;
  }
}

async function loop(net) {
  if (video.readyState < 2) { requestAnimationFrame(() => loop(net)); return; }
  const pose = await net.estimateSinglePose(video, { flipHorizontal: true, imageScaleFactor: 0.6, outputStride: 16 });
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  const pct  = Math.round(suavizar(calcularScore(pose.keypoints)));
  let color, msg, bg, border;
  if (pct > 75)      { color='#198754'; msg='Postura correcta — mantén la posición';      bg='rgba(25,135,84,0.15)';  border='#198754'; }
  else if (pct > 50) { color='#FFC107'; msg='Ajuste leve de postura recomendado';          bg='rgba(255,193,7,0.15)';  border='#FFC107'; }
  else               { color='#DC3545'; msg='Postura incorrecta — corrija de inmediato';   bg='rgba(220,53,69,0.15)';  border='#DC3545'; }
  dibujar(pose.keypoints, color);
  scoreEl.style.color = color;
  scoreEl.textContent = 'Postura: ' + pct + '%';
  alertEl.style.background = bg; alertEl.style.color = color;
  alertEl.style.border = '1px solid ' + border;
  alertEl.textContent = msg;
  requestAnimationFrame(() => loop(net));
}

(async () => {
  const ok = await iniciarCamara();
  if (!ok) return;
  status.textContent = 'Cargando PoseNet...';
  const net = await posenet.load({
    architecture: 'MobileNetV1', outputStride: 16,
    inputResolution: { width: 640, height: 480 }, multiplier: 0.75,
  });
  status.style.display = 'none';
  loop(net);
})();
</script>
</body>
</html>
''';

  @override
  void initState() {
    super.initState();
    if (!_registered) {
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId,
        (int viewId) {
          final iframe = web.HTMLIFrameElement();
          iframe.setAttribute('srcdoc', _poseHtml);
          iframe.setAttribute('allow', 'camera');
          iframe.style.border = 'none';
          iframe.style.width  = '100%';
          iframe.style.height = '100%';
          return iframe;
        },
      );
      _registered = true;
    }
  }

  @override
Widget build(BuildContext context) {
  return Column(
    children: [
      // Ocupa todo el espacio disponible automáticamente
      Expanded(
        child: const HtmlElementView(viewType: _viewId),
      ),

      // Leyenda compacta
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _legendItem(Icons.circle, _success, 'Correcta >75%'),
            _legendItem(Icons.circle, const Color(0xFFFFC107), 'Ajuste 50-75%'),
            _legendItem(Icons.circle, _danger, 'Incorrecta <50%'),
          ],
        ),
      ),
    ],
  );
}

  Widget _legendItem(IconData icon, Color color, String texto) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 10),
      const SizedBox(width: 4),
      Text(texto, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
    ],
  );
}
