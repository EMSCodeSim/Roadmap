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

import 'package:firepath/nav.dart';
import 'package:firepath/state/app_mode_controller.dart';
import 'package:firepath/state/department_inbox_controller.dart';

import 'package:firepath/services/responder_roadmap_api.dart';
import 'package:firepath/pages/department/class_task_book_link_card.dart';

const _emsCeCategories = <String>[
  'Airway', 'Cardiology', 'Trauma', 'Medical', 'Operations',
  'Pediatric / Obstetrics', 'Local / State', 'Individual',
];

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

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final rows = await _api.listClasses();
      DepartmentClassSetup? setup;
      try { setup = await _api.getClassSetup(); } catch (_) {}
      if (!mounted) return;
      setState(() { _classes = rows; _setup = setup; _error = null; });
      if (widget.openCreateTraining && setup != null) {
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
                ListTile(leading: const Icon(Icons.note_add_outlined), title: const Text('Blank Training Sheet'), onTap: () => sheetContext.pop<DepartmentTrainingSheetTemplate?>(null)),
                ...templates.where((t) => category.isEmpty || t.trainingCategory == category).map((t) =>
                  ListTile(leading: const Icon(Icons.copy_all_outlined), title: Text(t.name),
                    subtitle: Text(t.defaultTitle.isEmpty ? t.trainingCategory.replaceAll('_', ' ') : t.defaultTitle),
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
      await _load();
      if (!mounted) return;
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
    await Navigator.of(context).push(MaterialPageRoute(builder:(_)=>_TrainingSheetTemplatesPage(api:_api,setup:setup)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Training Sheets'), actions: [if (context.watch<AppModeController>().isAdmin) IconButton(tooltip:'Department setup',onPressed:_configureAgency,icon:const Icon(Icons.tune_rounded)), if (context.watch<AppModeController>().isAdmin && _setup != null) IconButton(tooltip: 'Training Sheet templates', onPressed: _manageTemplates, icon: const Icon(Icons.library_books_outlined)), if ((context.watch<AppModeController>().isInstructor || context.watch<AppModeController>().isAdmin) && _setup != null) IconButton(tooltip: 'Create Training Sheet', onPressed: _createTraining, icon: const Icon(Icons.add_rounded))]),
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
  const _TrainingSheetTemplatesPage({required this.api,required this.setup});
  final ResponderRoadmapApi api; final DepartmentClassSetup setup;
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
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Training Sheet Templates')),floatingActionButton:FloatingActionButton.extended(onPressed:add,icon:const Icon(Icons.add),label:const Text('New Template')),body:rows==null?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(16),children:[
    const Text('Save the setup you reuse. Attendance, skill results and signatures are never part of a template.'),
    if(error!=null)Padding(padding:const EdgeInsets.only(top:10),child:Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error))),
    const SizedBox(height:12),
    if(rows!.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(18),child:Text('No templates yet. Create one for recurring drills, EMS CE, driver training, or company training.'))),
    ...rows!.map((t)=>Card(child:ListTile(leading:const Icon(Icons.description_outlined),title:Text(t.name,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text([t.defaultTitle,t.trainingCategory.replaceAll('_',' '),if(t.creditHours>0)'${t.creditHours} hr'].where((v)=>v.isNotEmpty).join(' · ')),trailing:PopupMenuButton<String>(onSelected:(v){if(v=='archive')archive(t);},itemBuilder:(_)=>const [PopupMenuItem(value:'archive',child:Text('Archive'))])))),
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
  bool busy = false, qr = true, advanced = false; String? error; DateTime startTime = DateTime.now(); String category = 'COMPANY'; String checklist = ''; final Set<String> selectedMembers = <String>{};
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
  Future<void> save() async {
    if(title.text.trim().isEmpty){setState(()=>error='Training title is required.'); return;}
    if(_isEmsCe && location.text.trim().isEmpty){setState(()=>error='Class location is required for EMS CE.'); return;}
    if(!qr && selectedMembers.isEmpty){setState(()=>error='Choose roster members or enable QR sign-in.');return;}
    final h=double.tryParse(hours.text.trim())??0;
    final mode=context.read<AppModeController>();
    final me=widget.setup.proctors.where((p)=>(p['userId']?.toString()??'')==mode.departmentLink?.userId).toList();
    final defaults=widget.template?.proctorUserIds.where((id)=>widget.setup.proctors.any((p)=>p['userId']?.toString()==id)).toList() ?? const <String>[];
    final proctors=defaults.isNotEmpty ? defaults : me.map((p)=>p['userId'].toString()).toList();
    if(proctors.isEmpty){setState(()=>error='Choose an approved proctor before starting this training.'); return;}
    setState((){busy=true;error=null;});
    try {
      final created = await widget.api.createTrainingSheet(title:title.text, startsAt:startTime.toUtc().toIso8601String(), trainingCategory:category, classType:widget.template?.classType ?? 'GENERAL', checklistVersionId:checklist, trainingSheetTemplateId:widget.template?.id ?? '', creditHours:h, location:location.text, notes:notes.text, proctorUserIds:proctors, membershipIds:selectedMembers.toList(), selfRegistration:qr);
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
      const SizedBox(height:12),
      if(_isEmsCe) TextField(controller:location,decoration:const InputDecoration(labelText:'Class location *')),
      if(_isEmsCe) const SizedBox(height:12),
      OutlinedButton.icon(
        onPressed: () async {
          final day = await showDatePicker(context:context,initialDate:startTime,firstDate:DateTime(2020),lastDate:DateTime.now().add(const Duration(days:730)));
          if(day==null || !mounted)return;
          final time = await showTimePicker(context:context,initialTime:TimeOfDay.fromDateTime(startTime));
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
  // Drafts are kept per enrollment so switching roster members does not discard
  // unsent evaluations. Only explicit Submit sends results to the server.
  final Map<String, Map<String, String>> _draftSkillResults = {};
  final Map<String, Map<String, String>> _draftSkillNotes = {};

  @override
  void initState() { super.initState(); _load(); }
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
    final issues = detail.roster.where((m) => _missingFor(detail, m).isNotEmpty).toList();
    final selection = await showModalBottomSheet<DepartmentClassStudent>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(child: FractionallySizedBox(
        heightFactor: 0.75,
        child: Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Review & Finish', style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(issues.isEmpty
                ? 'No member attendance or required-skill gaps detected locally. Server validation is still required.'
                : '${issues.length} member(s) need attention. Tap a member to fix their record.'),
            ],
          )),
          Expanded(child: ListView(children: issues.isEmpty
            ? [const ListTile(leading: Icon(Icons.check_circle_outline),
                title: Text('Member-level checks complete'),
                subtitle: Text('Check server-required fields and proctors before closing.'))]
            : issues.map((member) => ListTile(
                leading: const Icon(Icons.report_problem_outlined),
                title: Text(member.name),
                subtitle: Text(_missingFor(detail, member)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(sheetContext, member),
              )).toList())),
          Padding(padding: const EdgeInsets.all(16), child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(sheetContext),
              icon: const Icon(Icons.fact_check_outlined),
              label: Text(issues.isEmpty ? 'Check server readiness' : 'Back to roster'),
            ),
          )),
        ]),
      )),
    );
    if (!mounted) return;
    if (selection != null) {
      _jumpToMember(selection, grading: selection.attendance == 'PRESENT');
    } else if (issues.isEmpty) {
      // The server remains the authority for required fields, proctors,
      // pending sync, and the actual close decision.
      if (await _editTrainingDocumentation()) await _closeTraining();
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
    final hours = TextEditingController(text:d.creditHours > 0 ? d.creditHours.toString() : '');
    final isEms = d.trainingCategory == 'EMS';
    final ceControllers = <String, TextEditingController>{
      for (final category in _emsCeCategories)
        category: TextEditingController(text: d.ceCredits.where((item) => item['category'] == category).map((item) => item['hours']).firstOrNull?.toString() ?? ''),
    };
    Future<DateTime?> chooseTime(BuildContext dialogContext, DateTime initial) async {
      final day = await showDatePicker(
        context:dialogContext, initialDate:initial,
        firstDate:DateTime(2020), lastDate:DateTime.now().add(const Duration(days:730)),
      );
      if (day == null || !dialogContext.mounted) return null;
      final time = await showTimePicker(context:dialogContext,initialTime:TimeOfDay.fromDateTime(initial));
      if (time == null) return null;
      return DateTime(day.year,day.month,day.day,time.hour,time.minute);
    }
    final result = await showDialog<Map<String, dynamic>>(
      context:context,
      builder:(dialogContext)=>StatefulBuilder(
        builder:(dialogContext,update)=>AlertDialog(
          title:const Text('Finish Training Documentation'),
          content:SizedBox(width:440,child:SingleChildScrollView(child:Column(
            mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
              const Text('Complete times, narrative and department RMS codes after teaching. Saving does not mark the record entered into RMS.'),
              const SizedBox(height:12),
              OutlinedButton.icon(
                onPressed:() async { final chosen=await chooseTime(dialogContext,start); if(chosen!=null)update(()=>start=chosen); },
                icon:const Icon(Icons.schedule),label:Text('Start: $start'),
              ),
              const SizedBox(height:8),
              OutlinedButton.icon(
                onPressed:() async { final chosen=await chooseTime(dialogContext,end??start); if(chosen!=null)update(()=>end=chosen); },
                icon:const Icon(Icons.schedule),label:Text(end==null?'Set actual end time':'End: $end'),
              ),
              const SizedBox(height:8),
              TextField(controller:location,decoration:const InputDecoration(labelText:'Training location')),
              const SizedBox(height:8),
              TextField(controller:hours,keyboardType:const TextInputType.numberWithOptions(decimal:true),
                decoration:const InputDecoration(labelText:'Credit hours (optional if times provided)')),
              const SizedBox(height:8),
              TextField(controller:narrative,maxLines:5,decoration:const InputDecoration(
                labelText:'Class objectives and training narrative',hintText:'Document objectives covered and include RMS codes as needed')),
              if(isEms)...[
                const SizedBox(height:14),
                Text('EMS CE categories',style:Theme.of(dialogContext).textTheme.titleMedium),
                const SizedBox(height:4),const Text('Confirm how earned credit is distributed. Example: 0.5 Medical and 0.5 Airway.'),
                ..._emsCeCategories.map((category)=>Padding(
                  padding:const EdgeInsets.only(top:8),
                  child:TextField(controller:ceControllers[category],keyboardType:const TextInputType.numberWithOptions(decimal:true),
                    onChanged:(_)=>update((){}),decoration:InputDecoration(labelText:'$category hours',hintText:'0')),
                )),
                const SizedBox(height:8),
                Text('Total CE credit: ${ceControllers.values.fold<double>(0,(sum,c)=>sum+(double.tryParse(c.text.trim())??0)).toStringAsFixed(2)} hours',style:const TextStyle(fontWeight:FontWeight.w700)),
              ],
            ],
          ))),
          actions:[
            TextButton(onPressed:()=>Navigator.pop(dialogContext),child:const Text('Cancel')),
            FilledButton(onPressed:()=>Navigator.pop(dialogContext,<String,dynamic>{
              'start':start,'end':end,'notes':narrative.text,'location':location.text,'hours':double.tryParse(hours.text.trim())??0.0,
              'ceCredits':<String,double>{for(final entry in ceControllers.entries) entry.key:double.tryParse(entry.value.text.trim())??0},
            }),child:const Text('Save Documentation')),
          ],
        ),
      ),
    );
    narrative.dispose(); location.dispose(); hours.dispose();
    for(final controller in ceControllers.values){controller.dispose();}
    if (result == null || !mounted) return false;
    final savedStart = result['start'] as DateTime;
    final savedEnd = result['end'] as DateTime?;
    if (savedEnd == null || savedEnd.isBefore(savedStart)) {
      setState(()=>_error='Enter an actual end time after the start time before closing.');
      return false;
    }
    if(isEms && (result['notes'] as String).trim().isEmpty){setState(()=>_error='Enter class objectives and a training narrative before closing EMS CE.');return false;}
    final ceCredits=result['ceCredits'] as Map<String,double>;
    if(isEms && !ceCredits.values.any((hours)=>hours>0)){setState(()=>_error='Assign EMS CE credit to at least one category before closing.');return false;}
    setState(() { _busy=true; _error=null; });
    try {
      _setDetail(await _api.updateTrainingSheetDocumentation(
        d.id, startsAt:savedStart, endsAt:savedEnd,
        notes:result['notes'] as String, location:result['location'] as String,
        creditHours:result['hours'] as double,
        ceCredits:ceCredits,
      ));
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
    final time=await showTimePicker(context:context,initialTime:TimeOfDay.fromDateTime(d.startsAt?.toLocal()??DateTime.now()));
    if(time==null||!mounted)return;
    final when=DateTime(date.year,date.month,date.day,time.hour,time.minute);
    final ok=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(title:const Text('Repeat Training?'),content:Text('Create a new training sheet for ${d.title} on ${when.toLocal()}?\n\nThe setup is copied. Roster, attendance, skill results, signatures, completion status and old timestamps are not copied.'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Create Repeat'))]))??false;
    if(!ok)return;
    setState(()=>_busy=true);
    try{
      final created=await _api.createTrainingSheet(title:d.title,startsAt:when.toUtc().toIso8601String(),trainingCategory:d.trainingCategory,checklistVersionId:d.checklistVersionId,creditHours:d.creditHours,location:d.location,notes:d.notes,proctorUserIds:d.proctorUserIds,selfRegistration:false);
      if(!mounted)return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder:(_)=>DepartmentClassDetailPage(classId:created.id)));
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
          const SizedBox(height:8),TextField(controller:email,onChanged:(_)=>update((){}),keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'Email *')),
          const SizedBox(height:8),TextField(controller:organization,decoration:const InputDecoration(labelText:'Organization (optional)')),
        ]))),
        actions:[TextButton(onPressed:()=>Navigator.pop(dialogContext),child:const Text('Cancel')),
          if(selected.isNotEmpty) FilledButton(onPressed:()=>Navigator.pop(dialogContext,'roster'),child:Text('Add ${selected.length} selected')),
          if(name.text.trim().isNotEmpty&&email.text.trim().isNotEmpty) FilledButton(onPressed:()=>Navigator.pop(dialogContext,'manual'),child:const Text('Add manual student'))],
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

  Widget _closeoutLine(BuildContext context, String label, bool complete, String detail) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Icon(complete ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
        size: 20, color: complete ? Colors.green : Theme.of(context).colorScheme.outline),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
      Flexible(child: Text(detail, textAlign: TextAlign.end, style: Theme.of(context).textTheme.bodySmall)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final detail = _detail; final student = _student;
    final mode = context.watch<AppModeController>();
    final canRecordRmsEntry = mode.isAdmin;
    return Scaffold(appBar: AppBar(title: Text(detail?.title ?? 'Class roster')), body: detail == null ? Center(child: _error == null ? const CircularProgressIndicator() : Text(_error!)) : ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 28), children: [
      Text(detail.checklistTitle, style: Theme.of(context).textTheme.bodyMedium), const SizedBox(height: 10),
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

      if (detail.status != 'COMPLETE')
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Next step', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                detail.roster.isEmpty
                    ? 'Add students to begin this Training Sheet.'
                    : detail.roster.any((member) => member.attendance == 'REGISTERED')
                        ? 'Record attendance for every student.'
                        : detail.roster.any((member) => member.attendance == 'PRESENT' && !_studentComplete(detail, member))
                            ? 'Grade required skills for present students.'
                            : 'Review the completed roster and close training.',
              ),
              const SizedBox(height: 10),
              if (detail.roster.isEmpty)
                Wrap(spacing:8,runSpacing:8,children:[
                  FilledButton.icon(onPressed:_busy?null:_showQr,icon:const Icon(Icons.qr_code_2_rounded),label:const Text('Show QR')),
                  OutlinedButton.icon(onPressed:_busy?null:_addStudents,icon:const Icon(Icons.person_add_alt_1_outlined),label:const Text('Add students')),
                ])
              else if (detail.roster.any((member) => member.attendance == 'REGISTERED'))
                OutlinedButton.icon(
                  onPressed: _busy ? null : _load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh Roster'),
                )
              else if (detail.roster.any((member) => member.attendance == 'PRESENT' && !_studentComplete(detail, member)))
                FilledButton.icon(
                  onPressed: _busy ? null : _groupGrade,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Grade Skills'),
                )
              else
                FilledButton.icon(
                  onPressed: _busy ? null : () { _reviewAndFinish(); },
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('Review & Finish'),
                ),
            ]),
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
          const SizedBox(height: 14),
          Text('Instructor Closeout', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _closeoutLine(context, 'Roster', detail.roster.isNotEmpty, '${detail.roster.length} registered'),
          _closeoutLine(context, 'Attendance verified', detail.roster.isNotEmpty && detail.roster.every((member) => member.attendance != 'REGISTERED'), '${detail.roster.where((member) => member.attendance != 'REGISTERED').length}/${detail.roster.length} recorded'),
          _closeoutLine(context, 'Required skill results', detail.roster.isNotEmpty && detail.roster.every((member) => member.attendance != 'REGISTERED') && detail.roster.where((member) => member.attendance == 'PRESENT').every((member) => _studentComplete(detail, member)), '${detail.roster.where((member) => _studentComplete(detail, member)).length} ready'),
          _closeoutLine(context, 'Training closed', detail.status == 'COMPLETE', 'Review & Close'),
          _closeoutLine(context, 'Instructor approval', detail.instructorApprovedAt != null, 'Required before RMS entry'),
          _closeoutLine(context, 'Department RMS entry', detail.rmsStatus == 'RMS_ENTERED', 'Separate official record step'),
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
              OutlinedButton.icon(onPressed: _busy || detail.roster.isEmpty ? null : () { _reviewAndFinish(); }, icon: const Icon(Icons.rate_review_outlined), label: const Text('Review & Finish')),
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
      Row(children: [
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
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
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
