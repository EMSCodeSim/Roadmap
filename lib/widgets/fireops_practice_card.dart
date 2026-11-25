import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firepath/models/career_record.dart';
import 'package:firepath/services/fireops_recommendations.dart';

class FireOpsPracticeCard extends StatelessWidget {
  final String topic;
  final List<CareerRecord> records;
  final int? maxMinutes;
  const FireOpsPracticeCard({super.key, required this.topic, required this.records, this.maxMinutes});
  @override
  Widget build(BuildContext context) {
    final items = FireOpsRecommendations.suggest(topic:topic, records:records, maxMinutes:maxMinutes);
    if(items.isEmpty)return const SizedBox.shrink();
    return Card(child: Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('Recommended FireOpsSim practice',style:Theme.of(context).textTheme.titleMedium),
      Text('Matched to $topic. Suggestions are practice opportunities, not proof of competency.'),
      ...items.map((d)=>ListTile(contentPadding:EdgeInsets.zero,title:Text(d.title),subtitle:Text('${d.category} · ${d.minutes.join("/")} min options'),trailing:const Icon(Icons.open_in_new),onTap:() async {try {if(await launchUrl(d.url,mode:LaunchMode.externalApplication))return;}catch(_){}if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Unable to open FireOpsSim.')));})),
    ])));
  }
}
