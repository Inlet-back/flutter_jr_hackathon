import 'package:alarm/alarm.dart';
import 'package:alarm/model/volume_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:flutter_jr_hackathon/common/themes/theme_manager.dart';
import 'package:flutter_jr_hackathon/provider/difficulty_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditAlarmScreen extends ConsumerStatefulWidget {
  const EditAlarmScreen({super.key, this.alarmSettings, required this.theme});

  final AlarmSettings? alarmSettings;
  final ThemeManager theme; // ThemeManagerを受け取る

  @override
  ConsumerState<EditAlarmScreen> createState() => _EditAlarmScreenState();
}

class _EditAlarmScreenState extends ConsumerState<EditAlarmScreen> {
  bool loading = false;

  late bool creating;
  late DateTime selectedDateTime;
  late bool loopAudio;
  late bool vibrate;
  late double? volume;
  late Duration? fadeDuration;
  late bool staircaseFade;
  late String assetAudio;

  // 途中
  @override
  void initState() {
    super.initState();
    creating = widget.alarmSettings == null;

    if (creating) {
      selectedDateTime = DateTime.now().add(const Duration(minutes: 1));
      selectedDateTime = selectedDateTime.copyWith(second: 0, millisecond: 0);
      loopAudio = true;
      vibrate = true;
      volume = null;
      fadeDuration = null;
      staircaseFade = false;
      assetAudio = 'assets/marimba.mp3';
    } else {
      selectedDateTime = widget.alarmSettings!.dateTime;
      loopAudio = widget.alarmSettings!.loopAudio;
      vibrate = widget.alarmSettings!.vibrate;
      volume = widget.alarmSettings!.volumeSettings.volume;
      fadeDuration = widget.alarmSettings!.volumeSettings.fadeDuration;
      staircaseFade = widget.alarmSettings!.volumeSettings.fadeSteps.isNotEmpty;
      assetAudio = widget.alarmSettings!.assetAudioPath;
    }
  }

  // 途中
  // String getDay

  // 途中
  Future<void> pickTime() async {
    final res = await DatePicker.showTimePicker(
      context,
      showTitleActions: true,
      showSecondsColumn: false,
    );

    if (res != null) {
      setState(() {
        final now = DateTime.now();
        selectedDateTime = now.copyWith(
          hour: res.hour,
          minute: res.minute,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        );
        if (selectedDateTime.isBefore(now)) {
          selectedDateTime = selectedDateTime.add(Duration(days: 1));
        }
      });
    }
  }

