import 'package:flutter/material.dart';
import 'router.dart';

class CareKudosApp extends StatelessWidget {
  const CareKudosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CareKudos',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
