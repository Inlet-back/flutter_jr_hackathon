import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_jr_hackathon/scenes/alarm/components/alarm_tile.dart';
// import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
// import 'package:flutter_jr_hackathon/model/alarm_settings.dart';
import 'package:flutter_jr_hackathon/scenes/alarm/edit_alarm_screen.dart';
import 'package:go_router/go_router.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  // まだ使ってない
  List<AlarmSettings> alarms = [];
  // Notifications? notifications;

  // static StreamSubscription<AlarmSet>? ringSubscription;
  // static StreamSubscription<AlarmSet>? updateSubscription;

  // 途中
  // @override
  // void initState()

  // フル
  // アラームは基本１つしか用意しないからAlarm.getAlarm()でも問題ないけど、exAppに合わせる
  Future<void> loadAlarms() async {
    final updateAlarms = await Alarm.getAlarms();
    updateAlarms.sort((a, b) => a.dateTime.isBefore(b.dateTime) ? 0 : 1);
    setState(() {
      alarms = updateAlarms;
    });
  }

  // 途中
  // ringing~~

  // フル
  Future<void> navigateToAlarmScreen(AlarmSettings? settings) async {
    final res = await showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.7,
          child: EditAlarmScreen(alarmSettings: settings),
        );
      },
    );

    if (res != null && res == true) unawaited(loadAlarms());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('アラーム設定'),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Expanded(
                child: alarms.isNotEmpty
                    ? ListView.separated(
                        itemCount: alarms.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          return AlarmTile(
                            key: Key(alarms[index].id.toString()),
                            title: TimeOfDay(
                                    hour: alarms[index].dateTime.hour,
                                    minute: alarms[index].dateTime.minute)
                                .format(context),
                            onPressed: () {
                              navigateToAlarmScreen(alarms[index]);
                            },

                            // 中身を完成させる
                            // key: Key(alarms[index].id.toString()),
                            // title: TimeOfDay(
                            //   hour: alarms[index].dateTime.hour,
                            //   minute: alarms[index].dateTime.minute,
                            // ).format(context),
                            // onPressed: () =>
                            //     navigateToAlarmScreen(alarms[index]),
                            // onDismissed: () {
                            //   Alarm.stop(alarms[index].id)
                            //       .then((_) => loadAlarms());
                            // },
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          'No alarms set',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
              ),
              FloatingActionButton(
                onPressed: () {
                  navigateToAlarmScreen(null);
                },
                child: Icon(Icons.alarm_add_rounded, size: 33),
              ),
              ElevatedButton(
                child: Text("ゲームへ"),
                onPressed: () {
                  context.go('/game');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
