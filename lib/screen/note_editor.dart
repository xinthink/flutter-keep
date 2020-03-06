import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:flt_keep/icons.dart';
import 'package:flt_keep/models.dart' show CurrentUser, Note, NoteState, NoteStateX;
import 'package:flt_keep/services.dart';
import 'package:flt_keep/styles.dart';
import 'package:flt_keep/widgets.dart';

/// The editor of a [Note], also shows every detail about a single note.
class NoteEditor extends StatefulWidget {
  /// Create a [NoteEditor],
  /// provides an existed [note] in edit mode, or `null` to create a new one.
  const NoteEditor({Key key, this.note}) : super(key: key);

  final Note note;

  @override
  State<StatefulWidget> createState() => _NoteEditorState(note);
}

/// [State] of [NoteEditor].
class _NoteEditorState extends State<NoteEditor> with CommandHandler {
  /// Create a state for [NoteEditor], with an optional [note] being edited,
  /// otherwise a new one will be created.
  _NoteEditorState(Note note)
    : this._note = note ?? Note(),
    _originNote = note?.copy() ?? Note(),
    this._titleTextController = TextEditingController(text: note?.title),
    this._contentTextController = TextEditingController(text: note?.content);

  /// The note in editing
  final Note _note;
  /// The origin copy before editing
  final Note _originNote;
  Color get _noteColor => _note.color ?? kDefaultNoteColor;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription<Note> _noteSubscription;
  final TextEditingController _titleTextController;
  final TextEditingController _contentTextController;

  /// If the note is modified.
  bool get _isDirty => _note != _originNote;

  @override
  void initState() {
    super.initState();
    _titleTextController.addListener(() => _note.title = _titleTextController.text);
    _contentTextController.addListener(() => _note.content = _contentTextController.text);
  }

