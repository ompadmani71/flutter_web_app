import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage()
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey BrowserKey = GlobalKey();
  final TextEditingController searchController = TextEditingController();

  String url = "";
  double progress = 0;

  List Bookmarks = [];

  InAppWebViewController? webViewController;
  late PullToRefreshController pullToRefreshController;

  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
    ),
    android: AndroidInAppWebViewOptions(
      useHybridComposition: true,
    ),
    ios: IOSInAppWebViewOptions(
      allowsInlineMediaPlayback: true,
    ),
  );

  refreshController() async {
    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.grey.shade700,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          await webViewController!.reload();
        } else if (Platform.isIOS) {
          await webViewController!.loadUrl(
            urlRequest: URLRequest(
              url: Uri.parse(
                "${await webViewController?.getUrl()}",
              ),
            ),
          );
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    refreshController();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async{
          await webViewController!.goBack();
          return false;
        },
        child: Scaffold(
          body: Column(
            children: [
              Expanded(
                flex: 1,
                child: TextField(
                  controller: searchController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    hintText: "Search",
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.grey.shade700,
                    ),
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    suffixIcon: IconButton(
                      onPressed: () async {
                        // pullToRefreshController.endRefreshing();
                        (await pullToRefreshController.isRefreshing())
                            ? pullToRefreshController.endRefreshing()
                            : searchController.clear();
                      },
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  onSubmitted: (val) async {
                    Uri uri = Uri.parse(val);
                    if (uri.scheme.isEmpty) {
                      uri = Uri.parse("https://www.google.com/search?q=" + val);
                    }
                    await webViewController!.loadUrl(
                      urlRequest: URLRequest(url: uri),
                    );
                  },
                ),
              ),
              (progress < 1)
                  ? LinearProgressIndicator(
                value: progress,
              )
                  : Container(),
              Expanded(
                flex: 11,
                child: InAppWebView(
                  key: BrowserKey,
                  pullToRefreshController: pullToRefreshController,
                  initialOptions: options,
                  onWebViewCreated: (controller) {
                    webViewController = controller;
                  },
                  initialUrlRequest: URLRequest(
                    url: Uri.parse("https://www.google.com/"),
                  ),
                  onLoadStart: (controller, uri) {
                    setState(() {
                      searchController.text =
                          uri!.scheme.toString() + "://" + uri.host + uri.path;
                    });
                  },
                  onLoadStop: (controller, uri) {
                    pullToRefreshController.endRefreshing();
                    setState(() {
                      searchController.text =
                          uri!.scheme.toString() + "://" + uri.host + uri.path;
                    });
                  },
                  androidOnPermissionRequest:
                      (controller, origin, resources) async {
                    return PermissionRequestResponse(
                        resources: resources,
                        action: PermissionRequestResponseAction.GRANT);
                  },
                  onProgressChanged: (controller, val) {
                    if (val == 100) {
                      pullToRefreshController.endRefreshing();
                    }
                    setState(() {
                      progress = val / 100;
                    });
                  },
                ),
              ),
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.home,
                        color: Colors.grey.shade700,
                      ),
                      onPressed: () async {
                        await webViewController!.loadUrl(
                          urlRequest: URLRequest(
                            url: Uri.parse("https://www.google.com/"),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_outlined,
                        color: Colors.grey.shade700,
                      ),
                      onPressed: () async {
                        await webViewController!.goBack();
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh_sharp,
                        color: Colors.grey.shade700,
                      ),
                      onPressed: () async {
                        if (Platform.isAndroid) {
                          await webViewController!.reload();
                        } else if (Platform.isIOS) {
                          await webViewController!.loadUrl(
                            urlRequest: URLRequest(
                              url: Uri.parse(
                                "${await webViewController?.getUrl()}",
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey.shade700,
                      ),
                      onPressed: () async {
                        await webViewController!.goForward();
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.bookmark_add,
                        color: Colors.grey.shade700,
                      ),
                      onPressed: () async {
                        Uri? uri = await webViewController!.getUrl();
                        String MyURL =
                            uri!.scheme.toString() + "://" + uri.host + uri.path;

                        setState(() {
                          Bookmarks.add(MyURL);
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Added Successfully in Bookmark .. !!"),
                            duration: Duration(milliseconds: 500),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.list_alt_outlined,
                        color: Colors.grey.shade700,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Center(
                                child: Text("My BookMarks"),
                              ),
                              content: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: Bookmarks.map(
                                      (e) => Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: GestureDetector(
                                      onTap: () async {
                                        await webViewController!.loadUrl(
                                          urlRequest: URLRequest(
                                            url: Uri.parse(e),
                                          ),
                                        );
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(e),
                                    ),
                                  ),
                                ).toList(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          resizeToAvoidBottomInset: false,
        ),
      ),
    );
  }
}
