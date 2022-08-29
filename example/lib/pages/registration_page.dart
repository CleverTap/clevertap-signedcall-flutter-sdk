import 'package:clevertap_directcall_flutter/plugin/clevertap_directcall_flutter.dart';
import 'package:clevertap_directcall_flutter_example/constants.dart';
import 'package:clevertap_directcall_flutter_example/pages/dialler_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shared_preference_manager.dart';

class RegistrationPage extends StatefulWidget {
  static const routeName = '/registration';
  final ClevertapDirectcallFlutter clevertapDirectcallFlutterPlugin;
  final String title;

  const RegistrationPage(
      {Key? key,
      required this.title,
      required this.clevertapDirectcallFlutterPlugin})
      : super(key: key);

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  String _userCuid = '';
  final cuidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initDCSDKIfCuIDSignedIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Direct Call'),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Column(
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              'USER-REGISTRATION',
              // textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Image.asset(
              'assets/clevertap-logo.png',
              height: 200,
              width: 200,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: cuidController,
              decoration: const InputDecoration(
                hintText: 'Enter CUID',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                initDirectCallSdk(cuidController.text);
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.red),
              ),
              child: const Text('Register and Continue'),
            ),
          ],
        ),
      ),
    );
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initDirectCallSdk(String cuid) async {
    showLoading();

    _userCuid = cuidController.text;

    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      const callScreenBranding = {
        keyBgColor: "#000000",
        keyFontColor: "#ffffff",
        keyLogoUrl:
            "https://res.cloudinary.com/dsakrbtd6/image/upload/v1642409353/ct-logo_mkicxg.png",
        keyButtonTheme: "light"
      };

      const missedCallActionsMap = {
        "1": "Call me back",
        "2": "Start Chat",
        "3": "Not Interested"
      };

      var initProperties = {
        keyAccountId: dcAccountId,
        keyApiKey: dcApiKey,
        keyCuid: cuid,
        keyAllowPersistSocketConnection: true, //Android Platform
        keyEnableReadPhoneState: true, //Android Platform
        keyOverrideDefaultBranding: callScreenBranding, //Android Platform
        keyMissedCallActions: missedCallActionsMap //Android Platform
      };

      widget.clevertapDirectcallFlutterPlugin.init(
          initProperties: initProperties, initHandler: _directCallInitHandler);
    } on PlatformException {
      const snackBar = SnackBar(content: Text('PlatformException occurs!'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _directCallInitHandler(
      Map<String, dynamic>? directCallInitError) async {
    if (kDebugMode) {
      print(
          "CleverTap:DirectCallFlutter: directCallInitHandler called = ${directCallInitError.toString()}");
    }
    if (directCallInitError == null) {
      //Initialization is successful here
      const snackBar = SnackBar(content: Text('Direct Call SDK Initialized!'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      processNext();
    } else {
      //Initialization is failed here
      final errorCode = directCallInitError[keyErrorCode];
      final errorMessage = directCallInitError[keyErrorMessage];

      final snackBar =
          SnackBar(content: Text('DC Init failed: $errorCode = $errorMessage'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void processNext() {
    //save cuid in a local session
    SharedPreferenceManager.saveLoggedInCuid(_userCuid);

    //Navigate the user to the Dialler Page
    Navigator.pushNamed(context, DiallerPage.routeName,
        arguments: {"loggedInCuid": _userCuid});
  }

  /// Initialized the DC SDK directly if any account is already signed in
  void initDCSDKIfCuIDSignedIn() {
    SharedPreferenceManager.getLoggedInCuid().then((result) {
      setState(() {
        if (result != null) {
          _userCuid = result;
          initDirectCallSdk(result);
        }
      });
    });
  }

  void showLoading() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        });
  }
}