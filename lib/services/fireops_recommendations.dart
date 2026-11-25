import 'package:firepath/models/career_record.dart';

class FireOpsSuggestion {
  final String id, title, category;
  final List<int> minutes;
  const FireOpsSuggestion(this.id, this.title, this.category, this.minutes);
  Uri get url => Uri.https('fireopssim.com', '/drill-library.html', {'q': title});
}
class FireOpsRecommendations {
  static const catalog = <FireOpsSuggestion>[
    FireOpsSuggestion('attack-line-deployment', 'Attack Line Deployment & Advancement', 'Fire Attack', [20,30,45]),
    FireOpsSuggestion('search-known-victim', 'Primary Search — Known Victim Location', 'Search & Rescue', [30,45]),
    FireOpsSuggestion('mayday-recognition', 'Mayday Recognition & Radio Discipline', 'Firefighter Survival', [20,30]),
    FireOpsSuggestion('scba-emergency', 'SCBA Emergency Procedures & Air Awareness', 'Firefighter Survival', [20,30]),
    FireOpsSuggestion('ground-ladder-decision', 'Ground Ladder Selection, Raise & Placement', 'Ladders', [20,30]),
    FireOpsSuggestion('water-supply-transition', 'Tank-to-Sustained Water Supply Transition', 'Driver / Operator', [30,45]),
    FireOpsSuggestion('first-due-sizeup', 'First-Due Size-Up & Initial Action Plan', 'Command', [10,20,30]),
    FireOpsSuggestion('gross-decon', 'Post-Fire Gross Decontamination & Clean Transport', 'Health & Safety', [20,30]),
    FireOpsSuggestion('firefighter-down-ppe-removal', 'Unresponsive Firefighter — PPE/SCBA Removal Transition', 'Firefighter Survival', [30,45]),
    FireOpsSuggestion('building-walkaround', 'District Building Construction Walkaround', 'Company / Station', [30,45,60]),
    FireOpsSuggestion('forcible-entry-sizeup', 'Forcible Entry Size-Up & Tool Selection', 'Truck / Tools', [20,30,45]),
    FireOpsSuggestion('hose-flow-kinks', 'Hose Kinks, Stream Quality & Flow Recognition', 'Fire Attack', [20,30]),
    FireOpsSuggestion('flow-path-door-control', 'Flow Path, Door Control & Coordinated Ventilation', 'Fire Dynamics', [20,30,45]),
    FireOpsSuggestion('rit-firefighter-rescue', 'RIT/RIC Firefighter Location, Packaging & Removal', 'Firefighter Survival', [30,45,60]),
    FireOpsSuggestion('apparatus-placement', 'Apparatus Placement Decision Tabletop', 'Driver / Operator', [10,20,30]),
    FireOpsSuggestion('aerial-positioning', 'Aerial Positioning & Scrub-Area Decision Drill', 'Aerial Operations', [20,30,45]),
    FireOpsSuggestion('wui-structure-triage', 'WUI Structure Triage & Go/No-Go Decision', 'Wildland / WUI', [20,30,45]),
    FireOpsSuggestion('hazmat-first-due', 'HazMat First-Due Recognition, Isolation & Information', 'HazMat', [20,30]),
    FireOpsSuggestion('scba-radio-comms', 'SCBA Radio Communications Under Workload', 'Communications', [20,30]),
    FireOpsSuggestion('multi-company-coordinated-attack', 'Coordinated Attack: Suppression, Search & Ventilation', 'Multi-Company', [45,60]),
    FireOpsSuggestion('research-water-mapping', 'Water Mapping Observation', 'Fire Attack', [10,20,30]),
    FireOpsSuggestion('research-basement-sizeup', 'Below-Grade Fire Recognition', 'Building Construction', [10,20,30]),
    FireOpsSuggestion('research-attic-sizeup', 'Attic Fire Decision Tabletop', 'Building Construction', [10,20,30]),
    FireOpsSuggestion('research-stream-air', 'Hose Stream Air Movement', 'Fire Attack', [10,20,30]),
    FireOpsSuggestion('research-search-coordination', 'Search and Suppression Coordination', 'Search & Rescue', [10,20,30]),
    FireOpsSuggestion('research-engineered-floor', 'Engineered Floor Hazard Recognition', 'Building Construction', [10,20,30]),
    FireOpsSuggestion('research-solar-array', 'Photovoltaic System Recognition', 'HazMat', [10,20,30]),
    FireOpsSuggestion('research-battery-hazards', 'Lithium-Ion Battery Hazard Recognition', 'HazMat', [10,20,30]),
    FireOpsSuggestion('research-refrigerant', 'Flammable Refrigerant Awareness', 'HazMat', [10,20,30]),
    FireOpsSuggestion('research-training-exposure', 'Training Exposure Controls', 'Firefighter Safety', [10,20,30]),
    FireOpsSuggestion('station-1-1', 'Hosebed inventory', 'Engine Operations', [10,20,30]),
    FireOpsSuggestion('station-1-2', 'Stretch estimation', 'Engine Operations', [10,20,30]),
    FireOpsSuggestion('station-1-3', 'Dry stairwell stretch', 'Engine Operations', [10,20,30]),
    FireOpsSuggestion('station-1-4', 'Nozzle inspection', 'Engine Operations', [10,20,30]),
    FireOpsSuggestion('station-1-5', 'Hose coupling inspection', 'Engine Operations', [10,20,30]),
    FireOpsSuggestion('station-1-6', 'Standpipe preplan', 'Engine Operations', [10,20,30]),
    FireOpsSuggestion('station-1-7', 'Exposure protection priorities', 'Engine Operations', [10,20,30]),
    FireOpsSuggestion('station-1-8', 'Overhaul hazard survey', 'Engine Operations', [10,20,30]),
    FireOpsSuggestion('station-1-9', 'Foam inventory review', 'Engine Operations', [10,20,30]),
    FireOpsSuggestion('station-1-10', 'Fire attack communications', 'Engine Operations', [10,20,30]),
    FireOpsSuggestion('station-2-1', 'Ladder inventory and inspection', 'Truck Operations', [10,20,30]),
    FireOpsSuggestion('station-2-2', 'Ladder reach planning', 'Truck Operations', [10,20,30]),
    FireOpsSuggestion('station-2-3', 'Window access assessment', 'Truck Operations', [10,20,30]),
    FireOpsSuggestion('station-2-4', 'Door construction identification', 'Truck Operations', [10,20,30]),
    FireOpsSuggestion('station-2-5', 'Hand tool inspection', 'Truck Operations', [10,20,30]),
    FireOpsSuggestion('station-2-6', 'Ventilation opening inventory', 'Truck Operations', [10,20,30]),
    FireOpsSuggestion('station-2-7', 'Roof construction recognition', 'Truck Operations', [10,20,30]),
    FireOpsSuggestion('station-2-8', 'Thermal imager familiarization', 'Truck Operations', [10,20,30]),
    FireOpsSuggestion('station-2-9', 'Secondary search documentation', 'Truck Operations', [10,20,30]),
    FireOpsSuggestion('station-2-10', 'Salvage planning', 'Truck Operations', [10,20,30]),
    FireOpsSuggestion('station-3-1', 'Daily apparatus inspection', 'Driver / Operator', [10,20,30]),
    FireOpsSuggestion('station-3-2', 'Pump panel identification', 'Driver / Operator', [10,20,30]),
    FireOpsSuggestion('station-3-3', 'Friction loss worksheet', 'Driver / Operator', [10,20,30]),
    FireOpsSuggestion('station-3-4', 'Elevation pressure worksheet', 'Driver / Operator', [10,20,30]),
    FireOpsSuggestion('station-3-5', 'Hydrant preplan mapping', 'Driver / Operator', [10,20,30]),
    FireOpsSuggestion('station-3-6', 'Tender shuttle tabletop', 'Driver / Operator', [10,20,30]),
    FireOpsSuggestion('station-3-7', 'Relay pumping tabletop', 'Driver / Operator', [10,20,30]),
    FireOpsSuggestion('station-3-8', 'Backing communication rehearsal', 'Driver / Operator', [10,20,30]),
    FireOpsSuggestion('station-3-9', 'Apparatus clearance survey', 'Driver / Operator', [10,20,30]),
    FireOpsSuggestion('station-3-10', 'Pump fault recognition tabletop', 'Driver / Operator', [10,20,30]),
    FireOpsSuggestion('station-4-1', 'SCBA cylinder inventory', 'Firefighter Survival', [10,20,30]),
    FireOpsSuggestion('station-4-2', 'Air consumption planning', 'Firefighter Survival', [10,20,30]),
    FireOpsSuggestion('station-4-3', 'PASS device familiarization', 'Firefighter Survival', [10,20,30]),
    FireOpsSuggestion('station-4-4', 'Emergency contact information', 'Firefighter Survival', [10,20,30]),
    FireOpsSuggestion('station-4-5', 'Crew integrity tabletop', 'Firefighter Survival', [10,20,30]),
    FireOpsSuggestion('station-4-6', 'Emergency exit recognition', 'Firefighter Survival', [10,20,30]),
    FireOpsSuggestion('station-4-7', 'Rehab recognition', 'Firefighter Survival', [10,20,30]),
    FireOpsSuggestion('station-4-8', 'Radio emergency button review', 'Firefighter Survival', [10,20,30]),
    FireOpsSuggestion('station-4-9', 'Accountability board reconciliation', 'Firefighter Survival', [10,20,30]),
    FireOpsSuggestion('station-4-10', 'Near-miss discussion', 'Firefighter Survival', [10,20,30]),
    FireOpsSuggestion('station-5-1', 'Vehicle hazard survey', 'Technical Rescue', [10,20,30]),
    FireOpsSuggestion('station-5-2', 'Cribbing inventory', 'Technical Rescue', [10,20,30]),
    FireOpsSuggestion('station-5-3', 'Extrication access planning', 'Technical Rescue', [10,20,30]),
    FireOpsSuggestion('station-5-4', 'Rope equipment inspection', 'Technical Rescue', [10,20,30]),
    FireOpsSuggestion('station-5-5', 'Knot recognition', 'Technical Rescue', [10,20,30]),
    FireOpsSuggestion('station-5-6', 'Mechanical advantage worksheet', 'Technical Rescue', [10,20,30]),
    FireOpsSuggestion('station-5-7', 'Confined space recognition', 'Technical Rescue', [10,20,30]),
    FireOpsSuggestion('station-5-8', 'Trench hazard recognition', 'Technical Rescue', [10,20,30]),
    FireOpsSuggestion('station-5-9', 'Water rescue size-up', 'Technical Rescue', [10,20,30]),
    FireOpsSuggestion('station-5-10', 'Patient movement planning', 'Technical Rescue', [10,20,30]),
    FireOpsSuggestion('station-6-1', 'Shift training needs review', 'Company Officer', [10,20,30]),
    FireOpsSuggestion('station-6-2', 'Training safety briefing', 'Company Officer', [10,20,30]),
    FireOpsSuggestion('station-6-3', 'Transfer of command tabletop', 'Company Officer', [10,20,30]),
    FireOpsSuggestion('station-6-4', 'Resource request exercise', 'Company Officer', [10,20,30]),
    FireOpsSuggestion('station-6-5', 'Progress report practice', 'Company Officer', [10,20,30]),
    FireOpsSuggestion('station-6-6', 'Preincident plan review', 'Company Officer', [10,20,30]),
    FireOpsSuggestion('station-6-7', 'Coaching a skill deficiency', 'Company Officer', [10,20,30]),
    FireOpsSuggestion('station-6-8', 'After-action facilitation', 'Company Officer', [10,20,30]),
    FireOpsSuggestion('station-6-9', 'Multi-company staging tabletop', 'Company Officer', [10,20,30]),
    FireOpsSuggestion('station-6-10', 'Training documentation audit', 'Company Officer', [10,20,30]),
    FireOpsSuggestion('station-7-1', 'Fire weather interpretation', 'Wildland / HazMat', [10,20,30]),
    FireOpsSuggestion('station-7-2', 'LCES tabletop', 'Wildland / HazMat', [10,20,30]),
    FireOpsSuggestion('station-7-3', 'WUI access survey', 'Wildland / HazMat', [10,20,30]),
    FireOpsSuggestion('station-7-4', 'Wildland equipment inventory', 'Wildland / HazMat', [10,20,30]),
    FireOpsSuggestion('station-7-5', 'Wildland radio plan', 'Wildland / HazMat', [10,20,30]),
    FireOpsSuggestion('station-7-6', 'ERG lookup practice', 'Wildland / HazMat', [10,20,30]),
    FireOpsSuggestion('station-7-7', 'SDS information retrieval', 'Wildland / HazMat', [10,20,30]),
    FireOpsSuggestion('station-7-8', 'Gas monitor familiarization', 'Wildland / HazMat', [10,20,30]),
    FireOpsSuggestion('station-7-9', 'Decontamination layout tabletop', 'Wildland / HazMat', [10,20,30]),
    FireOpsSuggestion('station-7-10', 'HazMat notification exercise', 'Wildland / HazMat', [10,20,30]),
  ];
  static List<FireOpsSuggestion> suggest({required String topic, required List<CareerRecord> records, int? maxMinutes, DateTime? now}) {
    final words = RegExp(r'[a-z]+').allMatches(topic.toLowerCase()).map((m)=>m.group(0)!).where((w)=>w.length>3 && !const {'fire','firefighter','training','practice','career','requirement','level','skills','competency'}.contains(w)).toSet();
    final aliases = <String,List<String>>{'officer':['command','leadership','company officer'],'driver':['pump','apparatus','water supply','driver'],'instructor':['instructor','coaching','training safety'],'rescue':['search','rescue'],'survival':['mayday','scba','survival'],'hazmat':['hazmat','hazardous'],'ladder':['ladder','ladders'],'ventilation':['ventilation','flow path']};
    final terms = {...words, for(final w in words) ...?aliases[w]};
    final cutoff = (now ?? DateTime.now()).subtract(const Duration(days:30));
    final recent = records.where((r)=>!r.date.isBefore(cutoff)).map((r)=>r.details['drillId']).toSet();
    int score(FireOpsSuggestion d) {
      final hay = '${d.title} ${d.category}'.toLowerCase();
      return terms.where((t)=>hay.contains(t)).length;
    }
    final matches = catalog.where((d)=>score(d)>0 && (maxMinutes==null || d.minutes.any((m)=>m<=maxMinutes))).toList();
    matches.sort((a,b){final recentOrder=(recent.contains(a.id)?1:0).compareTo(recent.contains(b.id)?1:0);if(recentOrder!=0)return recentOrder;final relevance=score(b).compareTo(score(a));return relevance!=0?relevance:a.title.compareTo(b.title);});
    return matches.take(3).toList();
  }
}
