import 'package:wp_player/utils/data_check/is_json_list_of_dicts.dart';

bool isJsonListOfDictsOrNull(dynamic json) {
  return (json == null) || isJsonListOfDicts(json);
}
