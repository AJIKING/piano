import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations.dart';
import '../../domain/score/piece.dart';

/// 収録曲(パブリックドメイン)の曲名・作曲者を表示言語へ翻訳する。
///
/// 曲データ([Piece])は日本語の `title` / `composer` を持つが、収録曲は id・
/// 作曲者名をキーに各言語の表記へ解決する。ユーザー作成曲はユーザーが付けた
/// 名前をそのまま使う。未知の id / 作曲者は元の文字列にフォールバックする。
String localizedPieceTitle(BuildContext context, Piece piece) {
  if (piece.isUserCreated) return piece.title;
  final l = AppLocalizations.of(context);
  switch (piece.id) {
    case 'twinkle-star':
      return l.songTwinkleStar;
    case 'chouchou':
      return l.songChouchou;
    case 'frog-round':
      return l.songFrogRound;
    case 'mary-had-a-little-lamb':
      return l.songMaryLamb;
    case 'london-bridge':
      return l.songLondonBridge;
    case 'old-macdonald':
      return l.songOldMacdonald;
    case 'when-the-saints':
      return l.songWhenSaints;
    case 'little-brown-jug':
      return l.songLittleBrownJug;
    case 'alps-ichimanjaku':
      return l.songAlps;
    case 'jingle-bells':
      return l.songJingleBells;
    case 'silent-night':
      return l.songSilentNight;
    default:
      return piece.title;
  }
}

String localizedPieceComposer(BuildContext context, Piece piece) {
  if (piece.isUserCreated) return piece.composer;
  final l = AppLocalizations.of(context);
  switch (piece.composer) {
    case 'フランス民謡':
      return l.composerFrenchFolk;
    case 'ドイツ民謡':
      return l.composerGermanFolk;
    case 'アメリカ民謡':
      return l.composerAmericanFolk;
    case 'イギリス民謡':
      return l.composerEnglishFolk;
    case 'J. ウィナー':
      return l.composerWinner;
    case 'J. ピアポント':
      return l.composerPierpont;
    case 'F. グルーバー':
      return l.composerGruber;
    default:
      return piece.composer;
  }
}
