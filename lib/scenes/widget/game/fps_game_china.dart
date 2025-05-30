import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jr_hackathon/provider/difficulty_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_objects/three_js_objects.dart';
import 'dart:math';

class SphereData {
  SphereData(
      {required this.mesh, required this.collider, required this.velocity});

  three.Mesh mesh;
  three.BoundingSphere collider;
  three.Vector3 velocity;
}

class FPSGameChina extends ConsumerStatefulWidget {
  final ValueChanged<int> onTargetCountChanged;
  final int checkTime;
  final int gameScreenTime; // ゲーム経過時間
  final int targetGoal; // 目標スコア
  final bool isMoveMode; // 移動モード
  const FPSGameChina({
    super.key,
    required this.onTargetCountChanged,
    required this.checkTime,
    required this.gameScreenTime,
    required this.targetGoal,
    required this.isMoveMode,
  });

  @override
  _FPSGamePageState createState() => _FPSGamePageState();
}

class _FPSGamePageState extends ConsumerState<FPSGameChina> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS? threeJs;
  final vertex = three.Vector3.zero();
  final color = three.Color();
  List<three.Object3D>? boxes = [];
  List<three.Object3D>? targets = [];
  int targetCount = 0;

  StreamSubscription<GyroscopeEvent>? gyroscopeSubscription;
  late double radius;

  // ジャイロスコープのデータを保持
  double yaw = 0.0; // 水平方向の回転
  double pitch = 0.0; // 垂直方向の回転

  void onPointerDown(event) {
    // ポインターダウン時の処理
    mouseTime = DateTime.now().millisecondsSinceEpoch;
  }

  void onPointerUp(event) {
    // ポインターアップ時の処理
    throwBall();
  }

  List<three.Object3D>? _sceneObjects = [];
  List<three.Material>? _materials = [];
  List<three.PlaneGeometry>? _geometries = [];

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          data.removeAt(0);
          data.add(threeJs!.clock.fps);
        });
      }
    });
    threeJs = three.ThreeJS(
        onSetupComplete: () {
          if (mounted) {
            setState(() {
              gyroscopeSubscription =
                  gyroscopeEvents.listen((GyroscopeEvent event) {
                if (mounted && threeJs!.camera != null) {
                  setState(() {
                    yaw += event.y * 0.1; // Y軸の回転データを使用
                    pitch += event.x * 0.1; // X軸の回転データを使用

                    // カメラの回転を更新
                    updateCameraRotation();
                  });
                }
              });
            });
          }

          // Keybindings
          // Add force on keydown
          threeJs!.domElement.addEventListener(
              three.PeripheralType.pointerdown, onPointerDown);
          threeJs!.domElement
              .addEventListener(three.PeripheralType.pointerup, onPointerUp);
        },
        setup: setup);
  }

  void clearSceneObjects() {
    if (_sceneObjects != null) {
      for (var obj in _sceneObjects!) {
        removeObjectFromScene(obj);
      }
      _sceneObjects!.clear(); // リストをクリア
    }
  }

  void clearMaterials() {
    if (_materials != null) {
      for (var material in _materials!) {
        material.dispose(); // マテリアルを解放
      }
      _materials!.clear(); // リストをクリア
    }
  }

  void clearGeometries() {
    if (_geometries != null) {
      for (var geometry in _geometries!) {
        geometry.dispose(); // ジオメトリを解放
      }
      _geometries!.clear(); // リストをクリア
    }
  }

  @override
  void dispose() {
    try {
      // Three.js関連のリソースを解放
      if (threeJs != null) {
        clearSceneObjects(); // シーンオブジェクトを削除
        clearMaterials(); // マテリアルを削除
        clearGeometries(); // ジオメトリを削除

        // シーン内のオブジェクトを削除
        for (var obj in _sceneObjects!) {
          threeJs!.scene.remove(obj);
          if (obj is three.Mesh) {
            obj.geometry?.dispose(); // ジオメトリを解放
            if (obj.material is three.Material) {
              (obj.material as three.Material).dispose();
              obj.material = null; // マテリアルを解放
            }
          }
        }

        _sceneObjects!.clear();
        _sceneObjects = null;

        // マテリアルを解放
        for (var material in _materials!) {
          material.dispose();
        }
        _materials!.clear();
        _materials = null;

        // ジオメトリを解放
        for (var geometry in _geometries!) {
          geometry.dispose();
        }
        _geometries!.clear();
        _geometries = null;

        // Three.jsのキャッシュをクリア
        three.loading.clear();

        // Three.js全体のリソースを解放
        threeJs!.dispose();
        threeJs = null;
      }
    } catch (e, stackTrace) {
      // エラーが発生した場合にログを記録
      debugPrint('Error during dispose: $e\n$stackTrace');
    }

    super.dispose();
  }

  void updateCameraRotation() {
    if (threeJs!.camera != null) {
      threeJs!.camera.rotation.set(pitch, yaw, 0);
    } else {
      print('Camera is not initialized yet.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [threeJs!.build()],
    ));
  }

  int stepsPerFrame = 5;
  double gravity = 30;

  List<SphereData> spheres = [];
  int sphereIdx = 0;

  Octree worldOctree = Octree();

  three.Vector3 playerVelocity = three.Vector3();
  three.Vector3 playerDirection = three.Vector3();

  bool playerOnFloor = false;
  int mouseTime = 0;
  Map<LogicalKeyboardKey, bool> keyStates = {
    LogicalKeyboardKey.arrowUp: false,
    LogicalKeyboardKey.arrowLeft: false,
    LogicalKeyboardKey.arrowDown: false,
    LogicalKeyboardKey.arrowRight: false,
    LogicalKeyboardKey.space: false,
  };

  three.Vector3 vector1 = three.Vector3();
  three.Vector3 vector2 = three.Vector3();
  three.Vector3 vector3 = three.Vector3();

  Future<void> setup() async {
    if (!mounted) return;
    threeJs!.scene = three.Scene();

    // 背景を朝日の色に変更
    threeJs!.scene.background = three.Color.fromHex32(0x8ED1E0); //
    threeJs!.scene.fog = three.Fog(0xffcc99, 0, 750); // フォグも背景色に合わせる

    threeJs!.camera = three.PerspectiveCamera(
        70, threeJs!.width / threeJs!.height, 0.1, 1000);

    threeJs!.camera.position.y = 10;
    threeJs!.camera.rotation.order = three.RotationOrders.yxz;

    // ライト設定
    final light = three.HemisphereLight(0xffeedd, 0x777788, 0.8); // 朝日のような柔らかい光
    light.position.setValues(0.5, 1, 0.75);
    threeJs!.scene.add(light);
    _sceneObjects!.add(light);
// 床のジオメトリを作成
    final floorGeometry = three.PlaneGeometry(2000, 2000); // 床の大きさを設定
    floorGeometry.rotateX(-math.pi / 2); // 床を水平に配置
    _geometries!.add(floorGeometry);

// 床のマテリアルを作成
    final floorMaterial = three.MeshStandardMaterial.fromMap({
      'color': three.Color.fromHex32(0x808080), // 灰色の床
      'roughness': 0.8, // 粗さを設定
      'metalness': 0.0, // 金属感をなくす
    });

    _materials!.add(floorMaterial);
// 床のメッシュを作成
    final floor = three.Mesh(floorGeometry, floorMaterial);
    floor.receiveShadow = true; // 床が影を受け取るように設定

// シーンに床を追加
    threeJs!.scene.add(floor);

    _sceneObjects!.add(floor);

    final loader = three.OBJLoader(); // OBJローダーを使用

    // モデルを一度だけロード
    var objTemplate = await loader.fromAsset('assets/models/lamp.obj');
    if (objTemplate == null) {
      print('モデルの読み込みに失敗しました');
      return;
    }

    for (int i = 0; i < 150; i++) {
      // 数を半分に変更

      try {
        // モデルを非同期でロード

        three.Object3D? obj = objTemplate!.clone(true);

        // ランダムな位置を設定
        obj.position.x =
            (math.Random().nextDouble() * 20 - 10).floor() * 20 + 20;
        obj.position.y = (math.Random().nextDouble() * 20).floor() * 3 + 40;
        obj.position.z =
            (math.Random().nextDouble() * 20 - 10).floor() * 20 + 20;

        obj.scale.setValues(20, 20, 20); // スケールを調整

        obj.traverse((child) {
          if (child is three.Mesh) {
            // 赤～オレンジのみに限定した柔らかい色を生成
            final lanternColor = three.Color();
            lanternColor.setHSL(
              math.Random().nextDouble() * 0.1, // 色相 (赤～オレンジ)
              math.Random().nextDouble() * 0.3 + 0.7, // 彩度 (柔らかい色合い)
              math.Random().nextDouble() * 0.4 + 0.5, // 明度 (明るめの色)
            );

            final material = three.MeshStandardMaterial.fromMap({
              'color': lanternColor,
              'emissive': lanternColor,
              'emissiveIntensity': 0.5,
            });
            child.material = material;
            _materials!.add(material); // リソースを追跡

            child.castShadow = true;
            child.receiveShadow = true;
          }
        });
        // シーンに追加
        threeJs!.scene.add(obj);
        _sceneObjects!.add(obj); // リソースを追跡
        boxes!.add(obj); // 的リストに追加
        obj = null; // メモリを解放
      } catch (e) {
        print('Error loading target model: $e');
      }
    }
    objTemplate = null; // メモリを解放
    // 的の設置

    await loadTargetModel();
    double direction = 1.0; // 移動方向（1: 右, -1: 左）
    double speed = 4.0; // 移動速度
    double maxDistance = 30.0; // 最大移動距離
    Map<three.Object3D, double> initialPositions = {}; // 初期位置を記録

    threeJs!.addAnimationEvent((dt) {
      double deltaTime = math.min(0.05, dt) / stepsPerFrame;
      if (deltaTime != 0) {
        for (int i = 0; i < stepsPerFrame; i++) {
          updateSpheres(deltaTime);
          // teleportPlayerIfOob();

          // 的の更新処理を関数で呼び出し
          if (widget.isMoveMode) {
            updateTargets(
                deltaTime, initialPositions, direction, speed, maxDistance);
          }
        }
      }
    });
  }

  void removeObjectFromScene(three.Object3D obj) {
    // シーンからオブジェクトを削除
    if (threeJs!.scene.children.contains(obj)) {
      threeJs!.scene.remove(obj);
    }

    // オブジェクトが Mesh の場合、リソースを解放
    if (obj is three.Mesh) {
      obj.geometry?.dispose(); // ジオメトリを解放
      if (obj.material is three.Material) {
        (obj.material as three.Material).dispose(); // マテリアルを解放
      }
    }

    // 子オブジェクトも再帰的に削除
    obj.traverse((child) {
      if (child is three.Mesh) {
        child.geometry?.dispose();
        if (child.material is three.Material) {
          (child.material as three.Material).dispose();
        }
      }
    });
  }

  void updateTargets(
      double deltaTime,
      Map<three.Object3D, double> initialPositions,
      double direction,
      double speed,
      double maxDistance) {
    // 初期位置を記録（最初のフレームのみ）
    if (initialPositions.isEmpty) {
      for (var obj in targets!) {
        initialPositions[obj] = obj.position.x;
      }
    }

    // 的を左右に動かす
    for (var obj in targets!) {
      double initialX = initialPositions[obj]!;
      obj.position.x += direction * speed * deltaTime;

      // 最大移動距離に達したら方向を反転
      if ((obj.position.x - initialX).abs() >= maxDistance) {
        direction *= -1; // 方向を反転
      }
    }
  }

  Future<void> loadTargetModel() async {
    if (!mounted) return;
    final loader = three.OBJLoader(); // モデルのパスを設定
    final textureLoader = three.TextureLoader();
    late three.Texture texture;
    textureLoader.flipY = false;
    texture = (await textureLoader.fromAsset('assets/textures/target.jpg'))!;
    texture.magFilter = three.LinearFilter;
    texture.minFilter = three.LinearMipmapLinearFilter;
    texture.generateMipmaps = true;
    texture.needsUpdate = true;
    texture.flipY = true; // this flipY is only for web

    final objTemplate = await loader.fromAsset('assets/models/1.object.obj');
    if (objTemplate == null) {
      print('モデルの読み込みに失敗しました');
      return;
    }

    for (int i = 0; i < widget.targetGoal; i++) {
      try {
        // モデルを非同期でロード
        final obj = objTemplate.clone(true);
        three.Vector3 forward = getForwardVector();
        // 的の位置を設定
        double randomDistance = 50 + math.Random().nextDouble() * 40;

        three.Vector3 targetPosition = three.Vector3()
          ..setFrom(threeJs!.camera.position)
          ..addScaled(forward, randomDistance); // プレイヤーの前方20ユニット

        // X・Y方向にランダムにオフセット

        double offsetX = (math.Random().nextDouble() * 60) *
            (math.Random().nextBool() ? 1 : -1);
        double offsetY = (math.Random().nextDouble() * 20 + 20);
        targetPosition.x += offsetX;
        targetPosition.y += offsetY;

        obj.position.setFrom(targetPosition);

        obj.scale.setValues(5, 5, 5);
        obj.lookAt(threeJs!.camera.position);

        // 子オブジェクトをトラバースして設定
        obj.traverse((child) {
          if (child is three.Mesh) {
            child.material = three.MeshStandardMaterial.fromMap({
              'map': texture, // テクスチャを適用
              'roughness': 0.8,
              'metalness': 0.0,
            });
            child.castShadow = true;
            child.receiveShadow = true;
          }
        });

        // 的をシーンに追加
        threeJs!.scene.add(obj);
        _sceneObjects!.add(obj);
        targets!.add(obj); // 追加した的をオブジェクトリストに追加

        // 的をオブジェクトリストに追加
      } catch (e) {
        print('Error loading target model: $e');
      }
    }
  }

  void throwBall() {
    double sphereRadius = 1.0;
    IcosahedronGeometry sphereGeometry = IcosahedronGeometry(sphereRadius, 5);
    three.MeshLambertMaterial sphereMaterial =
        three.MeshLambertMaterial.fromMap({'color': 0xbbbb44});

    final three.Mesh newsphere = three.Mesh(sphereGeometry, sphereMaterial);
    newsphere.castShadow = true;
    newsphere.receiveShadow = true;

    threeJs!.scene.add(newsphere);
    spheres.add(SphereData(
        mesh: newsphere,
        collider: three.BoundingSphere(three.Vector3(0, 10, 0), sphereRadius),
        velocity: three.Vector3()));
    SphereData sphere = spheres.last;

    // カメラの向いている方向を取得
    threeJs!.camera.getWorldDirection(playerDirection);

    // スフィアの初期位置をカメラの位置から設定
    sphere.collider.center
        .setFrom(threeJs!.camera.position)
        .addScaled(playerDirection, 2.0); // カメラの前方にスフィアを配置

    // スフィアをカメラの方向に一定速度で飛ばす
    double fixedSpeed = 50.0; // 固定速度
    sphere.velocity.setFrom(playerDirection).scale(fixedSpeed); // 一定速度で設定
  }

  void spheresCollisions() {
    for (int i = 0, length = spheres.length; i < length; i++) {
      SphereData s1 = spheres[i];
      for (int j = i + 1; j < length; j++) {
        SphereData s2 = spheres[j];
        num d2 = s1.collider.center.distanceToSquared(s2.collider.center);
        double r = s1.collider.radius + s2.collider.radius;
        double r2 = r * r;

        if (d2 < r2) {
          three.Vector3 normal =
              vector1.sub2(s1.collider.center, s2.collider.center).normalize();
          three.Vector3 v1 =
              vector2.setFrom(normal).scale(normal.dot(s1.velocity));
          three.Vector3 v2 =
              vector3.setFrom(normal).scale(normal.dot(s2.velocity));

          s1.velocity.add(v2).sub(v1);
          s2.velocity.add(v1).sub(v2);

          double d = (r - math.sqrt(d2)) / 2;

          s1.collider.center.addScaled(normal, d);
          s2.collider.center.addScaled(normal, -d);
        }
      }
    }
  }

  void checkCollisionWithTarget(SphereData sphere, three.Object3D target) {
    // 玉の中心と的の中心を取得
    three.Vector3 sphereCenter = sphere.collider.center;
    three.Vector3 targetCenter = target.position;

    // 玉の半径と的の半径を設定
    double sphereRadius = sphere.collider.radius;

    // 距離を計算（z軸を別途考慮）
    double dx = sphereCenter.x - targetCenter.x;
    double dy = sphereCenter.y - targetCenter.y;
    double dz = (sphereCenter.z - targetCenter.z) * 0.5; // z軸の距離を小さくする

    // 距離の二乗を計算
    double distanceSquared = dx * dx + dy * dy + dz * dz;

    // 衝突判定
    if (distanceSquared <= 15.0) {
      handleTargetHit(target, sphere); // 衝突時の処理を呼び出し
    }
  }

  void handleTargetHit(three.Object3D target, SphereData sphere) {
    // 的をシーンから削除
    if (threeJs!.scene.children.contains(target)) {
      targetCount++;
    }
    threeJs!.scene.remove(target);
    threeJs!.scene.remove(sphere.mesh);

    widget.onTargetCountChanged(targetCount);

    if (targetCount >= widget.targetGoal) {
      context.go('/clear', extra: {
        'checkTime': widget.checkTime,
        'gameTime': widget.gameScreenTime
      });
    }
  }

  void updateSpheres(double deltaTime) {
    for (final sphere in spheres) {
      sphere.collider.center.addScaled(sphere.velocity, deltaTime);
      OctreeData? result = worldOctree.sphereIntersect(sphere.collider);
      if (result != null) {
        sphere.collider.center.add(result.normal.scale(result.depth));
      }
      // 玉と的の当たり判定をチェック
      for (final target in targets!) {
        checkCollisionWithTarget(sphere, target);
        // if (!threeJs.scene.children.contains(target)) {
        //   break; // 現在のループを終了して次の弾に進む
        // }
      }
    }

    spheresCollisions();

    for (SphereData sphere in spheres) {
      sphere.mesh.position.setFrom(sphere.collider.center);
    }
  }

  three.Vector3 getForwardVector() {
    threeJs!.camera.getWorldDirection(playerDirection);
    playerDirection.y = 0;
    playerDirection.normalize();
    return playerDirection;
  }

  three.Vector3 getSideVector() {
    threeJs!.camera.getWorldDirection(playerDirection);
    playerDirection.y = 0;
    playerDirection.normalize();
    playerDirection.cross(threeJs!.camera.up);
    return playerDirection;
  }
}
