import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart' as audio;
import '../models/music_models.dart';
import '../services/lyrics_service.dart';

class MusicPlayerProvider extends ChangeNotifier {
  final audio.AudioPlayer _player = audio.AudioPlayer();
  final LyricsService _lyricsService = LyricsService();

  PlaybackState _playbackState = PlaybackState(
    state: PlayerState.stopped,
    position: Duration.zero,
    duration: Duration.zero,
  );

  List<MusicFile> _playlist = [];
  int _currentIndex = -1;
  bool _isShuffled = false;
  bool _isRepeat = false;

  // 歌词相关状态
  LrcData? _currentLyrics;
  bool _showLyrics = false;
  String? _webdavServerUrl;
  String? _webdavUsername;
  String? _webdavPassword;

  PlaybackState get playbackState => _playbackState;
  List<MusicFile> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  bool get isShuffled => _isShuffled;
  bool get isRepeat => _isRepeat;
  MusicFile? get currentFile =>
      _currentIndex >= 0 && _currentIndex < _playlist.length
      ? _playlist[_currentIndex]
      : null;

  // 歌词相关getter
  LrcData? get currentLyrics => _currentLyrics;
  bool get showLyrics => _showLyrics;
  LrcLine? get currentLyricLine =>
      _currentLyrics?.getCurrentLine(_playbackState.position);
  int get currentLyricLineIndex =>
      _currentLyrics?.getCurrentLineIndex(_playbackState.position) ?? -1;

  MusicPlayerProvider() {
    _setupPlayerListeners();
  }

  void _setupPlayerListeners() {
    _player.onPlayerStateChanged.listen((state) {
      final playbackState = _convertPlayerState(state);
      _updatePlaybackState(state: playbackState);
    });

    _player.onDurationChanged.listen((Duration duration) {
      _updatePlaybackState(duration: duration);
    });

    _player.onPositionChanged.listen((Duration position) {
      _updatePlaybackState(position: position);
    });

    _player.onPlayerComplete.listen((_) {
      _onSongComplete();
    });
  }

  PlayerState _convertPlayerState(dynamic state) {
    String stateString = state.toString();
    if (stateString.contains('playing')) {
      return PlayerState.playing;
    } else if (stateString.contains('paused')) {
      return PlayerState.paused;
    } else if (stateString.contains('stopped')) {
      return PlayerState.stopped;
    } else {
      return PlayerState.stopped;
    }
  }

  void _updatePlaybackState({
    PlayerState? state,
    Duration? position,
    Duration? duration,
    MusicFile? currentFile,
    String? error,
  }) {
    _playbackState = _playbackState.copyWith(
      state: state,
      position: position,
      duration: duration,
      currentFile: currentFile,
      error: error,
    );
    notifyListeners();
  }

  Future<void> playFile(MusicFile file, {List<MusicFile>? playlist}) async {
    try {
      _updatePlaybackState(state: PlayerState.loading);

      if (playlist != null) {
        _playlist = playlist;
        _currentIndex = playlist.indexOf(file);
      } else {
        _playlist = [file];
        _currentIndex = 0;
      }

      await _player.play(audio.UrlSource(file.url));
      _updatePlaybackState(currentFile: file);

      // 加载歌词
      _loadLyricsForCurrentFile();
    } catch (e) {
      _updatePlaybackState(state: PlayerState.error, error: '播放失败: $e');
    }
  }

  Future<void> _loadLyricsForCurrentFile() async {
    final file = currentFile;
    if (file == null ||
        _webdavServerUrl == null ||
        _webdavUsername == null ||
        _webdavPassword == null) {
      _currentLyrics = null;
      notifyListeners();
      return;
    }

    try {
      final lyrics = await _lyricsService.loadLyrics(
        file,
        _webdavUsername!,
        _webdavPassword!,
      );
      _currentLyrics = lyrics;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load lyrics: $e');
      _currentLyrics = null;
      notifyListeners();
    }
  }

  void setWebDAVCredentials(
    String serverUrl,
    String username,
    String password,
  ) {
    _webdavServerUrl = serverUrl;
    _webdavUsername = username;
    _webdavPassword = password;
  }

  void toggleLyricsDisplay() {
    _showLyrics = !_showLyrics;
    notifyListeners();
  }

  Future<void> play() async {
    if (_playbackState.state == PlayerState.paused) {
      await _player.resume();
    } else if (currentFile != null) {
      await _player.play(audio.UrlSource(currentFile!.url));
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
    _updatePlaybackState(state: PlayerState.stopped, position: Duration.zero);
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> next() async {
    if (_playlist.isEmpty) return;

    if (_isShuffled) {
      _currentIndex = DateTime.now().millisecondsSinceEpoch % _playlist.length;
    } else {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
    }

    if (_currentIndex < _playlist.length) {
      await playFile(_playlist[_currentIndex]);
    }
  }

  Future<void> previous() async {
    if (_playlist.isEmpty) return;

    if (_playbackState.position.inSeconds > 3) {
      await seekTo(Duration.zero);
      return;
    }

    if (_isShuffled) {
      _currentIndex = DateTime.now().millisecondsSinceEpoch % _playlist.length;
    } else {
      _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    }

    if (_currentIndex >= 0) {
      await playFile(_playlist[_currentIndex]);
    }
  }

  void _onSongComplete() {
    if (_isRepeat) {
      playFile(currentFile!);
    } else if (_currentIndex < _playlist.length - 1 || _isShuffled) {
      next();
    } else {
      _updatePlaybackState(state: PlayerState.stopped);
    }
  }

  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    notifyListeners();
  }

  void setPlaylist(List<MusicFile> files) {
    _playlist = files;
    _currentIndex = -1;
    notifyListeners();
  }

  void addToPlaylist(MusicFile file) {
    _playlist.add(file);
    notifyListeners();
  }

  void removeFromPlaylist(int index) {
    if (index >= 0 && index < _playlist.length) {
      _playlist.removeAt(index);
      if (_currentIndex == index) {
        _currentIndex = -1;
        stop();
      } else if (_currentIndex > index) {
        _currentIndex--;
      }
      notifyListeners();
    }
  }

  void clearPlaylist() {
    _playlist.clear();
    _currentIndex = -1;
    stop();
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
