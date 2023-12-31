import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:yqplaymusic/router/routeconfig.dart';

import 'generated/l10n.dart';
import 'common/utils/platformutils.dart';

void main() {
  runApp(const MyApp());

  // 将http请求的userAgent设置为空，防止网易云音乐返回403
  HttpClient httpClient = HttpClient();
  httpClient.userAgent = "";

  if (PlatformUtils.isAndroid) {
    SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    );
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(720, 1080),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          // 应用中文
          locale: const Locale("zh", "CN"),
          title: 'Flutter Demo',
          // 隐藏debug
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: "PingFang",
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
            useMaterial3: true,
          ),
          getPages: RouteConfig.getPages,
          // 初始化主页
          initialRoute: RouteConfig.main,
        );
      },
    );
  }
}
