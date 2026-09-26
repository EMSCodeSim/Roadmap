import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:firepath/state/app_mode_controller.dart';
import 'package:firepath/state/department_inbox_controller.dart';

import 'package:firepath/services/responder_roadmap_api.dart';

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
      selected = await showModalBottomSheet<DepartmentTrainingSheetTemplate?>(
        context: context, useSafeArea: true,
        builder: (context) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Create Training Sheet', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: ()=>Navigator.pop(context), icon: const Icon(Icons.note_add_outlined), label: const Text('Blank Training Sheet')),
            if (templates.isNotEmpty) ...[
              const SizedBox(height: 16), const Text('From Template', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              ...templates.take(8).map((t)=>ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.copy_all_outlined), title: Text(t.name), subtitle: Text(t.defaultTitle.isEmpty ? t.trainingCategory.replaceAll('_',' ') : t.defaultTitle), onTap: ()=>Navigator.pop(context,t))),
            ],
          ]),
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
        final blank = await showDialog<bool>(context: context, builder: (context)=>AlertDialog(title:const Text('Blank Training Sheet?'),content:const Text('Start without a saved template?'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Start Blank'))]));
        if(blank!=true)return;
      }
    }
    final created = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => _CreateTrainingSheet(api: _api, setup: setup, template: selected));
    if (created == true && mounted) await _load();
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
              ListTile(title:Text(item.$2),trailing:current.agencyType==item.$1?const Icon(Icons.check_circle):const Icon(Icons.chevron_right),onTap:()=>Navigator.pop(context,item.$1)),
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
    appBar: AppBar(title: const Text('My Classes'), actions: [if (context.watch<AppModeController>().isAdmin) IconButton(tooltip:'Department setup',onPressed:_configureAgency,icon:const Icon(Icons.tune_rounded)), if (context.watch<AppModeController>().isAdmin && _setup != null) IconButton(tooltip: 'Training Sheet templates', onPressed: _manageTemplates, icon: const Icon(Icons.library_books_outlined)), if ((context.watch<AppModeController>().isInstructor || context.watch<AppModeController>().isAdmin) && _setup != null) IconButton(tooltip: 'Create training', onPressed: _createTraining, icon: const Icon(Icons.add_rounded))]),
    body: _classes == null ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Text('My Classes', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6), Text((context.watch<AppModeController>().isInstructor || context.watch<AppModeController>().isAdmin) ? 'Create training sheets or open a class to manage its roster and document skill results.' : 'Assigned class rosters and skill checklists.'),
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
        const SizedBox(height:10),DropdownButtonFormField<String>(value:category,decoration:const InputDecoration(labelText:'Category'),items:const ['COMPANY','EMS','FIRE','DRIVER_OPERATOR','HAZMAT','TECHNICAL_RESCUE','WILDLAND','OTHER'].map((v)=>DropdownMenuItem(value:v,child:Text(v.replaceAll('_',' ')))).toList(),onChanged:(v)=>setLocal(()=>category=v??'COMPANY')),
        const SizedBox(height:10),DropdownButtonFormField<String>(value:checklist,decoration:const InputDecoration(labelText:'Checklist'),items:[const DropdownMenuItem(value:'',child:Text('Attendance only')),...widget.setup.checklists.map((v)=>DropdownMenuItem(value:v['id']?.toString()??'',child:Text(v['title']?.toString()??'Checklist')))],onChanged:(v)=>setLocal(()=>checklist=v??'')),
        const SizedBox(height:10),TextField(controller:hours,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Default hours')),
        const SizedBox(height:10),TextField(controller:location,decoration:const InputDecoration(labelText:'Default location')),
        const SizedBox(height:10),TextField(controller:notes,maxLines:3,decoration:const InputDecoration(labelText:'Default notes')),
        SwitchListTile(contentPadding:EdgeInsets.zero,value:qr,onChanged:(v)=>setLocal(()=>qr=v),title:const Text('QR self-registration')),
      ]),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Save Template'))])));
    if(ok!=true||name.text.trim().isEmpty)return;
    try{await widget.api.createTrainingSheetTemplate(name:name.text,defaultTitle:title.text,trainingCategory:category,creditHours:double.tryParse(hours.text)??0,checklistVersionId:checklist,location:location.text,notes:notes.text,requiredFields:widget.setup.requiredFields,selfRegistration:qr);await load();}catch(e){if(mounted)setState(()=>error=e.toString());}
  }
  Future<void> archive(DepartmentTrainingSheetTemplate t)async{final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Archive template?'),content:Text('Archive "${t.name}"? Existing training records are not affected.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Archive'))]))??false;if(!ok)return;try{await widget.api.archiveTrainingSheetTemplate(t.id);await load();}catch(e){if(mounted)setState(()=>error=e.toString());}}
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
  bool busy = false, qr = true; String? error; String category = 'COMPANY'; String checklist = '';
  @override void initState() {
    super.initState();
    final t=widget.template;
    if(t!=null){
      title.text=t.defaultTitle; location.text=t.location; notes.text=t.notes;
      hours.text=t.creditHours > 0 ? t.creditHours.toString() : '';
      category=t.trainingCategory; checklist=t.checklistVersionId; qr=t.selfRegistration;
    }
  }
  @override void dispose(){ title.dispose(); location.dispose(); notes.dispose(); hours.dispose(); super.dispose(); }
  bool req(String key) => widget.setup.requiredFields.contains(key);
  Future<void> save() async {
    if(title.text.trim().isEmpty){setState(()=>error='Training title is required.'); return;}
    if(req('LOCATION') && location.text.trim().isEmpty){setState(()=>error='Location is required by your department.'); return;}
    if(req('DESCRIPTION') && notes.text.trim().isEmpty){setState(()=>error='Description / notes are required by your department.'); return;}
    final h=double.tryParse(hours.text.trim())??0;
    if(req('HOURS') && h<=0){setState(()=>error='Training hours are required by your department.'); return;}
    final mode=context.read<AppModeController>();
    final me=widget.setup.proctors.where((p)=>(p['userId']?.toString()??'')==mode.departmentLink?.userId).toList();
    final defaults=widget.template?.proctorUserIds.where((id)=>widget.setup.proctors.any((p)=>p['userId']?.toString()==id)).toList() ?? const <String>[];
    final proctors=defaults.isNotEmpty ? defaults : me.map((p)=>p['userId'].toString()).toList();
    if(proctors.isEmpty){setState(()=>error='Choose an approved proctor before starting this training.'); return;}
    setState((){busy=true;error=null;});
    try {
      await widget.api.createTrainingSheet(title:title.text, startsAt:DateTime.now().toUtc().toIso8601String(), trainingCategory:category, checklistVersionId:checklist, creditHours:h, location:location.text, notes:notes.text, proctorUserIds:proctors, selfRegistration:qr);
      if(mounted) Navigator.pop(context,true);
    } catch(e){if(mounted)setState(()=>error=e.toString());}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>Padding(
    padding: EdgeInsets.fromLTRB(20,16,20,MediaQuery.viewInsetsOf(context).bottom+24),
    child: SingleChildScrollView(child: Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Text(widget.template==null?'Blank Training Sheet':'From Template · ${widget.template!.name}',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900)),
      const SizedBox(height:6), const Text('Field entry uses your department’s RMS requirements. QR sign-in is on by default.'),
      if(error!=null)...[const SizedBox(height:10),Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error))],
      const SizedBox(height:16),TextField(controller:title,decoration:const InputDecoration(labelText:'Training title *')),
      const SizedBox(height:12),DropdownButtonFormField<String>(value:category,decoration:const InputDecoration(labelText:'Training category'),items:const ['COMPANY','EMS','FIRE','DRIVER_OPERATOR','HAZMAT','TECHNICAL_RESCUE','WILDLAND','OTHER'].map((v)=>DropdownMenuItem(value:v,child:Text(v.replaceAll('_',' ')))).toList(),onChanged:(v)=>setState(()=>category=v??'COMPANY')),
      const SizedBox(height:12),DropdownButtonFormField<String>(value:checklist,decoration:const InputDecoration(labelText:'Skills checklist (optional)'),items:[const DropdownMenuItem(value:'',child:Text('Attendance only')),...widget.setup.checklists.map((v)=>DropdownMenuItem(value:v['id']?.toString()??'',child:Text(v['title']?.toString()??'Checklist')))],onChanged:(v)=>setState(()=>checklist=v??'')),
      const SizedBox(height:12),TextField(controller:location,decoration:InputDecoration(labelText:'Location${req('LOCATION')?' *':''}')),
      const SizedBox(height:12),TextField(controller:hours,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:'Training hours${req('HOURS')?' *':''}')),
      const SizedBox(height:12),TextField(controller:notes,maxLines:3,decoration:InputDecoration(labelText:'Description / notes${req('DESCRIPTION')?' *':''}')),
      const SizedBox(height:8),SwitchListTile(contentPadding:EdgeInsets.zero,value:qr,onChanged:(v)=>setState(()=>qr=v),title:const Text('Allow QR self-registration'),subtitle:const Text('Crew can scan in from their phones.')),
      const SizedBox(height:14),FilledButton.icon(onPressed:busy?null:save,icon:busy?const SizedBox.square(dimension:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.play_arrow_rounded),label:const Text('Start Training')),
    ])),
  );
}

