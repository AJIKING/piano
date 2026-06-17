import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../application/practice_controller.dart';
import '../../domain/audio/audio_engine.dart';
import '../../domain/score/piece.dart';
import '../../domain/score/score_geometry.dart';
import '../i18n/piece_labels.dart';
import '../theme/etude_theme.dart';
import '../widgets/grand_staff_view.dart';
import '../widgets/piano_keyboard.dart';
import '../widgets/score_scroll_follower.dart';
import '../widgets/score_view.dart';

/// 練習画面。譜面・テンポ・メトロノーム・再生と、下部の鍵盤。
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    super.key,
    required this.piece,
    required this.audioEngine,
  });

  final Piece piece;
  final AudioEngine audioEngine;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  static const _geometry = ScoreGeometry();
  late final PracticeController _controller;
  final ScoreScrollFollower _follow = ScoreScrollFollower();
  bool _audioReady = false;

  /// 譜面でタップして選んだ「再生開始音符」(正準順インデックス)。
  /// null なら先頭から再生する。
  int? _startIndex;

  /// 両手(大譜表＋両手再生)モード。収録曲で fullNotes がある時だけ使える。
  bool _twoHand = false;

  /// 両手/片手を切り替える。再生対象(controller.piece)も差し替える。
  void _toggleTwoHand() {
    _controller.stop();
    setState(() {
      _twoHand = !_twoHand;
      _startIndex = null;
      _controller.piece = _twoHand
          ? widget.piece.copyWith(notes: widget.piece.fullNotes)
          : widget.piece;
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = PracticeController(
      piece: widget.piece,
      audioEngine: widget.audioEngine,
      bpm: widget.piece.defaultBpm.toDouble(),
    );
    // 鳴る音が変わるたびに(=毎フレームではなく)再生ヘッドを追従させる。
    _controller.litPitches.addListener(_followPlayhead);
  }

  @override
  void dispose() {
    _controller.litPitches.removeListener(_followPlayhead);
    _controller.dispose();
    _follow.dispose();
    super.dispose();
  }

  /// 再生中、再生ヘッドが見切れたら譜面をスクロールして追従する。
  /// ただしユーザーが手動スクロール中は [ScoreScrollFollower] 側で追従を止める。
  void _followPlayhead() => _follow.follow(
    isActive: () => _controller.isPlaying,
    targetX: () => _geometry.xAtBeat(_controller.playheadBeats),
  );

  void _onKey(String pitch) {
    if (!_audioReady) {
      widget.audioEngine.init();
      _audioReady = true;
    }
    widget.audioEngine.playNote(pitch);
  }

  double? _playheadX() {
    if (!_controller.isPlaying) return null;
    return _geometry.xAtBeat(_controller.playheadBeats);
  }

  /// 選択した音符があればその位置から、無ければ先頭から再生する。
  void _togglePlay() {
    if (_controller.isPlaying) {
      _controller.stop();
    } else {
      _follow.resume(); // 再生開始で追従を復帰。
      final notes = widget.piece.sortedNotes;
      final i = _startIndex;
      final from = (i != null && i < notes.length) ? notes[i].beat : 0.0;
      _controller.play(fromBeat: from);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        // 横画面で縦を節約するため、曲名はやや小さめ・低めのバーに。
        toolbarHeight: 48,
        title: Text(
          localizedPieceTitle(context, widget.piece),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          // 両手(バスを含む)フル譜面がある収録曲だけ「両手のお手本」に切り替えられる。
          if (widget.piece.hasTwoHandScore)
            IconButton(
              icon: Icon(_twoHand ? Icons.piano : Icons.menu_book_outlined),
              tooltip: _twoHand ? l.oneHandBack : l.twoHandModel,
              onPressed: _toggleTwoHand,
            ),
        ],
      ),
      body: Column(
        children: [
          // 譜面と再生コントロールは毎フレーム(再生ヘッド)更新する。
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final playing = _controller.isPlaying;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 手動ドラッグを検知したら自動追従を止める(見たい所を見続ける)。
                  _follow.wrap(
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
                      child: _twoHand
                          ? GrandStaffView(
                              notes: widget.piece.fullNotes,
                              beatsPerMeasure: widget.piece.beatsPerMeasure,
                              scrollController: _follow.controller,
                              litNoteIndices: playing
                                  ? _controller.litNoteIndices
                                  : const {},
                              playheadX: _playheadX(),
                            )
                          : ScoreView(
                              piece: widget.piece,
                              geometry: _geometry,
                              scrollController: _follow.controller,
                              litNoteIndices: playing
                                  ? _controller.litNoteIndices
                                  : const {},
                              playheadX: _playheadX(),
                              // 停止中は選んだ開始音符を強調。タップで開始位置を選び、
                              // 同じ音符を再タップで解除して先頭からに戻す。
                              selectedIndex: playing ? null : _startIndex,
                              onSelectNote: playing
                                  ? null
                                  : (i) => setState(
                                      () => _startIndex = _startIndex == i
                                          ? null
                                          : i,
                                    ),
                            ),
                    ),
                  ),
                  _controls(),
                ],
              );
            },
          ),
          // 両手(お手本)モードでは鍵盤を出さず、大譜表を主役にする。
          if (_twoHand)
            const Spacer()
          else ...[
            const Divider(height: 1),
            // 鍵盤は「鳴る音が変わった時」だけ再構築する(毎フレーム再構築を避ける)。
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ValueListenableBuilder<Set<String>>(
                  valueListenable: _controller.litPitches,
                  builder: (context, lit, _) => PianoKeyboard(
                    onNotePressed: _onKey,
                    height: 160,
                    litPitches: lit,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton.filled(
            onPressed: _togglePlay,
            icon: Icon(
              _controller.isPlaying
                  ? Icons.stop_rounded
                  : Icons.play_arrow_rounded,
            ),
            tooltip: _controller.isPlaying
                ? AppLocalizations.of(context).stop
                : AppLocalizations.of(context).play,
          ),
          const SizedBox(width: 8),
          Text(
            '${_controller.bpm.round()}',
            style: const TextStyle(
              fontFamily: EtudeTheme.mono,
              color: EtudeColors.brassSoft,
            ),
          ),
          const Text(
            ' BPM',
            style: TextStyle(fontSize: 10, color: EtudeColors.ivory3),
          ),
          Expanded(
            child: Slider(
              min: PracticeController.minBpm,
              max: PracticeController.maxBpm,
              value: _controller.bpm,
              onChanged: _controller.setBpm,
            ),
          ),
          IconButton(
            onPressed: _controller.toggleMetronome,
            isSelected: _controller.metronomeOn,
            icon: const Icon(Icons.av_timer_outlined),
            selectedIcon: const Icon(Icons.av_timer),
            tooltip: AppLocalizations.of(context).metronome,
          ),
        ],
      ),
    );
  }
}