  @override
  void dispose() {
    _noteSubscription?.cancel();
    _titleTextController.dispose();
    _contentTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<CurrentUser>(context).data.uid;
    _watchNoteDocument(uid);
    return ChangeNotifierProvider.value(
      value: _note,
      child: Consumer<Note>(
        builder: (_, __, ___) => Hero(
          tag: 'NoteItem${_note.id}',
          child: Theme(
            data: Theme.of(context).copyWith(
              primaryColor: _noteColor,
              appBarTheme: Theme.of(context).appBarTheme.copyWith(
                elevation: 0,
              ),
              scaffoldBackgroundColor: _noteColor,
              bottomAppBarColor: _noteColor,
            ),
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: _noteColor,
                systemNavigationBarColor: _noteColor,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
              child: Scaffold(
                key: _scaffoldKey,
                appBar: AppBar(
                  actions: _buildTopActions(context, uid),
                  bottom: const PreferredSize(
                    preferredSize: Size(0, 24),
                    child: SizedBox(),
                  ),
                ),
                body: _buildBody(context, uid),
                bottomNavigationBar: _buildBottomAppBar(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, String uid) => DefaultTextStyle(
    style: kNoteTextLargeLight,
    child: WillPopScope(
      onWillPop: () => _onPop(uid),
      child: Container(
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SingleChildScrollView(
          child: _buildNoteDetail(),
        ),
      ),
    ),
  );

  Widget _buildNoteDetail() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      TextField(
        controller: _titleTextController,
        style: kNoteTitleLight,
        decoration: const InputDecoration(
          hintText: 'Title',
          border: InputBorder.none,
          counter: const SizedBox(),
        ),
        maxLines: null,
        maxLength: 1024,
        textCapitalization: TextCapitalization.sentences,
        readOnly: !_note.state.canEdit,
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _contentTextController,
        style: kNoteTextLargeLight,
        decoration: const InputDecoration.collapsed(hintText: 'Note'),
        maxLines: null,
        textCapitalization: TextCapitalization.sentences,
        readOnly: !_note.state.canEdit,
      ),
    ],
  );

  List<Widget> _buildTopActions(BuildContext context, String uid) => [
    if (_note.state != NoteState.deleted) IconButton(
        icon: Icon(_note.pinned == true ? AppIcons.pin : AppIcons.pin_outlined),
        tooltip: _note.pinned == true ? 'Unpin' : 'Pin',
        onPressed: () => _updateNoteState(uid, _note.pinned ? NoteState.unspecified : NoteState.pinned),
    ),
    if (_note.id != null && _note.state < NoteState.archived) IconButton(
      icon: const Icon(AppIcons.archive_outlined),
      tooltip: 'Archive',
      onPressed: () => Navigator.pop(context, NoteStateUpdateCommand(
        id: _note.id,
        uid: uid,
        from: _note.state,
        to: NoteState.archived,
      )),
    ),
    if (_note.state == NoteState.archived) IconButton(
      icon: const Icon(AppIcons.unarchive_outlined),
      tooltip: 'Unarchive',
      onPressed: () => _updateNoteState(uid, NoteState.unspecified),
    ),
  ];

  Widget _buildBottomAppBar(BuildContext context) => BottomAppBar(
    child: Container(
      height: kBottomBarSize,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
              icon: const Icon(AppIcons.add_box),
              color: kIconTintLight,
              onPressed: _note.state.canEdit ? () {} : null,
          ),
          Text('Edited ${_note.strLastModified}'),
          IconButton(
            icon: const Icon(Icons.more_vert),
            color: kIconTintLight,
            onPressed: () => _showNoteBottomSheet(context),
          ),
        ],
      ),
    ),
  );

  void _showNoteBottomSheet(BuildContext context) async {
    final command = await showModalBottomSheet<NoteCommand>(
      context: context,
      backgroundColor: _noteColor,
      builder: (context) => ChangeNotifierProvider.value(
        value: _note,
        child: Consumer<Note>(
          builder: (_, note, __) => Container(
            color: note.color ?? kDefaultNoteColor,
            padding: const EdgeInsets.symmetric(vertical: 19),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                NoteActions(),
                if (_note.state.canEdit) const SizedBox(height: 16),
                if (_note.state.canEdit) LinearColorPicker(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );

    if (command != null) {
      if (command.dismiss) {
        Navigator.pop(context, command);
      } else {
        processNoteCommand(_scaffoldKey.currentState, command);
      }
    }
  }

  /// Callback before the user leave the editor.
  Future<bool> _onPop(String uid) {
    if (_isDirty && (_note.id != null || _note.isNotEmpty)) {
      _note
        ..modifiedAt = DateTime.now()
        ..saveToFireStore(uid);
    }
    return Future.value(true);
  }

  void _watchNoteDocument(String uid) {
    if (_noteSubscription == null && uid != null && _note.id != null) {
      _noteSubscription = noteDocument(_note.id, uid).snapshots()
        .map((snapshot) => snapshot.exists ? snapshot.toNote() : null)
        .listen(_onCloudNoteUpdated);
    }
  }

  /// Callback when the FireStore copy of this note updated.
  void _onCloudNoteUpdated(Note note) {
    if (!mounted || note?.isNotEmpty != true || _note == note) {
      return;
    }

    final refresh = () {
      _titleTextController.text = _note.title ?? '';
      _contentTextController.text = _note.content ?? '';
      _originNote.update(note, updateTimestamp: false);
      _note.update(note, updateTimestamp: false);
    };

    if (_isDirty) {
      _scaffoldKey.currentState?.showSnackBar(SnackBar(
        content: const Text('The note is updated on cloud.'),
        action: SnackBarAction(
          label: 'Refresh',
          onPressed: refresh,
        ),
        duration: const Duration(days: 1),
      ));
    } else {
      refresh();
    }
  }

  /// Update this note to the given [state]
  void _updateNoteState(uid, NoteState state) {
    // new note, update locally
    if (_note.id == null) {
      _note.updateWith(state: state);
      return;
    }

    // otherwise, handles it in a undoable manner
    processNoteCommand(_scaffoldKey.currentState, NoteStateUpdateCommand(
      id: _note.id,
      uid: uid,
      from: _note.state,
      to: state,
    ));
  }
}