  // フル
  AlarmSettings buildAlarmSettings() {
    final id = creating
        ? DateTime.now().millisecondsSinceEpoch % 10000 + 1
        : widget.alarmSettings!.id;

    final VolumeSettings volumeSettings;

    if (staircaseFade) {
      volumeSettings = VolumeSettings.staircaseFade(
        volume: volume,
        fadeSteps: [
          VolumeFadeStep(Duration.zero, 0),
          VolumeFadeStep(const Duration(seconds: 15), 0.03),
          VolumeFadeStep(const Duration(seconds: 20), 0.5),
          VolumeFadeStep(const Duration(seconds: 30), 1),
        ],
      );
    } else if (fadeDuration != null) {
      volumeSettings = VolumeSettings.fade(
        volume: volume,
        fadeDuration: fadeDuration!,
      );
    } else {
      volumeSettings = VolumeSettings.fixed(
        volume: volume,
      );
    }

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: selectedDateTime,
      loopAudio: loopAudio,
      vibrate: vibrate,
      assetAudioPath: assetAudio,
      volumeSettings: volumeSettings,
      allowAlarmOverlap: true,
      notificationSettings: NotificationSettings(
          title: 'タップして',
          body: 'めざましシューティング！',
          stopButton: 'stop',
          icon: 'notification icon'),
    );
    return alarmSettings;
  }

  void saveAlarm() async {
    print('追加１');
    if (loading) return;
    print('追加2');
    setState(() => loading = true);
    print('追加3');

    Alarm.set(alarmSettings: buildAlarmSettings()).then((res) {
      print('確認');
      print('確認１: $res');
      if (res && mounted) Navigator.pop(context, true);
      print('確認２');
      setState(() {
        loading = false;
      });
    }).catchError((e) {
      print(e);
    });

    print('追加１０');
  }

  // 途中
  // delete

  @override
  Widget build(BuildContext context) {
    final gameDifficulty = ref.watch(difficultyNotifierProvider);
    print('gameDifficulty: $gameDifficulty');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: Text(
                  'キャンセル',
                  style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: saveAlarm,
                child: loading
                    ? CircularProgressIndicator()
                    : Text(
                        '保存',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
          RawMaterialButton(
            onPressed: pickTime,
            fillColor: Colors.white70,
            child: Container(
              margin: const EdgeInsets.all(20),
              child: Text(
                TimeOfDay.fromDateTime(selectedDateTime).format(context),
                style: Theme.of(context)
                    .textTheme
                    .displayMedium!
                    .copyWith(color: Colors.black),
              ),
            ),
          ),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     // 使い慣れているアラームはデフォルトでonだから不要かも
          //     Text('アラーム音を繰り返す'),
          //     CupertinoSwitch(
          //         value: loopAudio,
          //         onChanged: (value) {
          //           setState(() {
          //             loopAudio = value;
          //             print(loopAudio);
          //           });
          //         }),
          //   ],
          // ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              //// デフォルトでバイブレーションはon
              // Text(
              //   'バイブレーション',
              //   style: TextStyle(
              //       // fontSize: 16,
              //       // fontWeight: FontWeight.bold,
              //       ),
              // ),
              // CupertinoSwitch(
              //   value: vibrate,
              //   onChanged: (value) {
              //     setState(() {
              //       vibrate = value;
              //     });
              //   },
              // ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('テーマ'),
              DropdownButton(
                value: widget.theme.currentThemeName,
                items: [
                  DropdownMenuItem<String?>(
                    value: "CrystalTheme",
                    child: Text('クリスタル'),
                  ),
                  DropdownMenuItem<String?>(
                    value: "ChineseTheme",
                    child: Text('チャイナ'),
                  ),
                ],
                onChanged: (value) {
                  if (value == "CrystalTheme") {
                    widget.theme.setCrystalTheme();
                  } else if (value == "ChineseTheme") {
                    widget.theme.setChineseTheme();
                  }
                  print('テーマ変更: $value');
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('サウンド'),
              DropdownButton(
                value: assetAudio,
                items: [
                  DropdownMenuItem<String>(
                    value: 'assets/marimba.mp3',
                    child: Text('マリンバ'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'assets/mozart.mp3',
                    child: Text('モーツァルト'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'assets/one_piece.mp3',
                    child: Text('ワンピース'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    assetAudio = value!;
                  });
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('めざまし'),
              DropdownButton(
                value: gameDifficulty,
                items: [
                  DropdownMenuItem<String?>(
                    value: "Easy",
                    child: Text('ふつうに起きる'),
                  ),
                  DropdownMenuItem<String?>(
                    value: "Normal",
                    child: Text('ちゃんと起きる'),
                  ),
                  DropdownMenuItem<String?>(
                    value: "Hard",
                    child: Text('まじで起きる'),
                  ),
                ],
                onChanged: (value) {
                  ref
                      .read(difficultyNotifierProvider.notifier)
                      .setDifficulty(value!);
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('音量の変更'),
              CupertinoSwitch(
                value: volume != null,
                onChanged: (value) {
                  setState(() {
                    volume = value ? 0.5 : null;
                  });
                },
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: Duration(milliseconds: 200),
            child: volume != null
                ? SizedBox(
                    key: ValueKey('slider'),
                    height: 45,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          volume! > 0.7
                              ? Icons.volume_up_rounded
                              : volume! > 0.1
                                  ? Icons.volume_down_rounded
                                  : Icons.volume_mute_rounded,
                        ),
                        Expanded(
                          child: Slider(
                            value: volume!,
                            min: 0.1,
                            max: 1.0,
                            activeColor: Colors.green,
                            onChanged: (value) {
                              setState(() {
                                volume = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    key: ValueKey('empty'),
                    height: 45,
                  ),
          ),
          Row(),
        ],
      ),
    );
  }
}
