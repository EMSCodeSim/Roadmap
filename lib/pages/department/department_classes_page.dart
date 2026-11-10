import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/state/app_mode_controller.dart';
import 'package:firepath/state/department_inbox_controller.dart';

import 'package:firepath/services/responder_roadmap_api.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/services/training_time_calculator.dart';
import 'package:firepath/pages/department/class_task_book_link_card.dart';
import 'package:firepath/widgets/training_sheet/training_sheet_cards.dart';

const _emsCeCategories = <String>[
  'Airway', 'Cardiology', 'Trauma', 'Medical', 'Operations',
  'Pediatric / Obstetrics', 'Local / State', 'Individual',
];

String _trainingTemplateSummary(DepartmentTrainingSheetTemplate template) {
  final rosterFields = template.customFields
      .where((field) => field['appliesTo'] == 'ROSTER')
      .map((field) => field['label']?.toString() ?? 'Roster field')
      .toList(growable: false);
  final resultFields = template.customFields
      .where((field) => field['appliesTo'] != 'ROSTER')
      .map((field) => field['label']?.toString() ?? 'Result field')
      .toList(growable: false);
  final setup = <String>[
    if (template.checklistVersionId.isNotEmpty) 'Skills checklist',
    if (template.gradingConfig['writtenTestEnabled'] == true) 'Written test',
    if (template.gradingConfig['ccfEnabled'] == true) 'CCF score',
    if (rosterFields.isNotEmpty) 'Roster fields: ${rosterFields.join(', ')}',
    if (resultFields.isNotEmpty) 'Result fields: ${resultFields.join(', ')}',
    if (template.ceCredits.isNotEmpty)
      'EMS CE: ${template.ceCredits.map((credit) => '${credit['category']} ${credit['hours']} hr').join(', ')}',
    if (template.creditHours > 0) '${template.creditHours} training hr',
    if (template.selfRegistration) 'QR roster',
  ];
  return [
    if (template.defaultTitle.trim().isNotEmpty) template.defaultTitle.trim(),
    template.trainingCategory.replaceAll('_', ' '),
    ...setup,
  ].join(' · ');
}

class DepartmentClassesPage extends StatefulWidget {
  const DepartmentClassesPage({super.key, this.openCreateTraining = false});
  final bool openCreateTraining;
  @override
  State<DepartmentClassesPage> createState() => _DepartmentClassesPageState();
}

class _DepartmentClassesPageState extends State<DepartmentClassesPage> {
  final _api = ResponderRoadmapApi();
  List<DepartmentClassSummary>? _classes;
  DepartmentClassSetup? _setup;
  String? _error;
  bool _initialCreateOpened = false;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final rows = await _api.listClasses();
      DepartmentClassSetup? setup;
      try { setup = await _api.getClassSetup(); } catch (_) {}
      if (!mounted) return;
      setState(() { _classes = rows; _setup = setup; _error = null; });
      if (widget.openCreateTraining && setup != null && !_initialCreateOpened) {
        _initialCreateOpened = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _createTraining();
        });
      }
    } catch (e) {
      if (mounted) setState(() { _classes = const []; _error = e.toString(); });
    }
  }

  Future<void> _createTraining() async {
    final setup = _setup;
    if (setup == null) return;
    DepartmentTrainingSheetTemplate? selected;
    try {
      final templates = await _api.listTrainingSheetTemplates();
      if (!mounted) return;
      String category = '';
      selected = await showModalBottomSheet<DepartmentTrainingSheetTemplate?>(
        context: context, useSafeArea: true, isScrollControlled: true,
        builder: (sheetContext) => StatefulBuilder(builder: (sheetContext, update) =>
          SafeArea(child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(child: Text('1. Choose training topic', style: Theme.of(sheetContext).textTheme.titleLarge)),
                TextButton.icon(onPressed: () => sheetContext.pop<DepartmentTrainingSheetTemplate?>(null), icon: const Icon(Icons.close_rounded), label: const Text('Cancel')),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Topic'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('All categories')),
                  DropdownMenuItem(value: 'EMS', child: Text('EMS')),
                  DropdownMenuItem(value: 'CPR', child: Text('CPR')),
                  DropdownMenuItem(value: 'FIRE', child: Text('Fire')),
                  DropdownMenuItem(value: 'HAZMAT', child: Text('HazMat')),
                  DropdownMenuItem(value: 'DRIVER', child: Text('Driver Operator')),
                  DropdownMenuItem(value: 'FACILITY', child: Text('Facility')),
                  DropdownMenuItem(value: 'OFFICER', child: Text('Officer')),
                  DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                ],
                onChanged: (value) => update(() => category = value ?? ''),
              ),
              const SizedBox(height: 12),
              Text('2. Choose department template', style: Theme.of(sheetContext).textTheme.titleMedium),
              SizedBox(height: 300, child: ListView(children: [
                if (templates.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('No saved department templates yet. Starter examples on the web dashboard must be reviewed and saved to your department before they appear here. You can still create a blank Training Sheet.')),
                if (templates.isNotEmpty && !templates.any((t) => category.isEmpty || t.topic == category)) const Padding(padding: EdgeInsets.all(12), child: Text('No saved templates match this topic. Select All categories or start a blank Training Sheet.')),
                ListTile(leading: const Icon(Icons.note_add_outlined), title: const Text('Blank Training Sheet'), onTap: () => sheetContext.pop<DepartmentTrainingSheetTemplate?>(null)),
                ...templates.where((t) => category.isEmpty || t.topic == category).map((t) =>
                  ListTile(leading: const Icon(Icons.copy_all_outlined), title: Text(t.name),
                    subtitle: Text(_trainingTemplateSummary(t), maxLines: 3, overflow: TextOverflow.ellipsis),
                    onTap: () => sheetContext.pop<DepartmentTrainingSheetTemplate?>(t))),
              ])),
            ]),
          )),
        ),
      );
    } catch (_) {
      // Template API may not be deployed yet; Blank remains a safe fallback.
    }
    if (!mounted) return;
    if (selected == null) {
      final templatesAvailable = await _api.listTrainingSheetTemplates().then((v)=>v.isNotEmpty).catchError((_)=>false);
      if (templatesAvailable && mounted) {
        // A null result can mean Blank or the picker was dismissed. Ask explicitly.
        final blank = await showDialog<bool>(context: context, builder: (dialogContext)=>AlertDialog(title:const Text('Blank Training Sheet?'),content:const Text('Start without a saved template?'),actions:[TextButton(onPressed:()=>dialogContext.pop(false),child:const Text('Cancel')),FilledButton(onPressed:()=>dialogContext.pop(true),child:const Text('Start Blank'))]));
        if(blank!=true)return;
      }
    }
    if (!mounted) return;
    final created = await showModalBottomSheet<String>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => _CreateTrainingSheet(api: _api, setup: setup, template: selected));
    if (created != null && mounted) {
      // Open the new class immediately. The detail route uses qr=1 to display
      // the live QR and Print QR Code actions as soon as the class loads.
      await context.push('${AppRoutes.departmentTrainingSheets}/$created?qr=1');
      if (mounted) await _load();
    }
  }


  Future<void> _configureAgency() async {
    try {
      final current=await _api.getDepartmentConfiguration();
      if(!mounted)return;
      final selected=await showModalBottomSheet<String>(
        context:context,useSafeArea:true,
        builder:(context)=>Padding(
          padding:const EdgeInsets.all(20),
          child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
            Text('Department setup',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900)),
            const SizedBox(height:6),const Text('Choose a starting preset. Existing custom capabilities are preserved and everything remains editable.'),
            const SizedBox(height:14),
            for(final item in const [('FIRE','Fire'),('EMS','EMS'),('FIRE_EMS','Fire & EMS')])
              ListTile(title:Text(item.$2),trailing:current.agencyType==item.$1?const Icon(Icons.check_circle):const Icon(Icons.chevron_right),onTap:()=>context.pop(item.$1)),
          ]),
        ),
      );
      if(selected==null||!mounted)return;
      const defaults={
        'FIRE':['STRUCTURAL_FIRE','DRIVER_OPERATOR'],
        'EMS':['EMS_BLS','EMS_ALS'],
        'FIRE_EMS':['STRUCTURAL_FIRE','DRIVER_OPERATOR','EMS_BLS','EMS_ALS'],
      };
      final merged=<String>{...current.operationalCapabilities,...(defaults[selected]??const[])};
      await _api.updateDepartmentConfiguration(agencyType:selected,operationalCapabilities:merged.toList(),customCapabilities:current.customCapabilities);
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Department preset updated. Existing capabilities were preserved.')));
    }catch(e){if(mounted)setState(()=>_error=e.toString());}
  }

  Future<void> _manageTemplates() async {
    final setup=_setup; if(setup==null)return;
    await Navigator.of(context).push(MaterialPageRoute(builder:(_)=>_TrainingSheetTemplatesPage(api:_api,setup:setup,canManage:context.read<AppModeController>().isAdmin)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Training Sheets'), actions: [if (context.watch<AppModeController>().isAdmin) IconButton(tooltip:'Department setup',onPressed:_configureAgency,icon:const Icon(Icons.tune_rounded)), if (_setup != null) IconButton(tooltip: 'Browse Training Sheet templates', onPressed: _manageTemplates, icon: const Icon(Icons.library_books_outlined)), if ((context.watch<AppModeController>().isInstructor || context.watch<AppModeController>().isAdmin) && _setup != null) IconButton(tooltip: 'Create Training Sheet', onPressed: _createTraining, icon: const Icon(Icons.add_rounded))]),
    body: _classes == null ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Training Sheets', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6), Text((context.watch<AppModeController>().isInstructor || context.watch<AppModeController>().isAdmin) ? 'Run the full field workflow here: create Training Sheet → QR/roster → attendance & skills → review → instructor approval. RMS entry remains a separate department-record step.' : 'Your assigned rosters and skill checklists.'),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        if (_classes!.any((row) => row.status != 'COMPLETE')) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('Needs Attention', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                  Text('${_classes!.where((row) => row.status != 'COMPLETE').length}', style: const TextStyle(fontWeight: FontWeight.w900)),
                ]),
                const SizedBox(height: 2),
                Text('Needs Attention means it’s not finished yet or needs a next step (review, approval, or RMS entry).', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ..._classes!.where((row) => row.status != 'COMPLETE').take(2).map((row) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.groups_2_outlined),
                  title: Text(row.title),
                  subtitle: Text('${row.completeCount} of ${row.rosterCount} complete · ${row.status}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DepartmentClassDetailPage(classId: row.id))),
                )),
              ]),
            ),
          ),
        ],
        if ((context.watch<AppModeController>().isInstructor || context.watch<AppModeController>().isAdmin) && _setup != null) ...[const SizedBox(height: 14), FilledButton.icon(onPressed: _createTraining, icon: const Icon(Icons.add_rounded), label: const Text('Create Training Sheet'))],
        const SizedBox(height: 16),
        if (_classes!.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No classes are assigned to you yet. Classes you create, teach, or proctor will appear here.'))),
        ..._classes!.map((row) => Card(child: ListTile(
          contentPadding: const EdgeInsets.all(14), leading: const Icon(Icons.fact_check_outlined), title: Text(row.title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('${row.checklistTitle}\n${row.completeCount} of ${row.rosterCount} students complete · ${row.status}'), isThreeLine: true,
          trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DepartmentClassDetailPage(classId: row.id))),
        ))),
      ]),
    ),
  );
}



class _TrainingSheetTemplatesPage extends StatefulWidget {
  const _TrainingSheetTemplatesPage({required this.api,required this.setup,required this.canManage});
  final ResponderRoadmapApi api; final DepartmentClassSetup setup; final bool canManage;
  @override State<_TrainingSheetTemplatesPage> createState()=>_TrainingSheetTemplatesPageState();
}
class _TrainingSheetTemplatesPageState extends State<_TrainingSheetTemplatesPage>{
  List<DepartmentTrainingSheetTemplate>? rows; String? error;
  @override void initState(){super.initState();load();}
  Future<void> load()async{try{final v=await widget.api.listTrainingSheetTemplates();if(mounted)setState((){rows=v;error=null;});}catch(e){if(mounted)setState((){rows=[];error=e.toString();});}}
  Future<void> add()async{
    final name=TextEditingController(),title=TextEditingController(),hours=TextEditingController(),location=TextEditingController(),notes=TextEditingController();
    String category='COMPANY',checklist=''; bool qr=true;
    final ok=await showDialog<bool>(context:context,builder:(context)=>StatefulBuilder(builder:(context,setLocal)=>AlertDialog(
      title:const Text('New Training Sheet Template'),scrollable:true,content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:name,decoration:const InputDecoration(labelText:'Template name *')),
        const SizedBox(height:10),TextField(controller:title,decoration:const InputDecoration(labelText:'Default training title')),
        const SizedBox(height:10),DropdownButtonFormField<String>(initialValue:category,decoration:const InputDecoration(labelText:'Category'),items:const ['COMPANY','EMS','FACILITY','DRIVER','HAZMAT','OFFICER','OTHER'].map((v)=>DropdownMenuItem(value:v,child:Text(v.replaceAll('_',' ')))).toList(),onChanged:(v)=>setLocal(()=>category=v??'COMPANY')),
        const SizedBox(height:10),DropdownButtonFormField<String>(initialValue:checklist,decoration:const InputDecoration(labelText:'Checklist'),items:[const DropdownMenuItem(value:'',child:Text('Attendance only')),...widget.setup.checklists.map((v)=>DropdownMenuItem(value:v['id']?.toString()??'',child:Text(v['title']?.toString()??'Checklist')))],onChanged:(v)=>setLocal(()=>checklist=v??'')),
        const SizedBox(height:10),TextField(controller:hours,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Default hours')),
        const SizedBox(height:10),TextField(controller:location,decoration:const InputDecoration(labelText:'Default location')),
        const SizedBox(height:10),TextField(controller:notes,maxLines:3,decoration:const InputDecoration(labelText:'Default notes')),
        SwitchListTile(contentPadding:EdgeInsets.zero,value:qr,onChanged:(v)=>setLocal(()=>qr=v),title:const Text('QR self-registration')),
      ]),actions:[TextButton(onPressed:()=>context.pop(false),child:const Text('Cancel')),FilledButton(onPressed:()=>context.pop(true),child:const Text('Save Template'))])));
    if(ok!=true||name.text.trim().isEmpty)return;
    try{await widget.api.createTrainingSheetTemplate(name:name.text,defaultTitle:title.text,trainingCategory:category,creditHours:double.tryParse(hours.text)??0,checklistVersionId:checklist,location:location.text,notes:notes.text,requiredFields:widget.setup.requiredFields,selfRegistration:qr);await load();}catch(e){if(mounted)setState(()=>error=e.toString());}
  }
  Future<void> archive(DepartmentTrainingSheetTemplate t)async{final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Archive template?'),content:Text('Archive "${t.name}"? Existing training records are not affected.'),actions:[TextButton(onPressed:()=>c.pop(false),child:const Text('Cancel')),FilledButton(onPressed:()=>c.pop(true),child:const Text('Archive'))]))??false;if(!ok)return;try{await widget.api.archiveTrainingSheetTemplate(t.id);await load();}catch(e){if(mounted)setState(()=>error=e.toString());}}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Training Sheet Templates')),floatingActionButton:widget.canManage ? FloatingActionButton.extended(onPressed:add,icon:const Icon(Icons.add),label:const Text('New Template')) : null,body:rows==null?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(16),children:[
    const Text('Saved department templates are shared between the web dashboard and this app. Starter examples on the web must first be saved as department templates. Attendance, results and signatures are never copied from a template.'),
    if(error!=null)Padding(padding:const EdgeInsets.only(top:10),child:Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error))),
    const SizedBox(height:12),
    if(rows!.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(18),child:Text('No saved department templates yet. An administrator can review starter examples in the web Training Sheet Template Library and save them to the department. Pull down to refresh after saving.'))),
    ...rows!.map((t)=>Card(child:ListTile(leading:const Icon(Icons.description_outlined),title:Text(t.name,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text([t.defaultTitle,t.trainingCategory.replaceAll('_',' '),if(t.creditHours>0)'${t.creditHours} hr'].where((v)=>v.isNotEmpty).join(' · ')),trailing:widget.canManage ? PopupMenuButton<String>(onSelected:(v){if(v=='archive')archive(t);},itemBuilder:(_)=>const [PopupMenuItem(value:'archive',child:Text('Archive'))]) : null))),
  ])));
}