class DepartmentClassDetailPage extends StatefulWidget {
  final String classId;
  const DepartmentClassDetailPage({super.key, required this.classId});
  @override
  State<DepartmentClassDetailPage> createState() => _DepartmentClassDetailPageState();
}

class _DepartmentClassDetailPageState extends State<DepartmentClassDetailPage> {
  final _api = ResponderRoadmapApi();
  DepartmentClassDetail? _detail;
  String? _studentId;
  String? _error;
  bool _busy = false;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { try { _setDetail(await _api.getClass(widget.classId)); } catch (e) { if (mounted) setState(() => _error = e.toString()); } }
  void _setDetail(DepartmentClassDetail detail) { if (!mounted) return; setState(() { _detail = detail; _studentId = detail.roster.any((item) => item.id == _studentId) ? _studentId : (detail.roster.isEmpty ? null : detail.roster.first.id); _error = null; }); }
  DepartmentClassStudent? get _student { for (final item in _detail?.roster ?? const <DepartmentClassStudent>[]) { if (item.id == _studentId) return item; } return null; }
  String get _registrationUrl => _detail?.registrationToken.isNotEmpty == true ? 'https://responderroadmap.com/class-join/${_detail!.registrationToken}' : '';

  Future<void> _registration(String action) async {
    if (_detail == null || _busy) return; setState(()=>_busy=true);
    try { _setDetail(await _api.manageClassRegistration(classId: widget.classId, action: action)); }
    catch(e){if(mounted)setState(()=>_error=e.toString());}
    finally{if(mounted)setState(()=>_busy=false);}
  }

