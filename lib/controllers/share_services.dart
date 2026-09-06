import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';

class ShareServices {

 final dynamicLink = FirebaseDynamicLinks.instance;
   Future<String> referFriend(String userId) async {
    final DynamicLinkParameters dynamicLinkParameters = DynamicLinkParameters(
      uriPrefix: '',
      link: Uri.parse(''),
      androidParameters: const AndroidParameters(
        packageName: '',
        minimumVersion: 1,
      ),
       iosParameters: const IOSParameters(bundleId: '',minimumVersion: '1'),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: 'Secure Connect',
        description: 'secure connect',
        imageUrl: Uri.parse(
            ''),
      ),
    );

    final shortLink = await dynamicLink.buildShortLink(dynamicLinkParameters);
    return shortLink.shortUrl.toString();
  }

  void initDynamicLinksForRefer(BuildContext context) async {
    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) async {
      final Uri deepLink = dynamicLinkData.link;

      final queryParams = deepLink.queryParameters;
      final userId = queryParams['userId'];
     
    }).onError((error) {
      debugPrint('Dynamic Link Error: $error');
    });
  }
}