class _CreateTrainingSheet extends StatefulWidget {
  const _CreateTrainingSheet({required this.api, required this.setup, this.template});
  final ResponderRoadmapApi api;
  final DepartmentClassSetup setup;
  final DepartmentTrainingSheetTemplate? template;
  @override State<_CreateTrainingSheet> createState() => _CreateTrainingSheetState();
}

class _CreateTrainingSheetState extends State<_CreateTrainingSheet> {
  final title = TextEditingController(), location = TextEditingController(), notes = TextEditingController(), hours = TextEditingController();
  bool busy = false, qr = true, advanced = false; String? error; DateTime startTime = DateTime.now(); String category = 'COMPANY'; String checklist = ''; final Set<String> selectedMembers = <String>{}; final Map<String, String> stationProctors = <String, String>{};
  bool _dirty = false;
  bool get _isEmsCe => widget.template?.ceCredits.isNotEmpty == true;

  void _markDirty() {
    if (_dirty) return;
    setState(() => _dirty = true);
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard draft Training Sheet?'),
        content: const Text('You have entered information. If you leave now, it will not be saved.'),
        actions: [
          TextButton(onPressed: () => dialogContext.pop(false), child: const Text('Keep editing')),
          FilledButton(onPressed: () => dialogContext.pop(true), child: const Text('Discard')),
        ],
      ),
    );
    return approved ?? false;
  }
  @override void initState() {
    super.initState();
    final t=widget.template;
    if(t!=null){
      title.text=_isEmsCe ? '' : t.defaultTitle; location.text=t.location; notes.text=t.notes;
      hours.text=t.creditHours > 0 ? t.creditHours.toString() : '';
      category=t.trainingCategory; checklist=t.checklistVersionId; qr=t.selfRegistration;
    }
    title.addListener(_markDirty);
    location.addListener(_markDirty);
    notes.addListener(_markDirty);
    hours.addListener(_markDirty);
  }
  @override void dispose(){ title.dispose(); location.dispose(); notes.dispose(); hours.dispose(); super.dispose(); }

  Future<TimeOfDay?> _pickTimeDigital(BuildContext context, TimeOfDay initial) => showTimePicker(
    context: context,
    initialTime: initial,
    initialEntryMode: TimePickerEntryMode.inputOnly,
    builder: (context, child) {
      final media = MediaQuery.of(context);
      return MediaQuery(
        data: media.copyWith(alwaysUse24HourFormat: media.alwaysUse24HourFormat),
        child: child ?? const SizedBox.shrink(),
      );
    },
  );
  Future<void> save() async {
    if(title.text.trim().isEmpty){setState(()=>error='Training title is required.'); return;}
    if(!qr && selectedMembers.isEmpty){setState(()=>error='Choose roster members or enable QR sign-in.');return;}
    final h=double.tryParse(hours.text.trim())??0;
    final mode=context.read<AppModeController>();
    final me=widget.setup.proctors.where((p)=>(p['userId']?.toString()??'')==mode.departmentLink?.userId).toList();
    final defaults=widget.template?.proctorUserIds.where((id)=>widget.setup.proctors.any((p)=>p['userId']?.toString()==id)).toList() ?? const <String>[];
    final proctors=defaults.isNotEmpty ? defaults : me.map((p)=>p['userId'].toString()).toList();
    if(proctors.isEmpty){setState(()=>error='Choose an approved proctor before starting this training.'); return;}
    setState((){busy=true;error=null;});
    try {
      final stations = stationProctors.entries.map((entry) => <String, String>{'checklistVersionId': entry.key, 'title': widget.setup.checklists.firstWhere((v) => v['id']?.toString() == entry.key)['title']?.toString() ?? 'Skills station', 'proctorUserId': entry.value}).toList(growable:false);
      final created = await widget.api.createTrainingSheet(title:title.text, startsAt:startTime.toUtc().toIso8601String(), trainingCategory:category, classType:widget.template?.classType ?? 'GENERAL', checklistVersionId:checklist, trainingSheetTemplateId:widget.template?.id ?? '', creditHours:h, location:location.text, notes:notes.text, proctorUserIds:proctors, membershipIds:selectedMembers.toList(), selfRegistration:qr, stations:stations);
      if (mounted) {
        setState(() => _dirty = false);
        context.pop(created.id);
      }
    } catch(e){if(mounted)setState(()=>error=e.toString());}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>PopScope(
    canPop: !_dirty,
    onPopInvoked: (didPop) async {
      if (didPop) return;
      final discard = await _confirmDiscard();
      if (!discard || !mounted) return;
      setState(() => _dirty = false);
      context.pop();
    },
    child: Padding(
      padding: EdgeInsets.fromLTRB(20,16,20,MediaQuery.viewInsetsOf(context).bottom+24),
      child: SingleChildScrollView(child: Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Row(children: [
        Expanded(child: Text(widget.template==null?'Blank Training Sheet':'From Template · ${widget.template!.name}',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900))),
        TextButton.icon(
          onPressed: busy ? null : () async {
            final discard = await _confirmDiscard();
            if (!discard || !mounted) return;
            setState(() => _dirty = false);
            context.pop();
          },
          icon: const Icon(Icons.close_rounded),
          label: const Text('Cancel'),
        ),
      ]),
      const SizedBox(height:6), const Text('Create the class quickly, then collect student results and finish RMS documentation after training.'),
      if (widget.template != null) ...[
        const SizedBox(height: 12),
        Card(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: ListTile(
            leading: const Icon(Icons.fact_check_outlined),
            title: const Text('Selected instructor setup'),
            subtitle: Text(_trainingTemplateSummary(widget.template!)),
          ),
        ),
      ],
      if(error!=null)...[const SizedBox(height:10),Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error))],
      const SizedBox(height:16),TextField(controller:title,decoration:const InputDecoration(labelText:'Training title *')),
      const SizedBox(height:12),DropdownButtonFormField<String>(initialValue:category,decoration:const InputDecoration(labelText:'Training category'),items:const [
        DropdownMenuItem(value:'COMPANY',child:Text('Fire / Company')),
        DropdownMenuItem(value:'EMS',child:Text('EMS')),
        DropdownMenuItem(value:'HAZMAT',child:Text('HazMat')),
        DropdownMenuItem(value:'DRIVER',child:Text('Driver Operator')),
        DropdownMenuItem(value:'FACILITY',child:Text('Facility')),
        DropdownMenuItem(value:'OFFICER',child:Text('Officer')),
        DropdownMenuItem(value:'OTHER',child:Text('Other / Rescue')),
      ],onChanged:(v){setState(()=>category=v??'COMPANY');_markDirty();}),
      const SizedBox(height:12),DropdownButtonFormField<String>(initialValue:checklist,decoration:const InputDecoration(labelText:'Skills checklist (optional)'),items:[const DropdownMenuItem(value:'',child:Text('Attendance only')),...widget.setup.checklists.map((v)=>DropdownMenuItem(value:v['id']?.toString()??'',child:Text(v['title']?.toString()??'Checklist')))],onChanged:(v){setState(()=>checklist=v??'');_markDirty();}),
      if (advanced)
        ExpansionTile(
          title: Text('Multiple skill stations (${stationProctors.length})'),
          subtitle: const Text('Assign a published checklist and authorized proctor to each station.'),
          children: widget.setup.checklists.map<Widget>((item) {
            final id = item['id']?.toString() ?? '';
            final selected = stationProctors.containsKey(id);
            return Column(
              children: [
                CheckboxListTile(
                  dense: true,
                  title: Text(item['title']?.toString() ?? 'Checklist'),
                  subtitle: Text('${item['skillCount'] ?? 0} skills'),
                  value: selected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        if (widget.setup.proctors.isNotEmpty) {
                          stationProctors[id] = widget.setup.proctors.first['userId']?.toString() ?? '';
                        }
                      } else {
                        stationProctors.remove(id);
                      }
                    });
                    _markDirty();
                  },
                ),
                if (selected)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonFormField<String>(
                      initialValue: stationProctors[id],
                      decoration: const InputDecoration(labelText: 'Assigned proctor'),
                      items: widget.setup.proctors.map((person) => DropdownMenuItem(
                        value: person['userId']?.toString() ?? '',
                        child: Text(person['name']?.toString() ?? 'Proctor'),
                      )).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => stationProctors[id] = value);
                          _markDirty();
                        }
                      },
                    ),
                  ),
                const Divider(),
              ],
            );
          }).toList(),
        ),
      const SizedBox(height:12),
      if(_isEmsCe) TextField(controller:location,decoration:const InputDecoration(labelText:'Class location (optional)')),
      if(_isEmsCe) const SizedBox(height:12),
      OutlinedButton.icon(
        onPressed: () async {
          final day = await showDatePicker(context:context,initialDate:startTime,firstDate:DateTime(2020),lastDate:DateTime.now().add(const Duration(days:730)));
          if(day==null || !mounted)return;
          final time = await _pickTimeDigital(context, TimeOfDay.fromDateTime(startTime));
           if (time != null && mounted) {
             setState(() => startTime = DateTime(day.year, day.month, day.day, time.hour, time.minute));
             _markDirty();
           }
        },
        icon:const Icon(Icons.calendar_today_outlined),
         label:Text('Training date / start: ${startTime.toLocal()}'),
      ),
      const SizedBox(height:12),
      TextButton(onPressed:(){setState(()=>advanced=!advanced);_markDirty();},child:Text(advanced?'Hide optional details':'Show optional details')),
      if(advanced && !_isEmsCe) TextField(controller:location,decoration:const InputDecoration(labelText:'Location (closeout optional)')),
      const SizedBox(height:12),if(advanced) TextField(controller:hours,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Training hours (finish after teaching)')),
      const SizedBox(height:12),if(advanced) TextField(controller:notes,maxLines:3,decoration:const InputDecoration(labelText:'Optional preparation notes')),
      const SizedBox(height:8),SwitchListTile(contentPadding:EdgeInsets.zero,value:qr,onChanged:(v){setState(()=>qr=v);_markDirty();},title:const Text('Allow QR self-registration'),subtitle:const Text('Crew can scan in from their phones.')),
      const SizedBox(height:8),
      ExpansionTile(title:Text('Select department roster (${selectedMembers.length})'),children:[
        SizedBox(height:220,child:ListView(children:widget.setup.members.map((member){
          final id=member['id']?.toString()??'';
          return CheckboxListTile(
            dense:true,
            title:Text(member['name']?.toString()??'Member'),
            value:selectedMembers.contains(id),
            onChanged:id.isEmpty?null:(selected)=>setState((){
              if(selected==true){selectedMembers.add(id);}else{selectedMembers.remove(id);} _markDirty();
            }),
          );
        }).toList())),
      ]),
      const SizedBox(height:10),OutlinedButton.icon(
        onPressed: busy ? null : () async {
          final discard = await _confirmDiscard();
          if (!discard || !mounted) return;
          setState(() => _dirty = false);
          context.pop();
        },
        icon: const Icon(Icons.close_rounded),
        label: const Text('Cancel'),
      ),
      const SizedBox(height:14),FilledButton.icon(onPressed:busy?null:save,icon:busy?const SizedBox.square(dimension:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.play_arrow_rounded),label:Text(qr?'Create & Show QR':'Create Training Sheet')),
    ])),
    ),
  );
}

class DepartmentClassDetailPage extends StatefulWidget {
  final String classId;
  const DepartmentClassDetailPage({super.key, required this.classId, this.showQrOnOpen = false});
  final bool showQrOnOpen;
  @override
  State<DepartmentClassDetailPage> createState() => _DepartmentClassDetailPageState();
}

class _DepartmentClassDetailPageState extends State<DepartmentClassDetailPage> {
  final _api = ResponderRoadmapApi();
  DepartmentClassDetail? _detail;
  String? _studentId;
  String? _error;
  bool _busy = false;
  String? _groupSkillId;
  bool _showGrading = false;
  bool _missingOnly = false;
  bool _selectAttendance = false;
  final Set<String> _selectedAttendanceIds = <String>{};
  final _memberEditorKey = GlobalKey();
  final _detailScrollController = ScrollController();
  final _rosterSectionKey = GlobalKey();
  // Drafts are kept per enrollment so switching roster members does not discard
  // unsent evaluations. Only explicit Submit sends results to the server.
  final Map<String, Map<String, String>> _draftSkillResults = {};
  final Map<String, Map<String, String>> _draftSkillNotes = {};

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() {
    _detailScrollController.dispose();
    super.dispose();
  }

