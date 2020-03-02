import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import 'package:flt_keep/icons.dart' show AppIcons;
import 'package:flt_keep/models.dart' show CurrentUser, Note, NoteState, NoteStateX, NoteFilter;
import 'package:flt_keep/services.dart' show notesCollection, CommandHandler;
import 'package:flt_keep/styles.dart';
import 'package:flt_keep/utils.dart';
import 'package:flt_keep/widgets.dart' show AppDrawer, NotesGrid, NotesList;

/// Home screen, displays [Note] grid or list.
class HomeScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

/// [State] of [HomeScreen].
class _HomeScreenState extends State<HomeScreen> with CommandHandler {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /// `true` to show notes in a GridView, a ListView otherwise.
  bool _gridView = true;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
//      statusBarColor: Colors.white,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => NoteFilter(), // watching the note filter
        ),
        Consumer<NoteFilter>(
          builder: (context, filter, child) => StreamProvider.value(
            value: _createNoteStream(context, filter), // applying the filter to Firestore query
            child: child,
          ),
        ),
      ],
      child: Consumer2<NoteFilter, List<Note>>(
        builder: (context, filter, notes, child) {
          final hasNotes = notes?.isNotEmpty == true;
          final canCreate = filter.noteState.canCreate;
          return Scaffold(
            key: _scaffoldKey,
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints.tightFor(width: 720),
                child: CustomScrollView(
                  slivers: <Widget>[
                    _appBar(context, filter, child),
                    if (hasNotes) const SliverToBoxAdapter(
                      child: SizedBox(height: 24),
                    ),
                    ..._buildNotesView(context, filter, notes),
                    if (hasNotes) SliverToBoxAdapter(
                      child: SizedBox(height: (canCreate ? kBottomBarSize : 10.0) + 10.0),
                    ),
                  ],
                ),
              ),
            ),
            drawer: AppDrawer(),
            floatingActionButton: canCreate ? _fab(context) : null,
            bottomNavigationBar: canCreate ? _bottomActions() : null,
            floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
            extendBody: true,
          );
        },
      ),
    ),
  );

  Widget _appBar(BuildContext context, NoteFilter filter, Widget bottom) =>
    filter.noteState < NoteState.archived
      ? SliverAppBar(
        floating: true,
        snap: true,
        title: _topActions(context),
        automaticallyImplyLeading: false,
        centerTitle: true,
        titleSpacing: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
      )
      : SliverAppBar(
        floating: true,
        snap: true,
        title: Text(filter.noteState.filterName),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Menu',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        automaticallyImplyLeading: false,
      );

  Widget _topActions(BuildContext context) => Container(
    // width: double.infinity,
    constraints: const BoxConstraints(
      maxWidth: 720,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isNotAndroid ? 7 : 5),
        child: Row(
          children: <Widget>[
            const SizedBox(width: 20),
            InkWell(
              child: const Icon(Icons.menu),
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text('Search your notes',
                softWrap: false,
                style: TextStyle(
                  color: kHintTextColorLight,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            InkWell(
              child: Icon(_gridView ? AppIcons.view_list : AppIcons.view_grid),
              onTap: () => setState(() {
                _gridView = !_gridView;
              }),
            ),
            const SizedBox(width: 18),
            _buildAvatar(context),
            const SizedBox(width: 10),
          ],
        ),
      ),
    ),
  );

  Widget _bottomActions() => BottomAppBar(
    shape: const CircularNotchedRectangle(),
    child: Container(
      height: kBottomBarSize,
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: Row(
        children: <Widget>[
          const Icon(AppIcons.checkbox, size: 26, color: kIconTintLight),
          const SizedBox(width: 30),
          const Icon(AppIcons.brush_sharp, size: 26, color: kIconTintLight),
          const SizedBox(width: 30),
          const Icon(AppIcons.mic, size: 26, color: kIconTintLight),
          const SizedBox(width: 30),
          const Icon(AppIcons.insert_photo, size: 26, color: kIconTintLight),
        ],
      ),
    ),
  );

  Widget _fab(BuildContext context) => FloatingActionButton(
    backgroundColor: Theme.of(context).accentColor,
    child: const Icon(Icons.add),
    onPressed: () async {
      final command = await Navigator.pushNamed(context, '/note');
      debugPrint('--- noteEditor result: $command');
      processNoteCommand(_scaffoldKey.currentState, command);
    },
  );

  Widget _buildAvatar(BuildContext context) {
    final url = Provider.of<CurrentUser>(context)?.data?.photoUrl;
    return CircleAvatar(
      backgroundImage: url != null ? NetworkImage(url) : null,
      child: url == null ? const Icon(Icons.face) : null,
      radius: isNotAndroid ? 19 : 17,
    );
  }

  /// A grid/list view to display notes
  ///
  /// Notes are divided to `Pinned` and `Others` when there's no filter,
  /// and a blank view will be rendered, if no note found.
  List<Widget> _buildNotesView(BuildContext context, NoteFilter filter, List<Note> notes) {
    if (notes?.isNotEmpty != true) {
      return [_buildBlankView(filter.noteState)];
    }

    final asGrid = filter.noteState == NoteState.deleted || _gridView;
    final factory = asGrid ? NotesGrid.create : NotesList.create;
    final showPinned = filter.noteState == NoteState.unspecified;

    if (!showPinned) {
      return [
        factory(notes: notes, onTap: _onNoteTap),
      ];
    }

    final partition = _partitionNotes(notes);
    final hasPinned = partition.item1.isNotEmpty;
    final hasUnpinned = partition.item2.isNotEmpty;

    final _buildLabel = (String label, [double top = 26]) => SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsetsDirectional.only(start: 26, bottom: 25, top: top),
        child: Text(label, style: const TextStyle(
          color: kHintTextColorLight,
          fontWeight: FontWeights.medium,
          fontSize: 12),
        ),
      ),
    );

    return [
      if (hasPinned) _buildLabel('PINNED', 0),
      if (hasPinned) factory(notes: partition.item1, onTap: _onNoteTap),
      if (hasPinned && hasUnpinned) _buildLabel('OTHERS'),
      factory(notes: partition.item2, onTap: _onNoteTap),
    ];
  }

  Widget _buildBlankView(NoteState filteredState) => SliverFillRemaining(
    hasScrollBody: false,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Expanded(flex: 1, child: SizedBox()),
        Icon(AppIcons.thumbtack,
          size: 120,
          color: kAccentColorLight.shade300,
        ),
        Expanded(
          flex: 2,
          child: Text(filteredState.emptyResultMessage,
            style: TextStyle(
              color: kHintTextColorLight,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
  );

  /// Callback on a single note clicked
  void _onNoteTap(Note note) async {
    final command = await Navigator.pushNamed(context, '/note', arguments: { 'note': note });
    processNoteCommand(_scaffoldKey.currentState, command);
  }

  /// Create notes query
  Stream<List<Note>> _createNoteStream(BuildContext context, NoteFilter filter) {
    final user = Provider.of<CurrentUser>(context)?.data;
    final sinceSignUp = DateTime.now().millisecondsSinceEpoch -
      (user?.metadata?.creationTime?.millisecondsSinceEpoch ?? 0);
    final useIndexes = sinceSignUp >= _10_min_millis; // since creating indexes takes time, avoid using composite index until later
    final collection = notesCollection(user?.uid);
    final query = filter.noteState == NoteState.unspecified
      ? collection
        .where('state', isLessThan: NoteState.archived.index) // show both normal/pinned notes when no filter specified
        .orderBy('state', descending: true) // pinned notes come first
      : collection.where('state', isEqualTo: filter.noteState.index);

    return (useIndexes ? query.orderBy('createdAt', descending: true) : query)
      .snapshots()
      .handleError((e) => debugPrint('query notes failed: $e'))
      .map((snapshot) => Note.fromQuery(snapshot));
  }

  /// Partition the note list by the pinned state
  Tuple2<List<Note>, List<Note>> _partitionNotes(List<Note> notes) {
    if (notes?.isNotEmpty != true) {
      return Tuple2([], []);
    }

    final indexUnpinned = notes?.indexWhere((n) => !n.pinned);
    return indexUnpinned > -1
      ? Tuple2(notes.sublist(0, indexUnpinned), notes.sublist(indexUnpinned))
      : Tuple2(notes, []);
  }
}

const _10_min_millis = 600000;
