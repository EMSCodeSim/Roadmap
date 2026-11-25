import 'package:flutter_test/flutter_test.dart';
import 'package:firepath/services/fireops_recommendations.dart';
void main() {
 test('ladder recommendations match topic and time', () {
 final items=FireOpsRecommendations.suggest(topic:'Ground ladder',records:[],maxMinutes:30);
 expect(items,isNotEmpty);
 expect(items.every((d)=>d.minutes.any((m)=>m<=30)),isTrue);
 });
 test('unrelated topics do not generate generic recommendations', () {
 expect(FireOpsRecommendations.suggest(topic:'unrelatedxyz',records:[]),isEmpty);
 });
}
