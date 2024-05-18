import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_webview_pro/webview_flutter.dart';

class WebpageInitialScreen extends StatefulWidget {
  WebpageInitialScreen({required this.isInternet, Key? key}) : super(key: key);
  final bool isInternet;

  @override
  _WebpageInitialScreenState createState() => _WebpageInitialScreenState();
}

class _WebpageInitialScreenState extends State<WebpageInitialScreen> {
  late StreamSubscription subscription;
  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = AndroidWebView();
    subscription = Connectivity().onConnectivityChanged.listen(changeNetStatus);
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  void changeNetStatus(ConnectivityResult result) {
    final hasInternet = result != ConnectivityResult.none;
    print('PRE STATUS INTERNET:' + internet.toString());
    setState(() {
      internet = hasInternet;
      print('STATUS INTERNET:' + internet.toString());

      // if (_controller != null) {
      //   _controller.reload();
      // }
    });
  }

  Future<void> _launchUrl({required url, required String appName}) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // throw 'Could not launch $url';
      errorSnackbar(text: appName);
    }
  }

  Future<void> _launchNativeOrWebUrl(
      {required String nativeUrl,
      required String webUrl,
      required String appName}) async {
    try {
      var canLaunchNatively = await canLaunchUrl(Uri.parse(nativeUrl));

      if (canLaunchNatively) {
        launchUrl(Uri.parse(nativeUrl));
      } else {
        await launchUrl(Uri.parse(webUrl),
            mode: LaunchMode.externalApplication);
      }
    } catch (e, st) {
      // Handle this as you prefer
      errorSnackbar(text: appName);
    }
  }

  void errorSnackbar({required text}) {
    Fluttertoast.showToast(
        msg: "Couldn't open $text!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.transparent,
        textColor: Color(0xffF10909),
        fontSize: 12.0);
  }

  int i = 0;
  late WebViewController _controller;

  double progress = 0;
  bool internet = false;
  @override
  Widget build(BuildContext context) {
    internet = i == 0 ? widget.isInternet : internet;
    i++;
    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          _controller.goBack();
          return false;
        } else {
          AlertDialog alert = quitAppAlertDialog(context);
          showDialog(
            context: context,
            builder: (BuildContext context) => alert,
          );

          return true;
        }
      },
      child: SafeArea(
        child: Scaffold(
          floatingActionButton: internet
              ? Padding(
                  padding: const EdgeInsets.only(
                    bottom: 70.0,
                  ),
                  child: Container(
                    height: 56,
                    width: 56,
                    child: FloatingActionButton(
                      child: Icon(
                        Icons.refresh,
                        size: 30,
                      ),
                      backgroundColor: Colors.blue,
                      elevation: 5,
                      foregroundColor: Colors.white,
                      onPressed: () {
                        _controller.reload();
                        print('progress on refresh: $progress');
                        Fluttertoast.showToast(
                            msg: "reloading page...",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.white,
                            textColor: Colors.green,
                            fontSize: 16.0);
                      },
                    ),
                  ),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: Row(
            children: [
              Container(
                width: internet && progress > 0.7
                    ? MediaQuery.of(context).size.width
                    : 0.0,
                child: WebView(
                  initialUrl: "https://deliday.co.in/app/",
                  javascriptMode: JavascriptMode.unrestricted,
                  onWebViewCreated: (controller) {
                    print('I\'m inside webview function');
                    this._controller = controller;
                    // controllerCompleter.complete(controller);
                  },
                  navigationDelegate: (NavigationRequest request) async {
                    String urlContains = request.url;
                    print("CLICKED URL: $urlContains");
                    if (request.url
                        .startsWith('https://api.whatsapp.com/send?phone')) {
                      List<String> urlSplitted =
                          request.url.split("send?phone=");
                      String phone =
                          urlSplitted.last.substring(1, 13); //ignore +
                      print("PHONE: " + phone);
                      // final String convertedUrl = "whatsapp://send?phone=" + phone + "&text=Hi";//older way
                      final String convertedUrl =
                          "https://wa.me/" + phone; //new way
                      //https://api.whatsapp.com/send/?phone=(phone_number)
                      var _uri = Uri.parse(convertedUrl);
                      await _launchUrl(
                          url: _uri,
                          appName:
                              'WhatsApp'); //This is where Whatsapp launches
                      return NavigationDecision.prevent;
                    }
                    // if (request.url.contains('mailto:')) {
                    //   // var _uri = Uri.parse(request.url);//older way
                    //   var _uri =
                    //       Uri(scheme: 'mailto', path: 'info@addictedshop.in');
                    //   await _launchUrl(url: _uri, appName: 'mail app');
                    //   return NavigationDecision.prevent;
                    // }

                    if (request.url.contains('tel:')) {
                      var _uri = Uri.parse(request.url);
                      await _launchUrl(url: _uri, appName: 'dialer');
                      return NavigationDecision.prevent;
                    }

                    //https://goo.gl/maps/UyZSVDJpDbdSJC5C6
                    if (request.url.contains('https://goo.gl/maps/')) {
                      var _uri = Uri.parse(request.url);
                      await _launchUrl(url: _uri, appName: 'url');
                      return NavigationDecision.prevent;
                    }
                    // if (request.url.contains('https://www.youtube.com/')) {
                    //   var _uri = Uri.parse(request.url);
                    //   await _launchUrl(url: _uri, appName: 'youtube');
                    //   return NavigationDecision.prevent;
                    // }

                    // if (request.url
                    //     .contains('https://www.facebook.com/ADicTEdSHop/')) {
                    //   //fbProtocolUrl : 'fb://profile/100092280981515?wtsid=wt_0mnGGt9jS12tm60fx';
                    //   //fbFallbackUrl : 'https://www.facebook.com/ADicTEdSHop/';
                    //   _launchNativeOrWebUrl(
                    //     nativeUrl:
                    //         'fb://profile/100092280981515?wtsid=wt_0mnGGt9jS12tm60fx',
                    //     webUrl: 'https://www.facebook.com/ADicTEdSHop/',
                    //     appName: 'facebook',
                    //   );
                    //   return NavigationDecision.prevent;
                    // }

                    // if (request.url.contains(
                    //     'https://instagram.com/addictedshop007?igshid=NTc4MTIwNjQ2YQ==')) {
                    //   _launchNativeOrWebUrl(
                    //     nativeUrl: 'instagram://user?username=addictedshop007',
                    //     webUrl:
                    //         'https://instagram.com/addictedshop007?igshid=NTc4MTIwNjQ2YQ==',
                    //     appName: 'instagram',
                    //   );
                    //   return NavigationDecision.prevent;
                    // }
                    return NavigationDecision.navigate;
                  },
                  onProgress: (progress) {
                    setState(() {
                      this.progress = progress / 100;
                    });
                    print('progress :' + progress.toString());
                  },
                ),
              ),
              Container(
                color: Colors.white,
                width: internet && progress <= 0.7
                    ? MediaQuery.of(context).size.width
                    : 0.0,
                child: Lottie.asset(
                  'assets/lottie/loading.json',
                  reverse: true,
                ),
              ),
              Container(
                width: internet ? 0.0 : MediaQuery.of(context).size.width,
                color: Colors.white,
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.1,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50.0),
                      child: internet
                          ? SizedBox()
                          : Lottie.asset('assets/lottie/no-internet.json'),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 50),
                      child: Text(
                        internet ? '' : 'You\'re offline!',
                        style: TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 50),
                      child: Text(
                        internet
                            ? ''
                            : 'Check your connection and try again when you\'re back online.',
                        style: TextStyle(
                          fontSize: 20.0,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                    Expanded(
                      child: SizedBox(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AlertDialog quitAppAlertDialog(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(10),
      content: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              // color: Color(0xffFFF3CD),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  //#27C7D8
                  Color(0xff27C7D8),
                  Color(0xff27D7E8),
                  Color(0xff27E7F8),
                  // Color(0xffFFF3CD),
                  // Color(0xff198754),
                ],
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
            child: Text("Quit Application?",
                style: TextStyle(fontSize: 24), textAlign: TextAlign.center),
          ),
          Positioned(
            bottom: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      "Cancel",
                      style: TextStyle(fontSize: 22.0),
                    ),
                  ),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      Color(0xff27C7D8),
                    ),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      "Yes",
                      style: TextStyle(
                        fontSize: 22.0,
                        color: Color(0xff198754),
                      ),
                    ),
                  ),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      Colors.white,
                    ),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        side: BorderSide(
                          color: Color(0xff198754),
                        ),
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    SystemNavigator.pop();
                    //exit(0);
                  },
                ),
              ],
            ),
          ),
          Positioned(
            top: -75,
            child: CircleAvatar(
              backgroundColor: Color(0xff27C7D8),
              radius: 65,
              child: Image.asset(
                "assets/images/on-exit.png",
                width: 150,
                height: 150,
              ),
            ),
          )
        ],
      ),
    );
  }
}
