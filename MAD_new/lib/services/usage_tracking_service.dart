import 'package:app_usage/app_usage.dart'
    as device_usage;

import '../models/app_usage.dart'
    as model;

import '../repositories/firestore_repository.dart';

class UsageTrackingService {

  final FirestoreRepository
      _firestoreRepository;

  UsageTrackingService(
    this._firestoreRepository,
  );

  Future<void> syncUsageStats(
      String userId) async {

    try {

      DateTime endDate =
          DateTime.now();

      DateTime startDate =
          DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      );

      List<device_usage.AppUsageInfo>
          usageStats =
          await device_usage
              .AppUsage()
              .getAppUsage(
        startDate,
        endDate,
      );

      List<model.AppUsage>
          appUsageList = [];

      for (var info
          in usageStats) {

        int durationInMinutes =
            info.usage.inMinutes;

        if (durationInMinutes > 0) {

          String packageName =
              info.packageName;

          model.AppCategory category =
              model.AppCategory.neutral;

          if (packageName
                  .contains(
                      'instagram') ||
              packageName
                  .contains(
                      'facebook') ||
              packageName
                  .contains(
                      'tiktok') ||
              packageName
                  .contains(
                      'youtube') ||
              packageName
                  .contains(
                      'snapchat')) {

            category =
                model.AppCategory
                    .distracting;

          } else if (packageName
                  .contains(
                      'kindle') ||
              packageName
                  .contains(
                      'duolingo') ||
              packageName
                  .contains(
                      'notion') ||
              packageName
                  .contains(
                      'docs')) {

            category =
                model.AppCategory
                    .productive;
          }

          String appName =
              info.appName;

          appUsageList.add(

            model.AppUsage(

              id:
                  '${packageName}_${startDate.toIso8601String()}',

              userId:
                  userId,

              packageName:
                  packageName,

              appName:
                  appName,

              category:
                  category,

              durationMinutes:
                  durationInMinutes,

              date:
                  endDate,
            ),
          );
        }
      }

      if (appUsageList
          .isNotEmpty) {

        await _firestoreRepository
            .saveAppUsage(
          userId,
          appUsageList,
        );
      }

    } catch (e) {

      print(
        'Usage tracking error: $e',
      );
    }
  }
}