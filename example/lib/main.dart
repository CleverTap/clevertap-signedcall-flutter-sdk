import 'dart:async';

import 'package:clevertap_signedcall_flutter/models/call_events.dart';
import 'package:clevertap_signedcall_flutter/models/log_level.dart';
import 'package:clevertap_signedcall_flutter/models/missed_call_action_click_result.dart';
import 'package:clevertap_signedcall_flutter/plugin/clevertap_signedcall_flutter.dart';
import 'package:clevertap_signedcall_flutter_example/route_generator.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription<CallEvent>? _callEventSubscription;
  late StreamSubscription<MissedCallActionClickResult>?
  _missedCallActionClickEventSubscription;

  @override
  void initState() {
    super.initState();

    //Enables the verbose debugging in Signed Call Plugin
    CleverTapSignedCallFlutter.shared.setDebugLevel(LogLevel.verbose);
    setup();
  }

  void setup() {
    _startObservingCallEvents();
    _startObservingMissedCallActionClickEvent();
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }

  //Listens to the real-time stream of call-events
  void _startObservingCallEvents() {
    _callEventSubscription =
        CleverTapSignedCallFlutter.shared.callEventListener.listen((event) {
          print(
              "CleverTap:SignedCallFlutter: received callEvent stream with ${event.toString()}");
          //Utils.showSnack(context, event.name);
          if (event == CallEvent.callInProgress) {
            //_startCallDurationMeterToEndCall();
          }
        });
  }

  //Listens to the missed call action click events
  void _startObservingMissedCallActionClickEvent() {
    _missedCallActionClickEventSubscription = CleverTapSignedCallFlutter
        .shared.missedCallActionClickListener
        .listen((result) {
      print(
          "CleverTap:SignedCallFlutter: received missedCallActionClickResult stream with ${result.toString()}");
      //Navigator.pushNamed(context, <SomePage.routeName>);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _callEventSubscription?.cancel();
    _missedCallActionClickEventSubscription?.cancel();
  }
}
