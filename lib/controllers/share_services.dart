import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';

class ShareServices {

 final dynamicLink = FirebaseDynamicLinks.instance;
   Future<String> referFriend(String userId) async {
    final DynamicLinkParameters dynamicLinkParameters = DynamicLinkParameters(
      uriPrefix: 'https://secureconnectapp.page.link',
      link: Uri.parse('https://secureconnectapp.page.link?userId=$userId'),
      androidParameters: const AndroidParameters(
        packageName: 'com.app.secureconnect',
        minimumVersion: 1,
      ),
       iosParameters: const IOSParameters(bundleId: 'com.app.secureconnect',minimumVersion: '1'),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: 'Secure Connect',
        description: 'secure connect',
        imageUrl: Uri.parse(
            'https://firebasestorage.googleapis.com/v0/b/voisbe-1f7b6.appspot.com/o/voisbe_logo.png?alt=media&token=3b3b3b3b-3b3b-3b3b-3b3b-3b3b3b3b3b3b'),
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