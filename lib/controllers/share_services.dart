import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

class ShareServices {
  final FirebaseFunctions functions = FirebaseFunctions.instance;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;

  Future<String> referFriend(String userId) async {
    try {
      final HttpsCallable callable = functions.httpsCallable('generateShareLink');
      final result = await callable.call({'userId': userId});
      
      return result.data['shareLink'] ?? '';
    } catch (e) {
      debugPrint('Error generating share link: $e');
      return 'https://connect-675b1.web.app/refer?userId=$userId';
    }
  }

  void initDeepLinkListener(BuildContext context) {
    // Handle initial link if app was opened from a link
    _handleInitialLink(context);
    
    // Listen for links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) {
          _handleDeepLink(uri, context);
        }
      },
      onError: (err) {
        debugPrint('Deep Link Error: $err');
      },
    );
  }

  Future<void> _handleInitialLink(BuildContext context) async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        _handleDeepLink(uri, context);
      }
    } catch (e) {
      debugPrint('Failed to get initial link: $e');
    }
  }

  void _handleDeepLink(Uri uri, BuildContext context) {
    debugPrint('Received deep link: $uri');
    
    if (uri.path.contains('refer')) {
      final userId = uri.queryParameters['userId'];
      
      if (userId != null) {
        _processReferral(userId, context);
      }
    }
  }

  Future<void> _processReferral(String referrerId, BuildContext context) async {
    debugPrint('Referred by user: $referrerId');
    
    // TODO: Save referrer to your database/backend
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Welcome!'),
        content: Text('You were invited by a friend!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Get Started'),
          ),
        ],
      ),
    );
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}