  bool _initialQrShown = false;
  Future<void> _load() async { try { _setDetail(await _api.getClass(widget.classId));
    if (widget.showQrOnOpen && !_initialQrShown && mounted) {
      _initialQrShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showQr();
      });
    }
  } catch (e) { if (mounted) setState(() => _error = e.toString()); } }
  void _setDetail(DepartmentClassDetail detail) { if (!mounted) return; setState(() { _detail = detail; _studentId = detail.roster.any((item) => item.id == _studentId) ? _studentId : (detail.roster.isEmpty ? null : detail.roster.first.id); _error = null; }); }
  DepartmentClassStudent? get _student { for (final item in _detail?.roster ?? const <DepartmentClassStudent>[]) { if (item.id == _studentId) return item; } return null; }

  bool _studentComplete(DepartmentClassDetail detail, DepartmentClassStudent student) {
    if (student.attendance != 'PRESENT') return false;
    final required = detail.sections.expand((section) => section.skills).where((skill) => skill.required);
    for (final skill in required) {
      final matches = student.results.where((result) => result.requirementId == skill.id);
      if (matches.isEmpty || matches.last.result != 'PASS') return false;
    }
    final config = detail.gradingConfig;
    if (config['writtenTestEnabled'] == true) {
      if (student.writtenScore == null) return false;
      final threshold = (config['writtenTestPassPercent'] as num?)?.toDouble();
      if (threshold != null && student.writtenScore! < threshold) return false;
    }
    if (config['ccfEnabled'] == true) {
      if (student.ccfScore == null) return false;
      final threshold = (config['ccfPassPercent'] as num?)?.toDouble();
      if (threshold != null && student.ccfScore! < threshold) return false;
    }
    return true;
  }

  String _missingFor(DepartmentClassDetail detail, DepartmentClassStudent member) {
    if (member.attendance == 'REGISTERED') return 'Attendance not confirmed';
    if (member.attendance != 'PRESENT') return '';
    final missing = detail.sections.expand((section) => section.skills)
        .where((skill) => skill.required && !member.results.any(
          (result) => result.requirementId == skill.id && result.result == 'PASS',
        )).toList();
    final issues = <String>[];
    if (missing.isNotEmpty) issues.add('${missing.length} required skill(s) need a passing result');
    final config = detail.gradingConfig;
    final writtenThreshold = (config['writtenTestPassPercent'] as num?)?.toDouble();
    if (config['writtenTestEnabled'] == true && (member.writtenScore == null || (writtenThreshold != null && member.writtenScore! < writtenThreshold))) issues.add('written test score needed');
    final ccfThreshold = (config['ccfPassPercent'] as num?)?.toDouble();
    if (config['ccfEnabled'] == true && (member.ccfScore == null || (ccfThreshold != null && member.ccfScore! < ccfThreshold))) issues.add('CCF score needed');
    return issues.join('; ');
  }

  Future<void> _confirmSelectedAttendance() async {
    final detail = _detail;
    if (detail == null || _busy || detail.status == 'COMPLETE') return;
    final selected = detail.roster.where((member) =>
      _selectedAttendanceIds.contains(member.id) && member.attendance == 'REGISTERED').toList();
    if (selected.isEmpty) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm selected attendance?'),
        content: Text('Mark ${selected.length} selected registered members PRESENT? Confirm each person physically attended. No skill results will be awarded.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Confirm')),
        ],
      ),
    ) ?? false;
    if (!approved || !mounted) return;
    setState(() { _busy = true; _error = null; });
    var confirmed = 0;
    try {
      for (final member in selected) {
        final saved = await _api.updateClassStudentDurable(
          classId: detail.id, enrollmentId: member.id, attendance: 'PRESENT',
        );
        if (saved.queued) {
          if (mounted) {
            context.read<DepartmentInboxController>().submissionQueued();
            setState(() => _error = 'Sync pending for ${member.name}. Remaining selections were not submitted.');
          }
          break;
        }
        if (saved.detail != null) _setDetail(saved.detail!);
        confirmed++;
        _selectedAttendanceIds.remove(member.id);
      }
      if (mounted) {
        setState(() {
          if (_selectedAttendanceIds.isEmpty) _selectAttendance = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$confirmed of ${selected.length} attendance records confirmed on server.'),
        ));
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$confirmed confirmed; remaining selections retained: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmRosterAttendance() async {
    final detail = _detail;
    if (detail == null || _busy || detail.status == 'COMPLETE') return;
    final pending = detail.roster.where((m) => m.attendance == 'REGISTERED').toList();
    if (pending.isEmpty) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm group attendance?'),
        content: Text('Mark ${pending.length} registered member(s) PRESENT? Only confirm people you have physically verified. Absent and excused members will not change. This does not record any skill passes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Confirm attendance')),
        ],
      ),
    ) ?? false;
    if (!approved || !mounted) return;
    setState(() { _busy = true; _error = null; });
    var confirmed = 0;
    try {
      for (final member in pending) {
        final saved = await _api.updateClassStudentDurable(
          classId: detail.id, enrollmentId: member.id, attendance: 'PRESENT',
        );
        if (saved.queued) {
          if (mounted) {
            context.read<DepartmentInboxController>().submissionQueued();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Waiting to Sync — ${member.name} and remaining attendance need verification.')),
            );
          }
          break; // Never report queued attendance as server-confirmed.
        }
        if (saved.detail != null) _setDetail(saved.detail!);
        confirmed++;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$confirmed attendance record(s) confirmed on server. Check remaining members before closing.')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Confirmed $confirmed record(s); remaining attendance requires attention: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _groupGrade() async {
    final detail = _detail;
    if (detail == null || _busy || detail.status == 'COMPLETE') return;
    final skills = detail.sections.expand((section) => section.skills).toList();
    final members = detail.roster.where((member) => member.attendance == 'PRESENT').toList();
    if (skills.isEmpty || members.isEmpty) {
      setState(() => _error = 'Confirm attendance and choose a skills checklist first.');
      return;
    }
    String? skillId;
    String result = 'PASS';
    final selected = <String>{};
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, update) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Group skill results', style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: skillId,
                decoration: const InputDecoration(labelText: 'Skill'),
                items: skills.map((skill) => DropdownMenuItem<String>(
                  value: skill.id, child: Text(skill.title),
                )).toList(),
                onChanged: (value) => update(() => skillId = value),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: result,
                decoration: const InputDecoration(labelText: 'Evaluation'),
                items: const [
                  DropdownMenuItem(value: 'PASS', child: Text('Pass')),
                  DropdownMenuItem(value: 'FAIL', child: Text('Fail')),
                ],
                onChanged: (value) => update(() => result = value ?? 'PASS'),
              ),
              TextButton(
                onPressed: () => update(() {
                  if (selected.length == members.length) {
                    selected.clear();
                  } else {
                    selected.addAll(members.map((member) => member.id));
                  }
                }),
                child: Text(selected.length == members.length ? 'Clear selection' : 'Select all present'),
              ),
              SizedBox(
                height: 240,
                child: ListView(children: members.map((member) => CheckboxListTile(
                  title: Text(member.name),
                  value: selected.contains(member.id),
                  onChanged: (checked) => update(() {
                    if (checked == true) {
                      selected.add(member.id);
                    } else {
                      selected.remove(member.id);
                    }
                  }),
                )).toList()),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: skillId == null || selected.isEmpty
                    ? null : () => Navigator.pop(sheetContext, true),
                child: Text('Submit ${selected.length} evaluations'),
              ),
            ]),
          ),
        ),
      ),
    );
    if (confirmed != true || skillId == null || !mounted) return;
    setState(() { _busy = true; _error = null; });
    try {
      final batch = members.where((member) => selected.contains(member.id)).map((member) {
        final previous = member.results.where((item) => item.requirementId == skillId).firstOrNull;
        return <String, dynamic>{
          'enrollmentId': member.id,
          'result': result,
          'notes': 'Group evaluation',
          // null means no prior result was observed; the server checks this.
          'expectedUpdatedAt': previous?.updatedAt,
        };
      }).toList(growable: false);
      final saved = await _api.recordClassSkillBatchDurable(
        classId: detail.id,
        requirementId: skillId!,
        results: batch,
      );
      if (saved.detail != null) _setDetail(saved.detail!);
      if (saved.queued && mounted) {
        context.read<DepartmentInboxController>().submissionQueued();
        setState(() => _error = 'Evaluations waiting to sync. Check sync status before closing.');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(saved.queued ? '${batch.length} evaluation(s) saved and waiting to sync' : '${batch.length} individual evaluation(s) submitted together')),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Unable to submit these group evaluations: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editCustomResults(DepartmentClassDetail detail, DepartmentClassStudent student) async {
    final fields = detail.customFields;
    final config = detail.gradingConfig;
    final configured = config.isNotEmpty;
    final showWritten = configured ? config['writtenTestEnabled'] == true : true;
    final showCcf = configured ? config['ccfEnabled'] == true : true;
    if (fields.isEmpty && !showWritten && !showCcf) return;
    final controllers = <String, TextEditingController>{};
    final writtenController = TextEditingController(text: student.writtenScore?.toString() ?? '');
    final ccfController = TextEditingController(text: student.ccfScore?.toString() ?? '');
    final values = Map<String, dynamic>.from(student.customValues);
    for (final field in fields) {
      final id = field['id']?.toString() ?? '';
      controllers[id] = TextEditingController(text: values[id]?.toString() ?? '');
    }
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (dialogContext, update) => AlertDialog(
        title: Text('${student.name} — Student results'),
        scrollable: true,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (showWritten) TextField(controller: writtenController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Written test score (%)${config['writtenTestPassPercent'] != null ? ' · pass ≥${config['writtenTestPassPercent']}%' : ''}')),
          if (showCcf) TextField(controller: ccfController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'CCF score (%)${config['ccfPassPercent'] != null ? ' · pass ≥${config['ccfPassPercent']}%' : ''}')),
          for (final field in fields) ...[
            const SizedBox(height: 10),
            if (field['type'] == 'CHECKBOX')
              CheckboxListTile(title: Text(field['label']?.toString() ?? 'Check'),
                value: values[field['id']] == true,
                onChanged: (value) => update(() => values[field['id'].toString()] = value == true))
            else if (field['type'] == 'PASS_FAIL')
              DropdownButtonFormField<String>(
                initialValue: ['PASS','FAIL'].contains(values[field['id']]) ? values[field['id']].toString() : '',
                decoration: InputDecoration(labelText: field['label']?.toString() ?? 'Result'),
                items: const [DropdownMenuItem(value:'',child:Text('Not recorded')),DropdownMenuItem(value:'PASS',child:Text('Pass')),DropdownMenuItem(value:'FAIL',child:Text('Fail'))],
                onChanged: (value) => update(() => values[field['id'].toString()] = value ?? ''),
              )
            else TextField(
              controller: controllers[field['id']?.toString() ?? ''],
              keyboardType: field['type'] == 'PERCENT' || field['type'] == 'NUMBER' ? const TextInputType.numberWithOptions(decimal:true) : TextInputType.text,
              decoration: InputDecoration(labelText: '${field['label']}${field['required']==true?' *':''}'),
            ),
          ],
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext,false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext,true), child: const Text('Save results')),
        ],
      )),
    );
    if (save == true) {
      for (final field in fields) {
        final id = field['id']?.toString() ?? '';
        if (field['type'] == 'CHECKBOX' || field['type'] == 'PASS_FAIL') continue;
        final raw = controllers[id]?.text.trim() ?? '';
        values[id] = raw.isEmpty ? null : (field['type'] == 'NUMBER' || field['type'] == 'PERCENT') ? (double.tryParse(raw) ?? raw) : raw;
      }
      setState(() => _busy = true);
      try {
        final updated = await _api.updateClassStudent(classId: detail.id, enrollmentId: student.id, attendance: student.attendance, customValues: fields.isEmpty ? null : values, writtenScore: showWritten ? double.tryParse(writtenController.text.trim()) : null, ccfScore: showCcf ? double.tryParse(ccfController.text.trim()) : null);
        _setDetail(updated);
      } catch (error) {
        if (mounted) setState(() => _error = error.toString());
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
    for (final controller in controllers.values) { controller.dispose(); }
  }

  void _jumpToMember(DepartmentClassStudent member, {required bool grading}) {
    setState(() {
      _studentId = member.id;
      _showGrading = grading;
      _missingOnly = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _memberEditorKey.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut, alignment: 0.08);
      }
    });
  }

  Future<void> _reviewAndFinish() async {
    final detail = _detail;
    if (detail == null || _busy) return;
    final memberIssues = detail.roster
        .where((member) => _missingFor(detail, member).isNotEmpty)
        .toList();
    late final DepartmentCloseValidation validation;
    try {
      validation = await _api.validateClassClosure(detail.id);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Unable to check required closeout items: $error');
      }
      return;
    }
    if (!mounted) return;
    final serverIssues = validation.missing;
    final hasMissingItems =
        memberIssues.isNotEmpty || serverIssues.isNotEmpty || !validation.canClose;
    final selection = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final errorColor = Theme.of(sheetContext).colorScheme.error;
        final ceSummary = detail.ceCredits
            .where((item) => (item['hours'] as num?)?.toDouble() != null && (item['hours'] as num).toDouble() > 0)
            .map((item) => '${item['category']} ${(item['hours'] as num).toDouble().toStringAsFixed(2)} hr')
            .join(' · ');
        Widget summaryRow(String label, String value, {bool required = false}) =>
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 112, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
                Expanded(child: Text(value.isEmpty ? (required ? 'Required — not completed' : 'Not recorded') : value,
                    style: TextStyle(color: value.isEmpty && required ? errorColor : null,
                        fontWeight: value.isEmpty && required ? FontWeight.w800 : null))),
              ]),
            );
        final tiles = <Widget>[
          Card(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(detail.title, style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                summaryRow('Start', _recordDate(detail.startsAt), required: true),
                summaryRow('End', _recordDate(detail.endsAt), required: true),
                summaryRow('Total hours', detail.creditHours > 0 ? detail.creditHours.toStringAsFixed(2) : '', required: true),
                summaryRow('Category', detail.trainingCategory.replaceAll('_', ' '), required: true),
                if (detail.trainingCategory == 'EMS') summaryRow('CE category', ceSummary, required: true),
                summaryRow('Station', detail.station),
                summaryRow('Shift', detail.shift),
                summaryRow('Location', detail.location),
                summaryRow('Checklist', detail.checklistTitle),
                summaryRow('Roster', '${detail.roster.length} students · ${detail.roster.where((m) => m.attendance == 'PRESENT').length} present'),
                summaryRow('Description', detail.notes, required: true),
              ]),
            ),
          ),
          if (hasMissingItems)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: errorColor.withValues(alpha: .08),
                border: Border.all(color: errorColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(Icons.error_outline_rounded, color: errorColor),
                const SizedBox(width: 10),
                Expanded(child: Text('Required information', style: TextStyle(color: errorColor, fontWeight: FontWeight.w900))),
              ]),
            ),
          for (final item in serverIssues)
            ListTile(
              leading: Icon(Icons.error_outline_rounded, color: errorColor),
              title: Text(
                item.message,
                style: TextStyle(color: errorColor, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(item.action, style: TextStyle(color: errorColor)),
            ),
          for (final member in memberIssues)
            ListTile(
              leading: Icon(Icons.error_outline_rounded, color: errorColor),
              title: Text(
                '${member.name} needs attention',
                style: TextStyle(color: errorColor, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                _missingFor(detail, member),
                style: TextStyle(color: errorColor),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(sheetContext, member),
            ),
          if (!validation.canClose && serverIssues.isEmpty && memberIssues.isEmpty)
            ListTile(
              leading: Icon(Icons.error_outline_rounded, color: errorColor),
              title: Text(
                'The server still requires more information.',
                style: TextStyle(color: errorColor, fontWeight: FontWeight.w700),
              ),
            ),
          if (!hasMissingItems)
            const ListTile(
              leading: Icon(Icons.check_circle_outline, color: Colors.green),
              title: Text('All required closeout items are ready.'),
              subtitle: Text('Instructor approval remains a separate required step.'),
            ),
        ];
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.78,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review Training Sheet',
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasMissingItems
                            ? 'Review the full record below. Required information that is incomplete is shown in red.'
                            : 'The Training Sheet is complete and ready to close, print, and approve.',
                      ),
                    ],
                  ),
                ),
                Expanded(child: ListView(children: tiles)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(sheetContext, hasMissingItems ? 'edit' : 'continue'),
                      icon: Icon(
                        hasMissingItems
                            ? Icons.edit_note_rounded
                            : Icons.fact_check_outlined,
                      ),
                      label: Text(
                        hasMissingItems
                            ? 'Fill required information now'
                            : 'Review details & continue',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted) return;
    if (selection is DepartmentClassStudent) {
      _jumpToMember(selection, grading: selection.attendance == 'PRESENT');
    } else if (selection == 'edit') {
      if (await _editTrainingDocumentation() && mounted) await _reviewAndFinish();
    } else if (selection == 'continue' && validation.canClose) {
      if (await _editTrainingDocumentation()) {
        await _closeTraining();
        if (mounted && _detail?.status == 'COMPLETE') await _showCompletedTrainingActions();
      }
    }
  }

  Future<void> _showCompletedTrainingActions() async {
    final detail = _detail;
    if (detail == null || detail.status != 'COMPLETE' || !mounted) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Training Sheet complete', style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('Print or save a copy now. Instructor approval makes this the official record and sends it to the department RMS queue.'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(sheetContext, 'print'),
              icon: const Icon(Icons.print_outlined),
              label: const Text('Print / save Training Sheet'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: detail.instructorApprovedAt == null ? () => Navigator.pop(sheetContext, 'approve') : null,
              icon: const Icon(Icons.verified_outlined),
              label: Text(detail.instructorApprovedAt == null ? 'Instructor approve class' : 'Instructor approved'),
            ),
          ]),
        ),
      ),
    );
    if (action == 'print') {
      await _printTrainingRecord();
      if (mounted && _detail?.instructorApprovedAt == null) await _showCompletedTrainingActions();
    } else if (action == 'approve') {
      await _approveTrainingSheet();
    }
  }

  Future<void> _setRosterAttendance(DepartmentClassStudent member, String attendance) async {
    final detail = _detail;
    if (detail == null || _busy || detail.status == 'COMPLETE' ||
        member.attendance == attendance) return;
    setState(() { _busy = true; _error = null; });
    try {
      final saved = await _api.updateClassStudentDurable(
        classId: detail.id, enrollmentId: member.id, attendance: attendance,
      );
      if (saved.detail != null) {
        _setDetail(saved.detail!);
        _nextStudent();
      }
      if (saved.queued && mounted) {
        context.read<DepartmentInboxController>().submissionQueued();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance saved on device; waiting to sync.')),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Attendance was not confirmed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _nextStudent() {
    final roster = _detail?.roster ?? const <DepartmentClassStudent>[];
    if (roster.isEmpty) return;
    final index = roster.indexWhere((item) => item.id == _studentId);
    // Prefer the next member who still needs attendance or a required skill.
    for (var offset = 1; offset <= roster.length; offset++) {
      final candidate = roster[(index + offset) % roster.length];
      if (_missingFor(_detail!, candidate).isNotEmpty) {
        setState(() => _studentId = candidate.id);
        return;
      }
    }
    setState(() => _studentId = roster[(index + 1) % roster.length].id);
  }

  int _requiredSkillCount(DepartmentClassDetail detail) =>
      detail.sections.expand((section) => section.skills).where((skill) => skill.required).length;

  int _passedRequiredCount(DepartmentClassDetail detail, DepartmentClassStudent student) {
    final requiredIds = detail.sections.expand((section) => section.skills).where((skill) => skill.required).map((skill) => skill.id).toSet();
    return student.results.where((result) => requiredIds.contains(result.requirementId) && result.result == 'PASS').map((result) => result.requirementId).toSet().length;
  }
  String get _registrationUrl => _detail?.registrationToken.isNotEmpty == true ? 'https://responderroadmap.com/class-join/${_detail!.registrationToken}' : '';

  Future<void> _registration(String action) async {
    if (_detail == null || _busy) return; setState(()=>_busy=true);
    try { _setDetail(await _api.manageClassRegistration(classId: widget.classId, action: action)); }
    catch(e){if(mounted)setState(()=>_error=e.toString());}
    finally{if(mounted)setState(()=>_busy=false);}
  }

  Future<bool> _editTrainingDocumentation() async {
    final d = _detail;
    if (d == null || _busy || d.status == 'COMPLETE') return false;
    DateTime start = d.startsAt?.toLocal() ?? DateTime.now();
    DateTime? end = d.endsAt?.toLocal();
    final narrative = TextEditingController(text:d.notes);
    final location = TextEditingController(text:d.location);
    final station = TextEditingController(text:d.station);
    final hours = TextEditingController(text:d.creditHours > 0 ? d.creditHours.toString() : '');
    String trainingCategory = d.trainingCategory;
    String shift = d.shift;
    final ceCategories = <String>{
      ..._emsCeCategories,
      ...d.ceCredits.map((item) => item['category']?.toString() ?? '').where((category) => category.isNotEmpty),
    }.toList(growable: false);
    final ceControllers = <String, TextEditingController>{
      for (final category in ceCategories)
        category: TextEditingController(text: d.ceCredits.where((item) => item['category'] == category).map((item) => item['hours']).firstOrNull?.toString() ?? ''),
    };

    int parseHoursToMinutes(String raw) {
      final value = double.tryParse(raw.trim()) ?? 0;
      if (value <= 0) return 0;
      return (value * 60).round();
    }

    String formatLocalDateTime(DateTime dateTime) {
      final local = dateTime.toLocal();
      final hour = local.hour == 0 ? 12 : (local.hour > 12 ? local.hour - 12 : local.hour);
      final period = local.hour >= 12 ? 'PM' : 'AM';
      String two(int v) => v.toString().padLeft(2, '0');
      return '${local.month}/${local.day}/${local.year} $hour:${two(local.minute)} $period';
    }
    Future<DateTime?> chooseTime(BuildContext dialogContext, DateTime initial) async {
      final day = await showDatePicker(
        context:dialogContext, initialDate:initial,
        firstDate:DateTime(2020), lastDate:DateTime.now().add(const Duration(days:730)),
      );
      if (day == null || !dialogContext.mounted) return null;
      final time = await showTimePicker(
        context: dialogContext,
        initialTime: TimeOfDay.fromDateTime(initial),
        initialEntryMode: TimePickerEntryMode.inputOnly,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(alwaysUse24HourFormat: media.alwaysUse24HourFormat),
            child: child ?? const SizedBox.shrink(),
          );
        },
      );
      if (time == null) return null;
      return DateTime(day.year,day.month,day.day,time.hour,time.minute);
    }
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, update) {
          final isEms = trainingCategory == 'EMS';
          final elapsedMinutes = TrainingTimeCalculator.elapsedMinutes(start, end);
          final split = (elapsedMinutes == null)
              ? null
              : TrainingTimeCalculator.splitDayNight(
                  startLocal: start,
                  endLocal: end!,
                  definition: TrainingTimeCalculator.defaultDayNight,
                );
          final allocatedMinutes = isEms
              ? ceControllers.values.fold<int>(0, (sum, c) => sum + parseHoursToMinutes(c.text))
              : 0;
          final overAllocated = elapsedMinutes != null && allocatedMinutes > elapsedMinutes;
          final remainingMinutes = elapsedMinutes == null ? null : (elapsedMinutes - allocatedMinutes);

          return AlertDialog(
            title: const Text('Finish Training Documentation'),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color: Theme.of(dialogContext).colorScheme.surfaceVariant,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          Icon(Icons.schedule_rounded, color: FireOpsFeatureColors.training),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Time & hours', style: Theme.of(dialogContext).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 4),
                              Text(
                                elapsedMinutes == null
                                    ? 'Duration: Pending (set End Time)'
                                    : 'Duration: ${formatMinutesAsHoursMinutes(elapsedMinutes)}',
                                style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              if (split != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'Day ${formatMinutesAsHoursMinutes(split.dayMinutes)} · Night ${formatMinutesAsHoursMinutes(split.nightMinutes)}',
                                    style: Theme.of(dialogContext).textTheme.bodySmall,
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(TrainingTimeCalculator.defaultDayNight.label, style: Theme.of(dialogContext).textTheme.bodySmall),
                              ),
                            ]),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final chosen = await chooseTime(dialogContext, start);
                        if (chosen != null) update(() => start = chosen);
                      },
                      icon: const Icon(Icons.schedule),
                      label: Text('Start Time: ${formatLocalDateTime(start)}'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final chosen = await chooseTime(dialogContext, end ?? start);
                        if (chosen != null) update(() => end = chosen);
                      },
                      icon: const Icon(Icons.schedule),
                      label: Text(end == null ? 'End Time: Set when complete' : 'End Time: ${formatLocalDateTime(end!)}'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: trainingCategory,
                      decoration: const InputDecoration(labelText: 'Training category *'),
                      items: const [
                        DropdownMenuItem(value: 'COMPANY', child: Text('Company training')),
                        DropdownMenuItem(value: 'FACILITY', child: Text('Facility / station')),
                        DropdownMenuItem(value: 'EMS', child: Text('EMS')),
                        DropdownMenuItem(value: 'HAZMAT', child: Text('HazMat')),
                        DropdownMenuItem(value: 'DRIVER', child: Text('Driver / apparatus')),
                        DropdownMenuItem(value: 'OFFICER', child: Text('Officer development')),
                        DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                      ],
                      onChanged: (value) => update(() => trainingCategory = value ?? 'COMPANY'),
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: location, decoration: const InputDecoration(labelText: 'Training location')),
                    const SizedBox(height: 8),
                    TextField(
                      controller: station,
                      decoration: const InputDecoration(
                        labelText: 'Station / facility',
                        hintText: 'Station 181',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: shift,
                      decoration: const InputDecoration(labelText: 'Shift / platoon'),
                      items: <String>{'', 'A', 'B', 'C', 'DAY', 'NIGHT', if (shift.isNotEmpty) shift}
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(value.isEmpty ? 'Not selected' : value),
                              ))
                          .toList(growable: false),
                      onChanged: (value) => update(() => shift = value ?? ''),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: narrative,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Short class description / objectives',
                        hintText: 'Briefly describe what was taught and practiced',
                      ),
                    ),
                    if (isEms) ...[
                      const SizedBox(height: 14),
                      Text('EMS CE categories', style: Theme.of(dialogContext).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      const Text('Allocate time-based credit (total cannot exceed class duration).'),
                      ...ceCategories.map((category) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextField(
                          controller: ceControllers[category],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => update(() {}),
                          decoration: InputDecoration(labelText: '$category hours', hintText: '0'),
                        ),
                      )),
                      const SizedBox(height: 8),
                      if (elapsedMinutes != null) ...[
                        Row(children: [
                          Expanded(child: Text('Assigned', style: Theme.of(dialogContext).textTheme.bodySmall)),
                          Text(
                            formatMinutesAsHoursMinutes(allocatedMinutes),
                            style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, color: LightModeColors.purple),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: (allocatedMinutes / elapsedMinutes).clamp(0, 1),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(999),
                          backgroundColor: Theme.of(dialogContext).colorScheme.surfaceVariant,
                          color: overAllocated ? Theme.of(dialogContext).colorScheme.error : FireOpsSemanticColors.green,
                        ),
                        const SizedBox(height: 6),
                        Row(children: [
                          Expanded(child: Text('Remaining', style: Theme.of(dialogContext).textTheme.bodySmall)),
                          Text(
                            remainingMinutes == null
                                ? '—'
                                : (remainingMinutes < 0
                                    ? 'Over by ${formatMinutesAsHoursMinutes(-remainingMinutes)}'
                                    : formatMinutesAsHoursMinutes(remainingMinutes)),
                            style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: overAllocated ? Theme.of(dialogContext).colorScheme.error : FireOpsSemanticColors.green,
                            ),
                          ),
                        ]),
                        if (overAllocated)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Total assigned credit cannot exceed class duration.',
                              style: TextStyle(color: Theme.of(dialogContext).colorScheme.error, fontWeight: FontWeight.w700),
                            ),
                          ),
                      ] else
                        const Text('Set End Time to validate credit allocations.'),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              FilledButton(
                onPressed: overAllocated
                    ? null
                    : () {
                        final computedMinutes = TrainingTimeCalculator.elapsedMinutes(start, end);
                        Navigator.pop(dialogContext, <String, dynamic>{
                          'start': start,
                          'end': end,
                          'notes': narrative.text,
                          'location': location.text,
                          'station': station.text,
                          'shift': shift,
                          'trainingCategory': trainingCategory,
                          // Back-compat: creditHours remains a double, derived from elapsed minutes when possible.
                          'hours': computedMinutes == null ? (double.tryParse(hours.text.trim()) ?? 0.0) : (computedMinutes / 60.0),
                          'ceCredits': <String, double>{
                            for (final entry in ceControllers.entries) entry.key: double.tryParse(entry.value.text.trim()) ?? 0,
                          },
                        });
                      },
                child: const Text('Save Documentation'),
              ),
            ],
          );
        },
      ),
    );
    narrative.dispose(); location.dispose(); station.dispose(); hours.dispose();
    for(final controller in ceControllers.values){controller.dispose();}
    if (result == null || !mounted) return false;
    final savedStart = result['start'] as DateTime;
    final savedEnd = result['end'] as DateTime?;
    if (savedEnd == null || savedEnd.isBefore(savedStart)) {
      setState(()=>_error='Enter an actual end time after the start time before closing.');
      return false;
    }
    final savedCategory = result['trainingCategory'] as String;
    final isEms = savedCategory == 'EMS';
    if(isEms && (result['notes'] as String).trim().isEmpty){setState(()=>_error='Enter a short class description before closing EMS CE.');return false;}
    final ceCredits=result['ceCredits'] as Map<String,double>;
    if(isEms && !ceCredits.values.any((hours)=>hours>0)){setState(()=>_error='Assign EMS CE credit to at least one category before closing.');return false;}

    final elapsedMinutes = TrainingTimeCalculator.elapsedMinutes(savedStart, savedEnd);
    if (elapsedMinutes == null) {
      setState(() => _error = 'End Time must be after Start Time.');
      return false;
    }
    if (isEms) {
      final allocatedMinutes = ceCredits.values.fold<int>(0, (sum, value) => sum + parseHoursToMinutes(value.toString()));
      if (allocatedMinutes > elapsedMinutes) {
        setState(() => _error = 'Assigned CE credit cannot exceed class duration (${formatMinutesAsHoursMinutes(elapsedMinutes)}).');
        return false;
      }
    }
    setState(() { _busy=true; _error=null; });
    try {
      _setDetail(await _api.updateTrainingSheetDocumentation(
        d.id, startsAt:savedStart, endsAt:savedEnd,
        notes:result['notes'] as String, location:result['location'] as String,
        station:result['station'] as String, shift:result['shift'] as String,
        trainingCategory:savedCategory,
        creditHours:result['hours'] as double,
        ceCredits:ceCredits,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Training time and class description saved.')),
        );
      }
      return true;
    } catch (error) {
      if(mounted)setState(()=>_error='Unable to save training documentation: $error');
      return false;
    } finally { if(mounted)setState(()=>_busy=false); }
  }

  Future<void> _reviewPendingSkillSync() async {
    final d = _detail;
    if (d == null || _busy) return;
    try {
      final pending = await _api.pendingSkillMutationsForClass(d.id);
      if (!mounted) return;
      if (pending.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All skill evaluations on this device are synchronized.')),
        );
        return;
      }
      final server = await _api.getClass(d.id);
      if (!mounted) return;
      final batch = pending.first;
      final raw = batch['results'];
      final results = raw is List ? raw.whereType<Map>().toList() : <Map>[];
      final conflict = batch['syncStatus'] == 'CONFLICT';
      final action = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(conflict ? 'Skill results need reconciliation' : 'Skill results waiting to sync'),
          content: SizedBox(width: 460, height: 340, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${pending.length} saved batch(es) on this device. '
                  'Compare local observations with the official server record before discarding anything.'),
              const SizedBox(height: 8),
              Expanded(child: ListView(
                children: results.map((entry) {
                  final id = entry['enrollmentId']?.toString() ?? '';
                  final requirement = entry['requirementId']?.toString() ??
                      batch['requirementId']?.toString() ?? '';
                  final matches = server.roster.where((person) => person.id == id);
                  final member = matches.isEmpty ? null : matches.first;
                  final serverResults = member?.results.where((result) =>
                      result.requirementId == requirement);
                  final serverResult = serverResults == null || serverResults.isEmpty
                      ? 'Not recorded' : serverResults.first.result;
                  return ListTile(
                    dense: true,
                    title: Text(member?.name ?? id),
                    subtitle: Text('Device: ${entry['result']} · Server: $serverResult'),
                  );
                }).toList(),
              )),
            ],
          )),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Keep saved')),
            TextButton(onPressed: () => Navigator.pop(dialogContext, 'retry'),
                child: const Text('Retry sync')),
            TextButton(onPressed: () => Navigator.pop(dialogContext, 'discard'),
                child: const Text('Review & discard local copy')),
          ],
        ),
      );
      if (!mounted) return;
      if (action == 'retry') {
        final completed = await _api.retryPendingClassMutations();
        if (!mounted) return;
        await _load();
        if (mounted) setState(() => _error = completed > 0
            ? '$completed queued record(s) synchronized. Reopen sync review for remaining batches.'
            : 'No queued records synchronized. Check connection or review conflicts.');
      } else if (action == 'discard') {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Discard this device copy?'),
            content: const Text('Only discard after verifying the official web record. '
                'This removes the saved local observations without changing server results. '
                'Any missing or incorrect evaluations must be corrected separately by an authorized instructor.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Keep saved')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('I verified — discard copy')),
            ],
          ),
        ) ?? false;
        if (confirmed) {
          await _api.discardReviewedSkillMutation(d.id, batch['key']?.toString() ?? '');
          if (mounted) setState(() => _error =
              'Reviewed local copy discarded. Recheck the official Training Sheet before closing.');
        }
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Unable to review pending skill results: $error');
    }
  }

  Future<void> _closeTraining() async {
    final d=_detail; if(d==null||_busy)return;
    final pending = await _api.pendingSkillMutationCountForClass(d.id);
    if (pending > 0) {
      if (mounted) setState(() => _error =
          '$pending skill batch(es) are still saved on this device. '
          'Review or sync them before closing; server approval must not ignore field evaluations.');
      await _reviewPendingSkillSync();
      return;
    }
    setState(()=>_busy=true);
    try{
      final validation=await _api.validateClassClosure(widget.classId);
      if(!mounted)return;
      if(!validation.canClose){
        await showDialog<void>(context:context,builder:(context)=>AlertDialog(
          title:const Text('Training is not ready to close'),
          content:SizedBox(width:420,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('Complete these items before this becomes an official training record.'),const SizedBox(height:12),
            ...validation.missing.map((item)=>Padding(padding:const EdgeInsets.only(bottom:12),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
              const Padding(padding:EdgeInsets.only(top:2),child:Icon(Icons.error_outline_rounded,size:20)),const SizedBox(width:10),
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(item.message,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:2),Text(item.action)])),
            ]))),
          ]))),
          actions:[FilledButton(onPressed:()=>Navigator.pop(context),child:const Text('Fix Missing Items'))],
        ));
        return;
      }
      final ok=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(
        title:const Text('Close Training?'),
        content:Text('Roster: ${d.roster.length}\n\nAll required fields, attendance, proctors and skill results are complete. Closing finalizes the official digital training sheet and stops QR registration.'),
        actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Keep Open')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Finalize & Close'))],
      ))??false;
      if(!ok)return;
      _setDetail(await _api.updateClassStatus(classId:widget.classId,status:'COMPLETE'));
    }on ResponderRoadmapApiException catch(e){if(mounted)setState(()=>_error=e.message);}
    catch(e){if(mounted)setState(()=>_error=e.toString());}
    finally{if(mounted)setState(()=>_busy=false);}
  }

  Future<void> _approveTrainingSheet() async {
    final d = _detail;
    if (d == null || _busy) return;
    setState(() => _busy = true);
    try {
      _setDetail(await _api.approveTrainingSheet(d.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Training Sheet approved. RMS entry is now needed.')),
        );
      }
    } on ResponderRoadmapApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markRmsEntered() async {
    final d = _detail;
    if (d == null || _busy) return;
    final reference = TextEditingController(text: d.rmsReference);
    final note = TextEditingController(text: d.rmsEntryNote);
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark RMS Entered'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reference,
              decoration: const InputDecoration(
                labelText: 'RMS reference (optional)',
                hintText: 'Record or incident number',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              (reference.text.trim(), note.text.trim()),
            ),
            child: const Text('Mark Entered'),
          ),
        ],
      ),
    );
    reference.dispose();
    note.dispose();
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      _setDetail(
        await _api.markTrainingSheetEnteredIntoRms(
          d.id,
          reference: result.$1,
          note: result.$2,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('RMS entry recorded with server timestamp.')),
        );
      }
    } on ResponderRoadmapApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _repeatTraining() async {
    final d=_detail; if(d==null||_busy)return;
    final date=await showDatePicker(context:context,initialDate:DateTime.now().add(const Duration(days:7)),firstDate:DateTime.now(),lastDate:DateTime.now().add(const Duration(days:730)));
    if(date==null||!mounted)return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(d.startsAt?.toLocal() ?? DateTime.now()),
      initialEntryMode: TimePickerEntryMode.inputOnly,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(alwaysUse24HourFormat: media.alwaysUse24HourFormat),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if(time==null||!mounted)return;
    final when=DateTime(date.year,date.month,date.day,time.hour,time.minute);
    final ok=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(title:const Text('Repeat Training?'),content:Text('Create a new training sheet for ${d.title} on ${when.toLocal()}?\n\nThe setup is copied. Roster, attendance, skill results, signatures, completion status and old timestamps are not copied.'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Create Repeat'))]))??false;
    if(!ok)return;
    setState(()=>_busy=true);
    try{
      final created=await _api.createTrainingSheet(title:d.title,startsAt:when.toUtc().toIso8601String(),trainingCategory:d.trainingCategory,checklistVersionId:d.checklistVersionId,creditHours:d.creditHours,location:d.location,notes:d.notes,proctorUserIds:d.proctorUserIds,selfRegistration:false);
      if(!mounted)return;
      context.go('${AppRoutes.departmentTrainingSheets}/${created.id}');
    }catch(e){if(mounted)setState(()=>_error=e.toString());}
    finally{if(mounted)setState(()=>_busy=false);}
  }

  Future<void> _exportCsv() async {
    final d=_detail; if(d==null||d.status!='COMPLETE'||_busy)return;
    setState(()=>_busy=true);
    try{
      final bytes=await _api.downloadClosedTrainingCsv(widget.classId);
      final dir=await getTemporaryDirectory();
      final safe=d.title.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'),'_');
      final file=File('${dir.path}/${safe.isEmpty?'training':safe}_${d.id}.csv');
      await file.writeAsBytes(bytes,flush:true);
      await Share.shareXFiles([XFile(file.path,mimeType:'text/csv')],subject:'${d.title} training record',text:'Closed Responder Roadmap training record for retention or manual RMS entry.');
    }catch(e){if(mounted)setState(()=>_error=e.toString());}
    finally{if(mounted)setState(()=>_busy=false);}
  }

  String _recordDate(DateTime? value) {
    if (value == null) return 'Not recorded';
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    final hour = local.hour == 0 ? 12 : (local.hour > 12 ? local.hour - 12 : local.hour);
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.month}/${local.day}/${local.year} $hour:${two(local.minute)} $period';
  }

  Future<Uint8List> _buildTrainingRecordPdf(
    DepartmentClassDetail detail,
    String departmentName,
  ) async {
    final document = pw.Document(
      title: '${detail.title} Training Record',
      author: departmentName.isEmpty ? 'Responder Roadmap' : departmentName,
      subject: 'Completed department training record',
    );
    final skillNames = <String, String>{
      for (final section in detail.sections)
        for (final skill in section.skills) skill.id: skill.title,
    };
    final rosterRows = detail.roster.map((student) => <String>[
      student.name,
      student.attendance.replaceAll('_', ' '),
      student.finalResult.replaceAll('_', ' '),
      student.writtenScore?.toStringAsFixed(1) ?? '',
      student.ccfScore?.toStringAsFixed(1) ?? '',
    ]).toList(growable: false);
    final resultRows = <List<String>>[];
    for (final student in detail.roster) {
      for (final result in student.results) {
        resultRows.add(<String>[
          student.name,
          skillNames[result.requirementId] ?? 'Checklist skill',
          result.result.replaceAll('_', ' '),
          result.evaluatorName,
          result.notes,
        ]);
      }
    }
    final ceSummary = detail.ceCredits
        .where((item) => (item['hours'] as num?)?.toDouble() != null && (item['hours'] as num).toDouble() > 0)
        .map((item) => '${item['category']}: ${(item['hours'] as num).toDouble().toStringAsFixed(2)} hr')
        .join(' | ');

    pw.Widget line(String label, String value) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(text: pw.TextSpan(children: [
        pw.TextSpan(text: '$label: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.TextSpan(text: value.isEmpty ? 'Not recorded' : value),
      ])),
    );

    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(36),
      header: (context) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 8),
        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: .5))),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text(departmentName.isEmpty ? 'Responder Roadmap' : departmentName,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('Official Training Record', style: const pw.TextStyle(fontSize: 9)),
        ]),
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount} | Training ID ${detail.id}',
          style: const pw.TextStyle(fontSize: 8)),
      ),
      build: (context) => [
        pw.SizedBox(height: 10),
        pw.Text(detail.title, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 12),
        line('Category', detail.trainingCategory.replaceAll('_', ' ')),
        line('Checklist', detail.checklistTitle),
        line('Location', detail.location),
        line('Station', detail.station),
        line('Shift', detail.shift),
        line('Start', _recordDate(detail.startsAt)),
        line('Finish', _recordDate(detail.endsAt)),
        line('Training hours', detail.creditHours.toStringAsFixed(2)),
        if (ceSummary.isNotEmpty) line('EMS CE credits', ceSummary),
        line('Status', detail.status),
        line('Instructor approval', _recordDate(detail.instructorApprovedAt)),
        line('RMS status', detail.rmsStatus.replaceAll('_', ' ')),
        if (detail.rmsEnteredAt != null) line('RMS entered', _recordDate(detail.rmsEnteredAt)),
        if (detail.rmsReference.isNotEmpty) line('RMS reference', detail.rmsReference),
        if (detail.notes.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Text('Class objectives and training narrative', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Text(detail.notes),
        ],
        pw.SizedBox(height: 16),
        pw.Text('Class roster', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: const ['Student', 'Attendance', 'Final result', 'Written', 'CCF'],
          data: rosterRows,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellPadding: const pw.EdgeInsets.all(4),
        ),
        if (resultRows.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          pw.Text('Checklist results', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: const ['Student', 'Skill', 'Result', 'Evaluator', 'Notes'],
            data: resultRows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellPadding: const pw.EdgeInsets.all(3),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.2), 1: pw.FlexColumnWidth(1.8),
              2: pw.FlexColumnWidth(.8), 3: pw.FlexColumnWidth(1.1), 4: pw.FlexColumnWidth(1.5),
            },
          ),
        ],
        pw.SizedBox(height: 14),
        pw.Text('Generated from the canonical Responder Roadmap record.', style: const pw.TextStyle(fontSize: 8)),
      ],
    ));
    return document.save();
  }

  Future<void> _printTrainingRecord() async {
    final detail = _detail;
    if (detail == null || detail.status != 'COMPLETE' || _busy) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Training record PDF', style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Print with AirPrint or share the PDF to Files, email, or another app.'),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: () => Navigator.pop(sheetContext, 'print'), icon: const Icon(Icons.print_outlined), label: const Text('Print Record')),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: () => Navigator.pop(sheetContext, 'share'), icon: const Icon(Icons.ios_share_outlined), label: const Text('Share / Save PDF')),
        ]),
      )),
    );
    if (action == null || !mounted) return;
    setState(() { _busy = true; _error = null; });
    try {
      var departmentName = '';
      try {
        final record = await _api.getClosedTrainingExportRecord(detail.id);
        final department = record['department'];
        if (department is Map) departmentName = department['name']?.toString() ?? '';
      } catch (_) {
        // The loaded canonical class still contains everything required to print.
      }
      final bytes = await _buildTrainingRecordPdf(detail, departmentName);
      final safe = detail.title.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
      final name = '${safe.isEmpty ? 'training' : safe}_${detail.id}.pdf';
      if (action == 'print') {
        await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
      } else {
        await Printing.sharePdf(bytes: bytes, filename: name);
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Unable to create the training record PDF: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _printQr(String url, String title) async {
    final document = pw.Document();
    document.addPage(pw.Page(
      pageFormat: PdfPageFormat.letter,
      build: (context) => pw.Center(child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: url, width: 250, height: 250),
          pw.SizedBox(height: 16),
          pw.Text('Scan to sign in to this training class'),
          pw.SizedBox(height: 8),
          pw.Text(url, style: const pw.TextStyle(fontSize: 9)),
        ],
      )),
    ));
    await Printing.layoutPdf(
      onLayout: (format) async => document.save(),
      name: '${title.replaceAll(RegExp(r'[^a-zA-Z0-9 _-]'), '')} QR Sign-in',
    );
  }

  Future<void> _showQr() async {
    final d=_detail; if(d==null)return;
    if(!d.registrationEnabled || d.registrationToken.isEmpty) await _registration('OPEN');
    if(!mounted||_registrationUrl.isEmpty)return;
    await showDialog<void>(context:context,builder:(context)=>AlertDialog(title:const Text('Crew QR Sign-in'),content:Column(mainAxisSize:MainAxisSize.min,children:[QrImageView(data:_registrationUrl,size:240),const SizedBox(height:12),const Text('Have attendees scan this code to join the live roster.',textAlign:TextAlign.center)]),actions:[TextButton.icon(onPressed:()=>_printQr(_registrationUrl,d.title),icon:const Icon(Icons.print_outlined),label:const Text('Print QR Code')),TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Done'))]));
    await _load();
  }

  Future<void> _addStudents() async {
    final detail=_detail;if(detail==null||_busy||detail.status=='COMPLETE')return;
    final setup=await _api.getClassSetup();
    if(!mounted)return;
    final selected=<String>{};
    final name=TextEditingController(),email=TextEditingController(),organization=TextEditingController();
    final action=await showDialog<String>(context:context,builder:(dialogContext)=>StatefulBuilder(
      builder:(dialogContext,update)=>AlertDialog(
        title:const Text('Add students'),
        content:SizedBox(width:460,child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          Text('Department roster',style:Theme.of(dialogContext).textTheme.titleMedium),
          ...setup.members.map((member){final id=member['id']?.toString()??'';return CheckboxListTile(
            contentPadding:EdgeInsets.zero,dense:true,title:Text(member['name']?.toString()??'Member'),value:selected.contains(id),
            onChanged:id.isEmpty?null:(value)=>update((){if(value==true){selected.add(id);}else{selected.remove(id);}}));}),
          const Divider(height:28),Text('Manual student',style:Theme.of(dialogContext).textTheme.titleMedium),
          const SizedBox(height:8),TextField(controller:name,onChanged:(_)=>update((){}),decoration:const InputDecoration(labelText:'Student name *')),
          const SizedBox(height:8),TextField(controller:email,onChanged:(_)=>update((){}),keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'Email (optional)')),
          const SizedBox(height:8),TextField(controller:organization,decoration:const InputDecoration(labelText:'Organization (optional)')),
        ]))),
        actions:[TextButton(onPressed:()=>Navigator.pop(dialogContext),child:const Text('Cancel')),
          if(selected.isNotEmpty) FilledButton(onPressed:()=>Navigator.pop(dialogContext,'roster'),child:Text('Add ${selected.length} selected')),
          if(name.text.trim().isNotEmpty) FilledButton(onPressed:()=>Navigator.pop(dialogContext,'manual'),child:const Text('Add manual student'))],
      ),
    ));
    final manualName=name.text.trim(),manualEmail=email.text.trim(),manualOrganization=organization.text.trim();
    name.dispose();email.dispose();organization.dispose();
    if(action==null||!mounted)return;
    setState((){_busy=true;_error=null;});
    try{
      _setDetail(action=='roster'
        ? await _api.addTrainingSheetRosterMembers(detail.id,selected.toList())
        : await _api.addManualTrainingSheetStudent(detail.id,name:manualName,email:manualEmail,organization:manualOrganization));
    }catch(error){if(mounted)setState(()=>_error='Unable to add students: $error');}
    finally{if(mounted)setState(()=>_busy=false);}
  }


  Future<String?> _correctionNotes(String title) async {
    final controller = TextEditingController();
    return showDialog<String>(context: context, builder: (context) => AlertDialog(title: Text(title), content: TextField(controller: controller, maxLines: 4, autofocus: true, decoration: const InputDecoration(labelText: 'What must the student correct?')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { if (controller.text.trim().isNotEmpty) Navigator.pop(context, controller.text.trim()); }, child: const Text('Save result'))]));
  }

  Future<void> _stageSkill(DepartmentClassStudent member, DepartmentClassSkill skill, String result) async {
    if (_busy || _detail?.status == 'COMPLETE' || member.attendance != 'PRESENT') return;
    var notes = '';
    if (result == 'FAIL' || result == 'NEEDS_REMEDIATION') {
      final entered = await _correctionNotes(result == 'FAIL' ? 'Record failed skill' : 'Remediation required');
      if (entered == null || entered.trim().isEmpty || !mounted) return;
      notes = entered.trim();
    }
    setState(() {
      _draftSkillResults.putIfAbsent(member.id, () => {})[skill.id] = result;
      _draftSkillNotes.putIfAbsent(member.id, () => {})[skill.id] = notes;
    });
  }

  Future<void> _submitSkillDrafts(DepartmentClassStudent member) async {
    final detail = _detail;
    final pending = Map<String, String>.from(_draftSkillResults[member.id] ?? {});
    final notes = Map<String, String>.from(_draftSkillNotes[member.id] ?? {});
    if (detail == null || _busy || pending.isEmpty || detail.status == 'COMPLETE') return;
    if (member.attendance != 'PRESENT') {
      setState(() => _error = 'Confirm this member as present before submitting skill results.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final batch = pending.entries.map((entry) {
        final previous = member.results
            .where((item) => item.requirementId == entry.key)
            .firstOrNull;
        return <String, dynamic>{
          'enrollmentId': member.id,
          'requirementId': entry.key,
          'result': entry.value,
          'notes': notes[entry.key] ?? '',
          'expectedUpdatedAt': previous?.updatedAt,
        };
      }).toList(growable: false);
      final saved = await _api.recordClassSkillBatchDurable(
        classId: detail.id,
        results: batch,
      );
      if (saved.detail != null) _setDetail(saved.detail!);
      if (saved.queued && mounted) {
        context.read<DepartmentInboxController>().submissionQueued();
      }
      if (mounted) {
        setState(() {
          for (final key in pending.keys) {
            _draftSkillResults[member.id]?.remove(key);
            _draftSkillNotes[member.id]?.remove(key);
          }
          if (saved.queued) _error = 'Skill results are saved on this device and waiting to sync. Review sync before closing.';
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(saved.queued ? '${pending.length} skill result(s) saved and waiting to sync.' : '${pending.length} individual skill result(s) submitted together.'),
        ));
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'No staged results were cleared. Review the connection and submit again: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _passGroupSkill(DepartmentClassStudent member, DepartmentClassSkill skill) async {
    final detail = _detail;
    if (detail == null || _busy || detail.status == 'COMPLETE') return;
    if (member.attendance != 'PRESENT') {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Confirm attendance before recording a pass.')));
      return;
    }
    setState(() => _busy = true);
    try {
      final previous = member.results
          .where((item) => item.requirementId == skill.id)
          .firstOrNull;
      final saved = await _api.recordClassSkillBatchDurable(
        classId: detail.id,
        requirementId: skill.id,
        results: [
          <String, dynamic>{
            'enrollmentId': member.id,
            'result': 'PASS',
            'notes': '',
            'expectedUpdatedAt': previous?.updatedAt,
          },
        ],
      );
      if (saved.detail != null) _setDetail(saved.detail!);
      if (saved.queued && mounted) {
        context.read<DepartmentInboxController>().submissionQueued();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Waiting to Sync — ${member.name} skill result saved on this device.')));
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showChecklistMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _focusRoster() async {
    await Future<void>.delayed(Duration.zero);
    if (!_detailScrollController.hasClients) return;

    void revealRoster() {
      final target = _rosterSectionKey.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.08,
        );
      }
    }

    if (_rosterSectionKey.currentContext == null) {
      await _detailScrollController.animateTo(
        _detailScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => revealRoster());
  }

  Future<void> _openAttendanceStep() async {
    final detail = _detail;
    if (detail == null) return;

    final selectedIds = <String>{};
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, updateSheet) {
          final current = _detail;
          if (current == null) return const SizedBox.shrink();
          final roster = current.roster;
          final attendanceComplete = roster.isNotEmpty &&
              roster.every((member) => member.attendance != 'REGISTERED');
          final presentCount =
              roster.where((member) => member.attendance == 'PRESENT').length;
          final absentCount =
              roster.where((member) => member.attendance == 'ABSENT').length;
          final selectedCount =
              roster.where((member) => selectedIds.contains(member.id)).length;
          final allSelected =
              roster.isNotEmpty && selectedCount == roster.length;

          Future<void> saveSelected(String attendance) async {
            final ids = roster
                .where((member) => selectedIds.contains(member.id))
                .map((member) => member.id)
                .toList();
            if (ids.isEmpty || saving) return;
            updateSheet(() => saving = true);
            for (final id in ids) {
              final latest = _detail?.roster
                  .where((member) => member.id == id)
                  .firstOrNull;
              if (latest != null && latest.attendance != attendance) {
                await _setRosterAttendance(latest, attendance);
              }
              if (!mounted) return;
            }
            selectedIds.clear();
            if (sheetContext.mounted) {
              updateSheet(() => saving = false);
            }
          }

          Future<void> saveOne(
            DepartmentClassStudent member,
            String attendance,
          ) async {
            if (saving || member.attendance == attendance) return;
            updateSheet(() => saving = true);
            await _setRosterAttendance(member, attendance);
            if (sheetContext.mounted) {
              updateSheet(() => saving = false);
            }
          }

          return FractionallySizedBox(
            heightFactor: 0.94,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Roster & attendance',
                              style: Theme.of(sheetContext)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            Text(
                              roster.isEmpty
                                  ? 'Build the roster, then record attendance.'
                                  : '${roster.length} students · $presentCount present · $absentCount absent',
                              style: Theme.of(sheetContext).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed:
                            saving ? null : () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: saving || current.status == 'COMPLETE'
                            ? null
                            : () async {
                                await _addStudents();
                                if (sheetContext.mounted) {
                                  updateSheet(() {});
                                }
                              },
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Add students'),
                      ),
                      OutlinedButton.icon(
                        onPressed: saving ? null : () async {
                          await _showQr();
                          if (sheetContext.mounted) {
                            updateSheet(() {});
                          }
                        },
                        icon: const Icon(Icons.qr_code_2_rounded),
                        label: const Text('Roster QR'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (roster.isNotEmpty) ...[
                    Row(
                      children: [
                        Checkbox(
                          value: allSelected,
                          tristate: selectedCount > 0 && !allSelected,
                          onChanged: saving
                              ? null
                              : (value) => updateSheet(() {
                                    if (value == true) {
                                      selectedIds.addAll(
                                        roster.map((member) => member.id),
                                      );
                                    } else {
                                      selectedIds.clear();
                                    }
                                  }),
                        ),
                        Expanded(
                          child: Text(
                            allSelected
                                ? 'All students selected'
                                : selectedCount == 0
                                    ? 'Select all'
                                    : '$selectedCount selected',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: saving
                              ? null
                              : () => updateSheet(() {
                                    if (allSelected) {
                                      selectedIds.clear();
                                    } else {
                                      selectedIds.addAll(
                                        roster.map((member) => member.id),
                                      );
                                    }
                                  }),
                          child: Text(allSelected ? 'Clear' : 'Select all'),
                        ),
                      ],
                    ),
                    if (selectedCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: saving
                                    ? null
                                    : () => saveSelected('PRESENT'),
                                icon: const Icon(Icons.check_rounded),
                                label: const Text('Mark present'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: saving
                                    ? null
                                    : () => saveSelected('ABSENT'),
                                icon: const Icon(Icons.person_off_outlined),
                                label: const Text('Mark absent'),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  Expanded(
                    child: roster.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.groups_2_outlined,
                                    size: 52,
                                    color: Theme.of(sheetContext)
                                        .colorScheme
                                        .primary,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No students on the roster yet.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Use the QR code, choose members from the department list, or add a student manually.',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: roster.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final member = roster[index];
                              final selected =
                                  selectedIds.contains(member.id);
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Checkbox(
                                      value: selected,
                                      onChanged: saving
                                          ? null
                                          : (value) => updateSheet(() {
                                                if (value == true) {
                                                  selectedIds.add(member.id);
                                                } else {
                                                  selectedIds.remove(member.id);
                                                }
                                              }),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            member.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: [
                                              ChoiceChip(
                                                label: const Text('Present'),
                                                selected:
                                                    member.attendance ==
                                                        'PRESENT',
                                                onSelected: saving ||
                                                        current.status ==
                                                            'COMPLETE'
                                                    ? null
                                                    : (_) => saveOne(
                                                          member,
                                                          'PRESENT',
                                                        ),
                                              ),
                                              ChoiceChip(
                                                label: const Text('Absent'),
                                                selected:
                                                    member.attendance ==
                                                        'ABSENT',
                                                onSelected: saving ||
                                                        current.status ==
                                                            'COMPLETE'
                                                    ? null
                                                    : (_) => saveOne(
                                                          member,
                                                          'ABSENT',
                                                        ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (member.attendance == 'REGISTERED')
                                      Icon(
                                        Icons.error_outline_rounded,
                                        color: Theme.of(sheetContext)
                                            .colorScheme
                                            .error,
                                      )
                                    else
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.green,
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  if (!attendanceComplete && roster.isNotEmpty)
                    Text(
                      'Mark every student present or absent to finish this step.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(sheetContext).colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: saving || !attendanceComplete
                        ? null
                        : () => Navigator.pop(sheetContext),
                    icon: saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.done_rounded),
                    label: const Text('Finish roster & attendance'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openSkillsStep() async {
    final detail = _detail;
    if (detail == null) return;
    if (detail.status == 'COMPLETE') {
      await _focusRoster();
      return;
    }
    if (!detail.roster.any((member) => member.attendance == 'PRESENT')) {
      _showChecklistMessage('Confirm at least one student as present before grading skills.');
      await _openAttendanceStep();
      return;
    }
    await _showSkillsEvaluationWorkspace();
  }

  Future<void> _chooseEvaluationSetup() async {
    final detail = _detail;
    if (detail == null || _busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      final results = await Future.wait<dynamic>([
        _api.listTrainingSheetTemplates(),
        _api.getClassSetup(),
      ]);
      if (!mounted) return;
      final templates = results[0] as List<DepartmentTrainingSheetTemplate>;
      final setup = results[1] as DepartmentClassSetup;
      final choice = await showModalBottomSheet<Map<String, String>>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (sheetContext) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: .75,
          maxChildSize: .94,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              Text('Add skills & evaluation setup', style: Theme.of(sheetContext).textTheme.headlineSmall),
              const SizedBox(height: 6),
              const Text('Choose a prebuilt Training Sheet setup or a department checklist. It is copied to this class.'),
              const SizedBox(height: 18),
              if (templates.isNotEmpty) ...[
                Text('Saved class packages', style: Theme.of(sheetContext).textTheme.titleMedium),
                const Text('Selecting a package copies its checklist, grading rules, custom result fields, and EMS CE allocation onto this sheet.'),
                for (final template in templates.where((item) =>
                    item.checklistVersionId.isNotEmpty || item.gradingConfig.isNotEmpty || item.customFields.isNotEmpty || item.ceCredits.isNotEmpty))
                  ListTile(
                    leading: const Icon(Icons.fact_check_outlined),
                    title: Text(template.name),
                    subtitle: Text(
                      template.ceCredits.isNotEmpty && detail.trainingCategory != 'EMS'
                          ? '${_trainingTemplateSummary(template)} · Set this sheet to EMS before applying its CE allocation.'
                          : _trainingTemplateSummary(template),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(
                      template.ceCredits.isNotEmpty && detail.trainingCategory != 'EMS'
                          ? Icons.info_outline_rounded
                          : Icons.chevron_right_rounded,
                    ),
                    onTap: template.ceCredits.isNotEmpty && detail.trainingCategory != 'EMS'
                        ? null
                        : () => Navigator.pop(sheetContext, {
                            'trainingSheetTemplateId': template.id,
                          }),
                  ),
                const Divider(),
              ],
              Text('Department checklists', style: Theme.of(sheetContext).textTheme.titleMedium),
              for (final checklist in setup.checklists)
                ListTile(
                  leading: const Icon(Icons.checklist_rounded),
                  title: Text(checklist['title']?.toString() ?? 'Checklist'),
                  subtitle: Text('${checklist['skillCount'] ?? 0} skills · version ${checklist['version'] ?? ''}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(sheetContext, {
                    'checklistVersionId': checklist['id']?.toString() ?? '',
                  }),
                ),
            ],
          ),
        ),
      );
      if (choice == null || !mounted) return;
      final selectedTemplate = templates.where((item) => item.id == choice['trainingSheetTemplateId']).firstOrNull;
      final hasExistingSetup = detail.templateName.isNotEmpty ||
          detail.gradingConfig.isNotEmpty ||
          detail.customFields.isNotEmpty ||
          detail.ceCredits.isNotEmpty;
      if (selectedTemplate != null && hasExistingSetup) {
        final replace = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Apply this class package?'),
            content: const Text('This replaces the current grading rules and custom result fields. If the package has an EMS CE allocation, it replaces the current CE breakdown too. Existing student records remain attached to the class.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Keep current setup')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Apply package')),
            ],
          ),
        );
        if (replace != true || !mounted) return;
      }
      setState(() => _busy = true);
      final updated = await _api.updateClassEvaluationSetup(
        classId: detail.id,
        trainingSheetTemplateId: choice['trainingSheetTemplateId'] ?? '',
        checklistVersionId: choice['checklistVersionId'] ?? '',
      );
      _setDetail(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Instructor setup copied to this Training Sheet')),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Unable to add evaluation setup: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showSkillsEvaluationWorkspace() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, updateSheet) {
          final detail = _detail!;
          final skills = detail.sections.expand((section) => section.skills).toList();
          final present = detail.roster.where((member) => member.attendance == 'PRESENT').toList();
          final hasGrades = detail.gradingConfig.isNotEmpty || detail.customFields.isNotEmpty;
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: .88,
            maxChildSize: .96,
            builder: (_, controller) => ListView(
              controller: controller,
              padding: const EdgeInsets.all(20),
              children: [
                Row(children: [
                  Expanded(child: Text('Skills & evaluations', style: Theme.of(sheetContext).textTheme.headlineSmall)),
                  IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close_rounded)),
                ]),
                Text('${present.length} present student${present.length == 1 ? '' : 's'}'),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () async {
                    await _chooseEvaluationSetup();
                    if (mounted) updateSheet(() {});
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: Text(skills.isEmpty && !hasGrades ? 'Add prebuilt checklist or grading setup' : 'Add or change evaluation setup'),
                ),
                if (skills.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text('Skills checklist', style: Theme.of(sheetContext).textTheme.titleLarge),
                  Text('${skills.length} skill${skills.length == 1 ? '' : 's'} ready to evaluate'),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _busy ? null : () async {
                      Navigator.pop(sheetContext);
                      await _groupGrade();
                    },
                    icon: const Icon(Icons.done_all_rounded),
                    label: const Text('Check or grade skills · Apply to all'),
                  ),
                ],
                if (hasGrades) ...[
                  const SizedBox(height: 22),
                  Text('Student grades', style: Theme.of(sheetContext).textTheme.titleLarge),
                  const Text('Open a student to record written, CCF, or template grading fields.'),
                  const SizedBox(height: 8),
                  for (final student in present)
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person_outline_rounded)),
                        title: Text(student.name),
                        subtitle: Text([
                          if (student.writtenScore != null) 'Written ${student.writtenScore}%',
                          if (student.ccfScore != null) 'CCF ${student.ccfScore}%',
                          if (student.writtenScore == null && student.ccfScore == null) 'Tap to grade',
                        ].join(' · ')),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _busy ? null : () async {
                          await _editCustomResults(detail, student);
                          if (mounted) updateSheet(() {});
                        },
                      ),
                    ),
                ],
                if (skills.isEmpty && !hasGrades) ...[
                  const SizedBox(height: 24),
                  const Icon(Icons.assignment_add, size: 48),
                  const SizedBox(height: 8),
                  const Text('Add a prebuilt setup to begin evaluating students.', textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Finish skills & evaluations'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _activateCloseoutStep(
    int index,
    DepartmentClassDetail detail, {
    required bool canRecordRmsEntry,
  }) async {
    switch (index) {
      case 0:
        await _openAttendanceStep();
        return;
      case 1:
        await _openSkillsStep();
        return;
      case 2:
        if (detail.status != 'COMPLETE') {
          await _reviewAndFinish();
        } else if (detail.instructorApprovedAt == null) {
          await _approveTrainingSheet();
        } else {
          _showChecklistMessage('Training is already closed and instructor approved.');
        }
        return;
      case 3:
        if (detail.rmsStatus == 'RMS_ENTERED') {
          _showChecklistMessage('Department RMS entry is already recorded.');
        } else if (!canRecordRmsEntry) {
          _showChecklistMessage(
            'Only an authorized department administrator can record RMS entry.',
          );
        } else if (detail.rmsStatus != 'AWAITING_ENTRY') {
          _showChecklistMessage(
            'Instructor approval is required before RMS entry.',
          );
        } else {
          await _markRmsEntered();
        }
        return;
    }
  }

  Widget _closeoutChecklist(
    DepartmentClassDetail detail, {
    required bool canRecordRmsEntry,
  }) {
    final rosterAttendanceDone = detail.roster.isNotEmpty &&
        detail.roster.every((member) => member.attendance != 'REGISTERED');
    final skillsDone = rosterAttendanceDone &&
        detail.roster.where((member) => member.attendance == 'PRESENT')
            .every((member) => _studentComplete(detail, member));
    final reviewApprovalDone = detail.status == 'COMPLETE' &&
        detail.instructorApprovedAt != null;
    final rmsDone = detail.rmsStatus == 'RMS_ENTERED';
    final completed = <bool>[
      rosterAttendanceDone,
      skillsDone,
      reviewApprovalDone,
      rmsDone,
    ];
    final requiredIncomplete = <bool>[
      !rosterAttendanceDone,
      rosterAttendanceDone && !skillsDone,
      !reviewApprovalDone,
      reviewApprovalDone && !rmsDone,
    ];
    final labels = <String>[
      'Roster & attendance',
      'Skills & evaluations',
      'Review & instructor approval',
      'Department RMS entry',
    ];
    final readyCount = detail.roster
        .where((member) => _studentComplete(detail, member))
        .length;
    final descriptions = <String>[
      detail.roster.isEmpty
          ? 'Tap to add students or open QR sign-in'
          : rosterAttendanceDone
              ? '${detail.roster.length} registered · Attendance verified'
              : '${detail.roster.where((member) => member.attendance != 'REGISTERED').length}/${detail.roster.length} attendance recorded · Tap to update',
      skillsDone
          ? '$readyCount present students ready'
          : rosterAttendanceDone
              ? '$readyCount ready · Tap to grade required skills'
              : 'Complete roster and attendance first',
      reviewApprovalDone
          ? 'Training closed and instructor approved'
          : detail.status == 'COMPLETE'
              ? 'Tap to record instructor approval'
              : 'Review required items, close the sheet, then approve',
      rmsDone
          ? 'Department RMS entry recorded'
          : detail.rmsStatus == 'AWAITING_ENTRY' && canRecordRmsEntry
              ? 'Tap to record the department RMS entry'
              : detail.rmsStatus == 'AWAITING_ENTRY'
                  ? 'Waiting for an authorized department administrator'
                  : 'Available after instructor approval',
    ];
    final count = completed.where((value) => value).length;
    final error = Theme.of(context).colorScheme.error;
    return Card(child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Closeout checklist', style: Theme.of(context).textTheme.titleLarge),
        Text('$count of 4 complete'),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: count / 4),
        for (var i = 0; i < labels.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              completed[i]
                  ? Icons.check_circle
                  : requiredIncomplete[i]
                      ? Icons.error_outline_rounded
                      : Icons.radio_button_unchecked,
              color: completed[i]
                  ? Colors.green
                  : requiredIncomplete[i]
                      ? error
                      : null,
            ),
            title: Text(
              labels[i],
              style: requiredIncomplete[i] && !completed[i]
                  ? TextStyle(color: error, fontWeight: FontWeight.w700)
                  : null,
            ),
            subtitle: Text(
              descriptions[i],
              style: requiredIncomplete[i] && !completed[i]
                  ? TextStyle(color: error)
                  : null,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _busy
                ? null
                : () => _activateCloseoutStep(
                      i,
                      detail,
                      canRecordRmsEntry: canRecordRmsEntry,
                    ),
          ),
      ]),
    ));
  }


  @override
  Widget build(BuildContext context) {
    final detail = _detail; final student = _student;
    final mode = context.watch<AppModeController>();
    final canRecordRmsEntry = mode.isAdmin;
    return Scaffold(appBar: AppBar(title: Text(detail?.title ?? 'Training Sheet')), body: detail == null ? Center(child: _error == null ? const CircularProgressIndicator() : Text(_error!)) : ListView(
      controller: _detailScrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
      _closeoutChecklist(detail, canRecordRmsEntry: canRecordRmsEntry),
      const SizedBox(height: 10),
      TrainingSheetHeaderCard(detail: detail),
      const SizedBox(height: 10),
      TrainingSheetTimeHoursCard(detail: detail, onEditTimes: _busy ? () {} : () async { await _editTrainingDocumentation(); }),
      const SizedBox(height: 10),
      Consumer<DepartmentInboxController>(builder:(context,sync,_) {
        final waiting=sync.syncState==DepartmentSyncState.waitingToUpload;
        final failed=sync.syncState==DepartmentSyncState.failed;
        if(!waiting&&!failed)return const SizedBox.shrink();
        return Card(child:Padding(padding:const EdgeInsets.all(12),child:Row(children:[
          Icon(waiting?Icons.cloud_upload_outlined:Icons.cloud_off_outlined),
          const SizedBox(width:10),
          Expanded(child:Text(waiting?'Waiting to Sync — saved field changes will retry; skill conflicts require instructor review.':'Sync Failed — saved field changes remain on this device. Review offline skill results before closeout.')),
          TextButton(onPressed:()=>sync.refresh(),child:const Text('Retry')),
        ])));
      }),

      Builder(builder: (context) {
        final statusTone = detail.status == 'COMPLETE'
            ? (detail.instructorApprovedAt != null ? FireOpsSemanticColors.green : FireOpsSemanticColors.amber)
            : (detail.roster.isEmpty ? FireOpsSemanticColors.amber : FireOpsSemanticColors.blue);

        String title;
        String subtitle;
        VoidCallback? primary;
        String primaryLabel;
        IconData primaryIcon;
        final secondary = <Widget>[];

        if (detail.status != 'COMPLETE' && detail.roster.isEmpty) {
          title = 'Next action: Start roster';
          subtitle = 'Show QR for self-registration or add students manually.';
          primary = _busy ? null : _showQr;
          primaryLabel = 'Show QR';
          primaryIcon = Icons.qr_code_2_rounded;
          secondary.add(OutlinedButton.icon(onPressed: _busy ? null : _addStudents, icon: const Icon(Icons.person_add_alt_1_outlined), label: const Text('Add students')));
        } else if (detail.status != 'COMPLETE' && detail.roster.any((m) => m.attendance == 'REGISTERED')) {
          title = 'Next action: Attendance';
          subtitle = 'Confirm attendance for every student (present/absent).';
          primary = _busy ? null : _openAttendanceStep;
          primaryLabel = 'Open attendance recorder';
          primaryIcon = Icons.people_alt_outlined;
        } else if (detail.status != 'COMPLETE' && detail.roster.any((m) => m.attendance == 'PRESENT' && !_studentComplete(detail, m))) {
          title = 'Next action: Skill evaluations';
          subtitle = 'Grade required skills for present students.';
          primary = _busy ? null : _groupGrade;
          primaryLabel = 'Grade skills';
          primaryIcon = Icons.fact_check_outlined;
        } else if (detail.status != 'COMPLETE') {
          title = 'Next action: Closeout';
          subtitle = 'Set end time, narrative, then review and close the Training Sheet.';
          primary = _busy ? null : () async { await _editTrainingDocumentation(); };
          primaryLabel = 'Edit documentation';
          primaryIcon = Icons.edit_note_rounded;
          secondary.add(OutlinedButton.icon(onPressed: _busy ? null : _reviewAndFinish, icon: const Icon(Icons.rate_review_outlined), label: const Text('Review & Close')));
        } else if (detail.rmsStatus == 'NOT_READY') {
          title = 'Next action: Instructor approval';
          subtitle = 'Review the completed sheet and approve as the instructor.';
          primary = _busy ? null : _approveTrainingSheet;
          primaryLabel = 'Instructor approve';
          primaryIcon = Icons.approval_outlined;
        } else if (detail.rmsStatus == 'AWAITING_ENTRY' && canRecordRmsEntry) {
          title = 'Next action: RMS entry';
          subtitle = 'Record RMS entry once your department’s record is complete.';
          primary = _busy ? null : _markRmsEntered;
          primaryLabel = 'Mark RMS entered';
          primaryIcon = Icons.fact_check_outlined;
        } else {
          title = 'Status: RMS entry pending';
          subtitle = 'Waiting for an authorized department administrator to record RMS entry.';
          primary = null;
          primaryLabel = '—';
          primaryIcon = Icons.hourglass_bottom_rounded;
        }

        return TrainingSheetNextActionCard(
          title: title,
          subtitle: subtitle,
          primaryAction: primary,
          primaryLabel: primaryLabel,
          primaryIcon: primaryIcon,
          secondaryActions: secondary,
          statusTone: statusTone,
        );
      }),
      if (_error != null)
        Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
            ),
          ),
        ),
      if (detail.ceCredits.isNotEmpty || detail.gradingConfig.isNotEmpty)
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Template requirements', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          if (detail.ceCredits.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('EMS CE: ${detail.ceCredits.map((item) => '${item['hours']} hr ${item['category']}').join(' · ')}')),
          if (detail.gradingConfig.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Required scores: ${[
            if (detail.gradingConfig['writtenTestEnabled'] == true) 'Written test${detail.gradingConfig['writtenTestPassPercent'] != null ? ' ≥${detail.gradingConfig['writtenTestPassPercent']}%' : ''}',
            if (detail.gradingConfig['ccfEnabled'] == true) 'CCF${detail.gradingConfig['ccfPassPercent'] != null ? ' ≥${detail.gradingConfig['ccfPassPercent']}%' : ''}',
          ].join(' · ').isEmpty ? 'None' : [
            if (detail.gradingConfig['writtenTestEnabled'] == true) 'Written test${detail.gradingConfig['writtenTestPassPercent'] != null ? ' ≥${detail.gradingConfig['writtenTestPassPercent']}%' : ''}',
            if (detail.gradingConfig['ccfEnabled'] == true) 'CCF${detail.gradingConfig['ccfPassPercent'] != null ? ' ≥${detail.gradingConfig['ccfPassPercent']}%' : ''}',
          ].join(' · ')}')),
        ]))),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('TRAINING SHEET WORKFLOW', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              detail.status != 'COMPLETE'
                  ? '1  Roster / QR   →   2  Attendance & skills   →   3  Review & close   →   4  Instructor approve'
                  : detail.rmsStatus == 'NOT_READY'
                      ? 'Roster and results are closed. Review the completed sheet, then approve it as the instructor.'
                      : detail.rmsStatus == 'AWAITING_ENTRY'
                          ? 'Instructor work complete. This Training Sheet is now waiting for the department RMS-entry step.'
                          : 'Training Sheet complete. RMS entry has been recorded.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ]),
        ),
      ),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live class progress', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('${detail.roster.where((member) => member.attendance != 'REGISTERED').length}/${detail.roster.length} attendance recorded'),
          const SizedBox(height: 6),
          Text('${detail.roster.where((member) => _studentComplete(detail, member)).length}/${detail.roster.where((member) => member.attendance == 'PRESENT').length} present students ready'),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: detail.roster.isEmpty ? 0 : detail.roster.where((member) => _missingFor(detail, member).isEmpty).length / detail.roster.length),
        ],
      ))),
      const SizedBox(height: 10),
      // Keep secondary class tools accessible without competing with Next step.
      if (detail.status != 'COMPLETE')
        ExpansionTile(
          title: const Text('More class actions'),
          initiallyExpanded: false,
          children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(onPressed: _busy ? null : _showQr, icon: const Icon(Icons.qr_code_2_rounded), label: const Text('QR sign-in')),
              OutlinedButton.icon(onPressed: _busy ? null : _addStudents, icon: const Icon(Icons.person_add_alt_1_outlined), label: const Text('Add students')),
              OutlinedButton.icon(onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh_rounded), label: const Text('Refresh roster')),
              OutlinedButton.icon(onPressed: _busy ? null : _reviewPendingSkillSync,
                  icon: const Icon(Icons.sync_problem_outlined),
                  label: const Text('Review offline skill results')),
              OutlinedButton.icon(onPressed: _busy || detail.roster.isEmpty ? null : _groupGrade, icon: const Icon(Icons.fact_check_outlined), label: const Text('Group grade')),
              OutlinedButton.icon(onPressed: _busy || detail.roster.isEmpty ? null : _reviewAndFinish, icon: const Icon(Icons.rate_review_outlined), label: const Text('Review & Finish')),
            ]),
          ],
        ),
      if (detail.status == 'COMPLETE') ...[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  detail.rmsStatus == 'RMS_ENTERED'
                      ? Icons.task_alt_rounded
                      : detail.rmsStatus == 'AWAITING_ENTRY'
                          ? Icons.assignment_late_outlined
                          : Icons.verified_rounded,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    detail.rmsStatus == 'RMS_ENTERED'
                        ? 'Training approved and RMS entry recorded.'
                        : detail.rmsStatus == 'AWAITING_ENTRY'
                            ? 'Instructor approved — RMS Actions Needed.'
                            : 'Training closed — instructor approval is still required.',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (detail.rmsStatus == 'NOT_READY')
              FilledButton.icon(
                onPressed: _busy ? null : _approveTrainingSheet,
                icon: const Icon(Icons.approval_outlined),
                label: const Text('Instructor Approve'),
              ),
            if (detail.rmsStatus == 'AWAITING_ENTRY' && canRecordRmsEntry)
              FilledButton.icon(
                onPressed: _busy ? null : _markRmsEntered,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Mark RMS Entered'),
              ),
            if (detail.rmsStatus == 'AWAITING_ENTRY' && !canRecordRmsEntry)
              const Chip(
                avatar: Icon(Icons.forward_to_inbox_outlined, size: 18),
                label: Text('Sent to RMS Actions Needed'),
              ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _repeatTraining,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Repeat Training'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _exportCsv,
              icon: const Icon(Icons.table_view_outlined),
              label: const Text('Export CSV for RMS'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _printTrainingRecord,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('PDF / Print Record'),
            ),
          ],
        ),
      ],
      const SizedBox(height: 12),
      if (detail.status != 'COMPLETE' && detail.roster.isNotEmpty && detail.sections.any((section) => section.skills.isNotEmpty)) ...[
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Skill Grading', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Select a skill and record each observed result separately. Group grading never approves the entire roster.'),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: ValueKey(_groupSkillId),
              initialValue: detail.sections.expand((section) => section.skills).any((skill) => skill.id == _groupSkillId) ? _groupSkillId : null,
              decoration: const InputDecoration(labelText: 'Skill being evaluated'),
              isExpanded: true,
              items: detail.sections.expand((section) => section.skills).map((skill) =>
                DropdownMenuItem(value: skill.id, child: Text(skill.title, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: _busy ? null : (value) => setState(() => _groupSkillId = value),
            ),
            if (_groupSkillId != null) ...[
              const SizedBox(height: 10),
              for (final member in detail.roster)
                Builder(builder: (context) {
                  final skill = detail.sections.expand((section) => section.skills).where((s) => s.id == _groupSkillId).firstOrNull;
                  if (skill == null) return const SizedBox.shrink();
                  final result = member.results.where((r) => r.requirementId == skill.id).firstOrNull;
                  return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(member.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${member.attendance} · ${result?.result ?? 'NOT_EVALUATED'}', style: Theme.of(context).textTheme.bodySmall),
                    ])),
                    TextButton(
                      onPressed: _busy ? null : () => setState(() => _studentId = member.id),
                      child: const Text('Details'),
                    ),
                    FilledButton(
                      onPressed: _busy || member.attendance != 'PRESENT' ? null : () => _passGroupSkill(member, skill),
                      child: const Text('Pass'),
                    ),
                  ]));
                }),
            ],
          ],
        ))),
      ],
      if (mode.isAdmin)
        ExpansionTile(
          title: const Text('Optional: Connect to Task Book'),
          initiallyExpanded: false,
          children: [
            ClassTaskBookLinkCard(detail: detail, onAssigned: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task Book assignments updated.')));
            }),
          ],
        ),
      ExpansionTile(
        title: const Text('Roster tools'),
        initiallyExpanded: false,
        children: [
          Padding(padding: const EdgeInsets.all(12), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick roster recorder', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Choose attendance or grading. Select a member, record the result, then move to the next.'),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Attendance'), icon: Icon(Icons.people_outline)),
              ButtonSegment(value: true, label: Text('Grade skills'), icon: Icon(Icons.fact_check_outlined)),
            ],
            selected: {_showGrading},
            onSelectionChanged: (choice) => setState(() => _showGrading = choice.first),
          ),
          if (!_showGrading && detail.status != 'COMPLETE' &&
              detail.roster.any((m) => m.attendance == 'REGISTERED'))
            OutlinedButton.icon(
              onPressed: _busy ? null : _confirmRosterAttendance,
              icon: const Icon(Icons.done_all_rounded),
              label: Text('Confirm ${detail.roster.where((m) => m.attendance == 'REGISTERED').length} registered attendees'),
            ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show only members needing attention'),
            value: _missingOnly,
            onChanged: (value) => setState(() => _missingOnly = value ?? false),
          ),
        ],
          )),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          '${detail.roster.where((m) => m.attendance != 'REGISTERED').length} of ${detail.roster.length} attendance recorded · '
          '${detail.roster.where((m) => _studentComplete(detail, m)).length} of ${detail.roster.length} ready',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      Row(
        key: _rosterSectionKey,
        children: [
        Expanded(child: Text('Roster', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
        Text('${detail.roster.where((item) => _studentComplete(detail, item)).length}/${detail.roster.length} ready', style: Theme.of(context).textTheme.labelLarge),
      ]),
      const SizedBox(height: 8),
      if (detail.status != 'COMPLETE' && detail.roster.isNotEmpty)
        Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          OutlinedButton.icon(
            onPressed: _busy ? null : () => setState(() {
              _selectAttendance = !_selectAttendance;
              if (!_selectAttendance) _selectedAttendanceIds.clear();
            }),
            icon: Icon(_selectAttendance ? Icons.close : Icons.checklist_rounded),
            label: Text(_selectAttendance ? 'Cancel selection' : 'Select attendance'),
          ),
          if (_selectAttendance) ...[
            TextButton(
              onPressed: _busy ? null : () => setState(() {
                final pending = detail.roster.where((member) => member.attendance == 'REGISTERED');
                if (_selectedAttendanceIds.length == pending.length) {
                  _selectedAttendanceIds.clear();
                } else {
                  _selectedAttendanceIds.addAll(pending.map((member) => member.id));
                }
              }),
              child: const Text('Select pending'),
            ),
            FilledButton(
              onPressed: _busy || _selectedAttendanceIds.isEmpty ? null : _confirmSelectedAttendance,
              child: Text('Confirm ${_selectedAttendanceIds.length} present'),
            ),
          ],
        ]),
      if (detail.roster.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text('No members registered yet. Share the training QR code to build the roster.'),
        )
      else
        Card(
          child: Column(
            children: [
              for (final item in detail.roster.where((item) => !_missingOnly || _missingFor(detail, item).isNotEmpty))
                Builder(builder: (context) {
                  final selected = item.id == _studentId;
                  final complete = _studentComplete(detail, item);
                  return ListTile(
                    selected: selected,
                    selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.45),
                    leading: _selectAttendance && item.attendance == 'REGISTERED'
                        ? Checkbox(
                            value: _selectedAttendanceIds.contains(item.id),
                            onChanged: _busy ? null : (checked) => setState(() {
                              if (checked == true) {
                                _selectedAttendanceIds.add(item.id);
                              } else {
                                _selectedAttendanceIds.remove(item.id);
                              }
                            }),
                          )
                        : Icon(
                            complete ? Icons.check_circle_rounded : Icons.person_outline_rounded,
                            color: complete ? Colors.green : null,
                          ),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${item.attendance.replaceAll('_', ' ')} · ${_passedRequiredCount(detail, item)}/${_requiredSkillCount(detail)} required skills passed'
                      '${_missingFor(detail, item).isEmpty ? '' : '\\nNeeds: ${_missingFor(detail, item)}'}',
                    ),
                    trailing: Icon(selected ? Icons.keyboard_arrow_down_rounded : Icons.chevron_right_rounded),
                    onTap: () => setState(() {
                      if (_selectAttendance && item.attendance == 'REGISTERED') {
                        if (!_selectedAttendanceIds.add(item.id)) _selectedAttendanceIds.remove(item.id);
                      } else {
                        _studentId = item.id;
                      }
                    }),
                    // Attendance stays individually attributable; no implicit passes.
                    isThreeLine: false,
                  );
                }),
            ],
          ),
        ),
      if (detail.status != 'COMPLETE' && detail.roster.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text('Tap a member to edit. Attendance can also be recorded below.',
              style: Theme.of(context).textTheme.bodySmall),
        ),
      const SizedBox(height: 10),
      if (detail.status != 'COMPLETE' && detail.roster.isNotEmpty && detail.roster.any((item) => !_studentComplete(detail, item)))
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.pending_actions_rounded),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  '${detail.roster.where((item) => !_studentComplete(detail, item)).length} member(s) still need attendance or required skill results before the sheet is ready to finish.',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                )),
              ]),
            ),
          ),
        ),
      if (student != null && (!_missingOnly || _missingFor(detail, student).isNotEmpty)) ...[
        const SizedBox(height: 12),
        Card(
          key: _memberEditorKey,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              CircleAvatar(child: Text(student.name.trim().isEmpty ? '?' : student.name.trim().substring(0, 1).toUpperCase())),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(student.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text('${student.attendance.replaceAll('_', ' ')} · ${_passedRequiredCount(detail, student)}/${_requiredSkillCount(detail)} required skills passed'),
              ])),
              IconButton(tooltip: 'Next member', onPressed: _nextStudent, icon: const Icon(Icons.arrow_forward_rounded)),
            ]),
          ),
        ),
        if (detail.customFields.isNotEmpty || detail.gradingConfig.isNotEmpty) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy || detail.status == 'COMPLETE' ? null : () => _editCustomResults(detail, student),
            icon: const Icon(Icons.fact_check_outlined),
            label: Text(detail.gradingConfig.isNotEmpty && detail.customFields.isEmpty ? 'Record required scores' : 'Template-specific student results'),
          ),
        ],
        if (!_showGrading) ...[
        const SizedBox(height: 10),
        if (detail.status != 'COMPLETE')
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final status in const ['PRESENT', 'ABSENT', 'EXCUSED'])
              ChoiceChip(
                label: Text(status == 'PRESENT' ? 'Present' : status == 'ABSENT' ? 'Absent' : 'Excused'),
                selected: student.attendance == status,
                onSelected: _busy ? null : (_) => _setRosterAttendance(student, status),
              ),
          ]),
        const SizedBox(height: 10), DropdownButtonFormField<String>(key: ValueKey(student.id), initialValue: student.attendance, decoration: const InputDecoration(labelText: 'Attendance'), items: const ['REGISTERED', 'PRESENT', 'ABSENT', 'EXCUSED'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(), onChanged: _busy || detail.status == 'COMPLETE' ? null : (value) async { if (value == null) return; setState(() => _busy = true); try { final saved=await _api.updateClassStudentDurable(classId:detail.id,enrollmentId:student.id,attendance:value); if(saved.detail!=null){_setDetail(saved.detail!); _nextStudent();} if(saved.queued&&context.mounted){context.read<DepartmentInboxController>().submissionQueued();ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Waiting to Sync — attendance saved safely on this device.')));} } catch(e) { if (mounted) setState(() => _error = e.toString()); } finally { if (mounted) setState(() => _busy = false); } }),
        ] else ...[
        const SizedBox(height: 10),
        Text('Select all observed skill results first, then submit once. Results remain individual records.', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _busy || detail.status == 'COMPLETE' || (_draftSkillResults[student.id]?.isEmpty ?? true)
            ? null : () => _submitSkillDrafts(student),
          icon: const Icon(Icons.send_rounded),
          label: Text('Submit ${_draftSkillResults[student.id]?.length ?? 0} results'),
        ),
        const SizedBox(height: 18),
        ...detail.sections.map((section) => Card(margin: const EdgeInsets.only(bottom: 14), clipBehavior: Clip.antiAlias, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: double.infinity, padding: const EdgeInsets.all(14), color: Theme.of(context).colorScheme.surfaceContainerHighest, child: Text(section.title, style: const TextStyle(fontWeight: FontWeight.w900))),
          ...section.skills.map((skill) { DepartmentClassSkillResult? recorded; for (final item in student.results) { if (item.requirementId == skill.id) recorded = item; } return Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(skill.title, style: const TextStyle(fontWeight: FontWeight.w800))), Chip(label: Text((recorded?.result ?? 'NOT_EVALUATED').replaceAll('_', ' ')))]),
            if (skill.description.isNotEmpty) Text(skill.description), if (recorded != null) Padding(padding: const EdgeInsets.only(top: 5), child: Text('${recorded.evaluatorName}${recorded.notes.isEmpty ? '' : ' · ${recorded.notes}'}', style: Theme.of(context).textTheme.bodySmall)),
            const SizedBox(height: 8),
            Wrap(spacing: 7, runSpacing: 7, children: [
              for (final choice in const ['PASS', 'FAIL', 'NEEDS_REMEDIATION', 'NOT_APPLICABLE'])
                ChoiceChip(
                  label: Text(choice == 'NEEDS_REMEDIATION' ? 'Remediation' : choice == 'NOT_APPLICABLE' ? 'N/A' : choice == 'PASS' ? 'Pass' : 'Fail'),
                  selected: _draftSkillResults[student.id]?[skill.id] == choice,
                  onSelected: _busy || detail.status == 'COMPLETE' || student.attendance != 'PRESENT'
                    ? null : (_) => _stageSkill(student, skill, choice),
                ),
            ]),
            if (_draftSkillResults[student.id]?.containsKey(skill.id) == true)
              const Text('Selected — not submitted', style: TextStyle(fontWeight: FontWeight.w700)),

          ])); }),
        ]))),
        ],
      ],
    ]));
  }
}
