Future<void> loadTargetModel() async {
  if (!mounted) return;
  final loader = three.OBJLoader(); // モデルのパスを設定
  final textureLoader = three.TextureLoader();
  late three.Texture texture;
  textureLoader.flipY = false;
  texture = (await textureLoader.fromAsset('assets/models/target.png'))!;
  texture.magFilter = three.LinearFilter;
  texture.minFilter = three.LinearMipmapLinearFilter;
  texture.generateMipmaps = true;
  texture.needsUpdate = true;
  texture.flipY = true; // this flipY is only for web

  final objTemplate = await loader.fromAsset('assets/models/target.obj');
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
      
      three.Vector3 forward = getForwardVector();
      // 的の位置を設定
      double randomDistance =
          30 + math.Random().nextDouble() * 20; // 3.0から5.0のランダムな距離

      three.Vector3 targetPosition = three.Vector3()
        ..setFrom(threeJs.camera.position)
        ..addScaled(forward, randomDistance); /

      // X・Y方向にランダムにオフセット

       double offsetX = (math.Random().nextDouble() * 40) *
          (math.Random().nextBool() ? 1 : -1); // -20.0 ～ 20.0
      double offsetY = (math.Random().nextDouble() * 10 + 10); // 20.0 ～ 40.0
      targetPosition.x += offsetX;
      targetPosition.y += offsetY;

      obj.position.setFrom(targetPosition);

      obj.scale.setValues(0.1, 0.1, 0.1);
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

      targets!.add(obj); // 追加した的をオブジェクトリストに追加

      // 的をオブジェクトリストに追加
    } catch (e) {
      print('Error loading target model: $e');
    }
  }
}