  Future<void> _closeTraining() async {
    final d=_detail; if(d==null||_busy)return;
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

  Future<void> _showQr() async {
    final d=_detail; if(d==null)return;
    if(!d.registrationEnabled || d.registrationToken.isEmpty) await _registration('OPEN');
    if(!mounted||_registrationUrl.isEmpty)return;
    await showDialog<void>(context:context,builder:(context)=>AlertDialog(title:const Text('Crew QR Sign-in'),content:Column(mainAxisSize:MainAxisSize.min,children:[QrImageView(data:_registrationUrl,size:240),const SizedBox(height:12),const Text('Have attendees scan this code to join the live roster.',textAlign:TextAlign.center)]),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Done'))]));
    await _load();
  }


  Future<String?> _correctionNotes(String title) async {
    final controller = TextEditingController();
    return showDialog<String>(context: context, builder: (context) => AlertDialog(title: Text(title), content: TextField(controller: controller, maxLines: 4, autofocus: true, decoration: const InputDecoration(labelText: 'What must the student correct?')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { if (controller.text.trim().isNotEmpty) Navigator.pop(context, controller.text.trim()); }, child: const Text('Save result'))]));
  }

  Future<void> _record(DepartmentClassSkill skill, String result) async {
    final student = _student; if (student == null || _detail == null) return;
    var notes = ''; if (result == 'FAIL' || result == 'NEEDS_REMEDIATION') { final entered = await _correctionNotes(result == 'FAIL' ? 'Record failed skill' : 'Remediation required'); if (entered == null) return; notes = entered; }
    setState(() => _busy = true);
    try { final saved=await _api.recordClassSkillDurable(classId: widget.classId, enrollmentId: student.id, requirementId: skill.id, result: result, notes: notes); if(saved.detail!=null)_setDetail(saved.detail!); if(saved.queued&&mounted){context.read<DepartmentInboxController>().submissionQueued();ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Waiting to Sync — skill result saved safely on this device.')));} } catch (e) { if (mounted) setState(() => _error = e.toString()); } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail; final student = _student;
    return Scaffold(appBar: AppBar(title: Text(detail?.title ?? 'Class roster')), body: detail == null ? Center(child: _error == null ? const CircularProgressIndicator() : Text(_error!)) : ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 28), children: [
      Text(detail.checklistTitle, style: Theme.of(context).textTheme.bodyMedium), const SizedBox(height: 10),
      Consumer<DepartmentInboxController>(builder:(context,sync,_) {
        final waiting=sync.syncState==DepartmentSyncState.waitingToUpload;
        final failed=sync.syncState==DepartmentSyncState.failed;
        if(!waiting&&!failed)return const SizedBox.shrink();
        return Card(child:Padding(padding:const EdgeInsets.all(12),child:Row(children:[
          Icon(waiting?Icons.cloud_upload_outlined:Icons.cloud_off_outlined),
          const SizedBox(width:10),
          Expanded(child:Text(waiting?'Waiting to Sync — field changes are saved on this device and will retry automatically.':'Sync Failed — your saved field changes are still on this device.')),
          TextButton(onPressed:()=>sync.refresh(),child:const Text('Retry')),
        ])));
      }),

      if (detail.status != 'COMPLETE') Wrap(spacing: 8, runSpacing: 8, children: [FilledButton.icon(onPressed: _busy ? null : _showQr, icon: const Icon(Icons.qr_code_2_rounded), label: Text(detail.registrationEnabled ? 'Show QR' : 'Open QR Sign-in')), OutlinedButton.icon(onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh_rounded), label: Text('Refresh Roster')), OutlinedButton.icon(onPressed: _busy ? null : _closeTraining, icon: const Icon(Icons.check_circle_outline_rounded), label: const Text('Close Training'))]),
      if (detail.status == 'COMPLETE') ...[const Card(child: Padding(padding:EdgeInsets.all(14),child:Row(children:[Icon(Icons.verified_rounded),SizedBox(width:10),Expanded(child:Text('Training closed — official digital training sheet finalized.'))]))), const SizedBox(height:8), Wrap(spacing:8,runSpacing:8,children:[OutlinedButton.icon(onPressed:_busy?null:_repeatTraining,icon:const Icon(Icons.replay_rounded),label:const Text('Repeat Training')),OutlinedButton.icon(onPressed:_busy?null:_exportCsv,icon:const Icon(Icons.table_view_outlined),label:const Text('Export CSV for RMS')),OutlinedButton.icon(onPressed:_busy?null:()=>Share.share('Open the canonical training record at https://responderroadmap.com/classes/${detail.id} to print/save as PDF.',subject:'${detail.title} training record'),icon:const Icon(Icons.picture_as_pdf_outlined),label:const Text('PDF / Print Record'))])],
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: _studentId, decoration: const InputDecoration(labelText: 'Student'), items: detail.roster.map((item) => DropdownMenuItem(value: item.id, child: Text('${item.name} · ${item.finalResult.replaceAll('_', ' ')}'))).toList(), onChanged: (value) => setState(() => _studentId = value)),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
      if (student != null) ...[
        const SizedBox(height: 12), DropdownButtonFormField<String>(value: student.attendance, decoration: const InputDecoration(labelText: 'Attendance'), items: const ['REGISTERED', 'PRESENT', 'ABSENT', 'EXCUSED'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(), onChanged: _busy || detail.status == 'COMPLETE' ? null : (value) async { if (value == null) return; setState(() => _busy = true); try { final saved=await _api.updateClassStudentDurable(classId:detail.id,enrollmentId:student.id,attendance:value); if(saved.detail!=null)_setDetail(saved.detail!); if(saved.queued&&mounted){context.read<DepartmentInboxController>().submissionQueued();ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Waiting to Sync — attendance saved safely on this device.')));} } finally { if (mounted) setState(() => _busy = false); } }),
        const SizedBox(height: 18),
        ...detail.sections.map((section) => Card(margin: const EdgeInsets.only(bottom: 14), clipBehavior: Clip.antiAlias, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: double.infinity, padding: const EdgeInsets.all(14), color: Theme.of(context).colorScheme.surfaceContainerHighest, child: Text(section.title, style: const TextStyle(fontWeight: FontWeight.w900))),
          ...section.skills.map((skill) { DepartmentClassSkillResult? recorded; for (final item in student.results) { if (item.requirementId == skill.id) recorded = item; } return Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(skill.title, style: const TextStyle(fontWeight: FontWeight.w800))), Chip(label: Text((recorded?.result ?? 'NOT_EVALUATED').replaceAll('_', ' ')))]),
            if (skill.description.isNotEmpty) Text(skill.description), if (recorded != null) Padding(padding: const EdgeInsets.only(top: 5), child: Text('${recorded.evaluatorName}${recorded.notes.isEmpty ? '' : ' · ${recorded.notes}'}', style: Theme.of(context).textTheme.bodySmall)),
            const SizedBox(height: 8), Wrap(spacing: 7, runSpacing: 7, children: [FilledButton(onPressed: _busy || detail.status == 'COMPLETE' ? null : () => _record(skill, 'PASS'), child: const Text('Pass')), OutlinedButton(onPressed: _busy || detail.status == 'COMPLETE' ? null : () => _record(skill, 'NEEDS_REMEDIATION'), child: const Text('Remediation')), OutlinedButton(onPressed: _busy || detail.status == 'COMPLETE' ? null : () => _record(skill, 'FAIL'), child: const Text('Fail')), TextButton(onPressed: _busy || detail.status == 'COMPLETE' ? null : () => _record(skill, 'NOT_APPLICABLE'), child: const Text('N/A'))]),
          ])); }),
        ]))),
      ],
    ]));
  }
}
