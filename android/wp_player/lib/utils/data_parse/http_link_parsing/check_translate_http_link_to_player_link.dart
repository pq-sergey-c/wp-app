import 'package:wp_player/utils/data_parse/http_link_parsing/types/http_link_host.dart';

String? checkTranslateHTTPLinkToPlayerLink(String link) {
  final Uri? uri = Uri.tryParse(link);
  if (uri == null) return null;

  final HTTPLinkHost? linkHost = HTTPLinkHost.fromString(uri.host);
  if (linkHost == null) return null;

  if (uri.pathSegments.length < 2) return null;

  if (!['listen', 'session'].contains(uri.pathSegments.first)) return null;

  final String connectionType = uri.pathSegments.first;
  final bool isFree = uri.pathSegments.length > 2 && uri.pathSegments[1] == 'free';
  final String uuid = uri.pathSegments.last;

  return 'wavepaths2://$connectionType/${linkHost.playerLinkPathEntry}${isFree ? '/free' : ''}/playerlib/$uuid';
}
