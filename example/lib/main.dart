import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:audio_service/audio_service.dart';
// import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

// import 'dart:math';

// import 'package:flutter/material.dart';
// import 'dart:async';

// import 'dart:developer' as logger;

// import 'package:audio_service/audio_service.dart';
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:rxdart/rxdart.dart';

//Used by player page
import 'package:auto_size_text/auto_size_text.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

MediaControl playControl = MediaControl(
  androidIcon: 'drawable/ic_stat_play_arrow',
  label: 'Play',
  action: MediaAction.play,
);
MediaControl pauseControl = MediaControl(
  androidIcon: 'drawable/ic_stat_pause',
  label: 'Pause',
  action: MediaAction.pause,
);
MediaControl skipToNextControl = MediaControl(
  androidIcon: 'drawable/ic_stat_skip_next',
  label: 'Next',
  action: MediaAction.skipToNext,
);
MediaControl skipToPreviousControl = MediaControl(
  androidIcon: 'drawable/ic_stat_skip_previous',
  label: 'Previous',
  action: MediaAction.skipToPrevious,
);
MediaControl stopControl = MediaControl(
  androidIcon: 'drawable/ic_stat_stop',
  label: 'Stop',
  action: MediaAction.stop,
);

// void main() => runApp(new MyApp());
void main() => runApp(new PlaylistView());

class PlaylistView extends StatelessWidget {
  // const name({Key key}) : super(key: key);
  final mediaItems = <MediaItem>[
    MediaItem(
      id: "https://firebasestorage.googleapis.com/v0/b/speakeng-da85a.appspot.com/o/Episodes%2FI%20Need%20Thee%20Every%20Hour.mp3?alt=media&token=0013a8ec-cea5-4d9a-bd97-922d6a79595b",
      album: "Refill My Soul",
      title: "Peace in Difficult Times",
      artist: "Shauna",
      duration: 60000,
      //TODO: Change URI to art work image
      artUri:
          "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg",
    ),
    MediaItem(
      id: "https://firebasestorage.googleapis.com/v0/b/speakeng-da85a.appspot.com/o/Episodes%2FThere%20Is%20A%20Green%20Hill%20Far%20Away.mp3?alt=media&token=c2808c4e-a957-459d-8a7a-6307caae3037",
      album: "Refill My Soul",
      title: "There Is A Green Hill Far Away",
      artist: "Shauna",
      duration: 60000,
      artUri:
          //TODO: Change URI to art work image
          "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg",
    )
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('Audio Test'),
        ),
        body: Container(
          child: new ListView.builder(
              itemCount: mediaItems.length,
              itemBuilder: (BuildContext context, int index) {
                // return new Text(mediaItems[index].id);
                return ListTile(
                  leading: Icon(Icons.music_note),
                  title: Text(mediaItems[index].title),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          // Goes to new page and selects media item to play
                          builder: (context) => MyApp(mediaItems[index]),
                        ));
                  },
                );
              }),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  /// Values passed from other routes
  final MediaItem selectedItem;
  //TODO: Make this necessary to run
  MyApp(this.selectedItem);

  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final BehaviorSubject<double> _dragPositionSubject =
      BehaviorSubject.seeded(null);

//Represented in milliseconds (used by skip buttons)
  final int TEN_SECONDS = 10000;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    connect();
    // if (AudioServiceBackground.state.basicState == BasicPlaybackState.none) {
    AudioService.start(
      backgroundTaskEntrypoint: _audioPlayerTaskEntrypoint,
      androidNotificationChannelName: 'Audio Service Demo', //TODO: Rename
      notificationColor: 0xFF2196f3,
      androidNotificationIcon: 'mipmap/ic_launcher',
      enableQueue: true,
    );
    // }
    // logger.log(widget.selectedItem.toString());

    AudioService.addQueueItem(widget.selectedItem);
  }

  @override
  void dispose() {
    disconnect();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        connect();
        break;
      case AppLifecycleState.paused:
        disconnect();
        break;
      default:
        break;
    }
  }

  void connect() async {
    await AudioService.connect();
  }

  void disconnect() {
    AudioService.disconnect();
  }

  final controller = PageController(viewportFraction: 1);

  //TODO: App acts weird if stopped, might want to have a method that sends back to home screen if playback is stopped
  //TODO: Change background picture to Refill My Soul background
  //TODO: Update audio service to 0.7.1 (look at GitHub changes to example)

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        AudioService.stop();
        //
        // logger.log("Pop it like it's hot");
        // disconnect();
        return Future.value(true);
      },
      child: new Scaffold(
        appBar: new AppBar(
          // title: const Text('Audio Service Demo'),
          backgroundColor: const Color(0xFFFFFFFF),
          iconTheme: IconThemeData(color: Colors.black),
          elevation: 0,
        ),
        body: new Center(
          child: StreamBuilder<ScreenState>(
            stream: Rx.combineLatest3<List<MediaItem>, MediaItem, PlaybackState,
                    ScreenState>(
                AudioService.queueStream,
                AudioService.currentMediaItemStream,
                AudioService.playbackStateStream,
                (queue, mediaItem, playbackState) =>
                    ScreenState(queue, mediaItem, playbackState)),
            builder: (context, snapshot) {
              final screenState = snapshot.data;
              final queue = screenState?.queue;
              final mediaItem = screenState?.mediaItem;
              final state = screenState?.playbackState;
              final basicState = state?.basicState ?? BasicPlaybackState.none;
              return Container(
                color: const Color(0xFFFFFFFF),
                child: Column(
                  // mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //TODO: Skip functionality
                    // if (queue != null && queue.isNotEmpty)
                    //   Row(
                    //     mainAxisAlignment: MainAxisAlignment.center,
                    //     children: [
                    //       IconButton(
                    //         icon: Icon(Icons.skip_previous),
                    //         iconSize: 64.0,
                    //         onPressed: mediaItem == queue.first
                    //             ? null
                    //             : AudioService.skipToPrevious,
                    //       ),
                    //       IconButton(
                    //         icon: Icon(Icons.skip_next),
                    //         iconSize: 64.0,
                    //         onPressed: mediaItem == queue.last
                    //             ? null
                    //             : AudioService.skipToNext,
                    //       ),
                    //     ],
                    //   ),
                    if (mediaItem?.title != null)
                      // Text(mediaItem.title),
                      //   Padding(
                      //     padding: const EdgeInsets.only(top: 14),
                      //     child: Text(
                      //       mediaItem.title,
                      //       style: TextStyle(
                      //         fontSize: 20,
                      //         fontWeight: FontWeight.w600,
                      //       ),
                      //     ),
                      //   ),
                      // Container(
                      //   padding: EdgeInsets.fromLTRB(0, 14, 0, 0),
                      //   constraints: BoxConstraints(
                      //       maxHeight: 100.0,
                      //       maxWidth: 250.0,
                      //       minWidth: 200.0,
                      //       minHeight: 50.0),
                      //   child: AutoSizeText(
                      //     '"Remember all that has been done for you this day"',
                      //     textAlign: TextAlign.center,
                      //     style: TextStyle(
                      //       fontSize: 12,
                      //       color: Colors.grey,
                      //     ),
                      //     maxLines: 2,
                      //   ),
                      // ),
                      if (basicState == BasicPlaybackState.none ||
                          basicState == BasicPlaybackState.stopped) ...[
                        //TODO: Indicate error to user
                        // audioPlayerButton(),
                        // textToSpeechButton(),
                      ] else
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          //Recently added here (was under if title statement)
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Text(
                                mediaItem.title,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.fromLTRB(0, 14, 0, 0),
                              constraints: BoxConstraints(
                                  maxHeight: 100.0,
                                  maxWidth: 250.0,
                                  minWidth: 200.0,
                                  minHeight: 50.0),
                              child: AutoSizeText(
                                '"Remember all that has been done for you this day"',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                maxLines: 2,
                              ),
                            ),
                            Container(
                              height: 330,
                              width: 320,
                              // padding: EdgeInsets.only(top: ),
                              margin: EdgeInsets.only(top: 20),
                              child: Card(
                                semanticContainer: true,
                                clipBehavior: Clip.antiAliasWithSaveLayer,
                                color: Color.fromRGBO(236, 239, 247, 1),
                                // child: Image.asset(
                                //   'assets/images/Refill-My-Soul-Logo(edited).png',
                                //   // fit: BoxFit.fill,
                                // ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                elevation: 1,
                                // margin: EdgeInsets.all(10),
                              ),
                            ),
                            if (basicState != BasicPlaybackState.none &&
                                basicState != BasicPlaybackState.stopped) ...[
                              Container(
                                margin: EdgeInsets.only(top: 20),
                                child: positionIndicator(mediaItem, state),
                              ),
                              // Text("State: " +
                              //     "$basicState".replaceAll(RegExp(r'^.*\.'), '')),
                            ],
                            Container(
                              margin: EdgeInsets.only(top: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  // if (basicState ==)

                                  if (basicState ==
                                      BasicPlaybackState.playing) ...[
                                    skipBack10Button(mediaItem, state),
                                    pauseButton(),
                                    skipForward10Button(mediaItem, state)
                                  ] else if (basicState ==
                                      BasicPlaybackState.paused) ...[
                                    skipBack10Button(mediaItem, state),
                                    playButton(),
                                    skipForward10Button(mediaItem, state)
                                  ] else if (basicState ==
                                          BasicPlaybackState.buffering ||
                                      basicState ==
                                          BasicPlaybackState.skippingToNext ||
                                      basicState ==
                                          BasicPlaybackState
                                              .skippingToPrevious ||
                                      basicState ==
                                          BasicPlaybackState.connecting)
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: SizedBox(
                                        width: 64.0,
                                        height: 64.0,
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // stopButton(),
                            // Text(basicState.toString()),
                          ],
                        ),
                    if (basicState != BasicPlaybackState.none &&
                        basicState != BasicPlaybackState.stopped) ...[
                      //TODO: Indicate error to user
                      // audioPlayerButton(),
                      // textToSpeechButton(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.only(top: 50),
                            child: SmoothPageIndicator(
                              controller: controller,
                              count: 2,
                              effect: WormEffect(
                                  dotHeight: 8,
                                  dotWidth: 8,
                                  activeDotColor: Colors.black54),
                            ),
                          ),
                        ],
                      )
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  RaisedButton audioPlayerButton() => startButton(
        'AudioPlayer',
        () {
          // print();

          // final mediaItem = MediaItem(
          //   id: "http://dl6.freemp3downloads.online/file/youtubeHAfFfqiYLp0128.mp3?fn=Kanye%20West%20-%20All%20Of%20The%20Lights%20ft.%20Rihanna%2C%20Kid%20Cudi.mp3",
          //   album: "Science Friday",
          //   title: "The test",
          //   artist: "Science Friday and WNYC Studios",
          //   duration: 327000,
          //   artUri:
          //       "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg",
          // );

          // AudioService.play();
          // await AudioService.playFromMediaId(mediaItem.id);
          // // AudioService.playFromMediaId(mediaItem.id);
        },
      );

  // RaisedButton textToSpeechButton() => startButton(
  //       'TextToSpeech',
  //       () {
  //         AudioService.start(
  //           backgroundTaskEntrypoint: _textToSpeechTaskEntrypoint,
  //           androidNotificationChannelName: 'Audio Service Demo',
  //           notificationColor: 0xFF2196f3,
  //           androidNotificationIcon: 'mipmap/ic_launcher',
  //         );
  //       },
  //     );

  RaisedButton startButton(String label, VoidCallback onPressed) =>
      RaisedButton(
        child: Text(label),
        onPressed: onPressed,
      );

  MaterialButton playButton() => MaterialButton(
        child: Icon(
          Icons.play_arrow,
          size: 40,
        ),
        textColor: Colors.white,
        color: Color.fromRGBO(80, 174, 221, 1),
        padding: EdgeInsets.all(16),
        shape: CircleBorder(),
        onPressed: AudioService.play,
      );

  MaterialButton pauseButton() => MaterialButton(
        child: Icon(
          Icons.pause,
          size: 40,
        ),
        textColor: Colors.white,
        color: Color.fromRGBO(80, 174, 221, 1),
        padding: EdgeInsets.all(16),
        shape: CircleBorder(),
        onPressed: AudioService.pause,
      );

  MaterialButton skipBack10Button(MediaItem mediaItem, PlaybackState state) =>
      MaterialButton(
          child: Icon(
            Icons.replay_10,
            size: 30,
          ),
          textColor: Colors.black54,
          padding: EdgeInsets.all(16),
          shape: CircleBorder(),
          onPressed: () {
            AudioService.seekTo(state.currentPosition - TEN_SECONDS);
          });

  MaterialButton skipForward10Button(
          MediaItem mediaItem, PlaybackState state) =>
      MaterialButton(
          child: Icon(
            Icons.forward_10,
            size: 30,
          ),
          textColor: Colors.black54,
          padding: EdgeInsets.all(16),
          shape: CircleBorder(),
          onPressed: () {
            AudioService.seekTo(state.currentPosition + TEN_SECONDS);
          });

  // IconButton stopButton() => IconButton(
  //       icon: Icon(Icons.stop),
  //       iconSize: 64.0,
  //       onPressed: AudioService.stop,
  //     );

  Widget positionIndicator(MediaItem mediaItem, PlaybackState state) {
    double seekPos;
    //TODO: Consider changing slider to also react to seekPos as well (to int can't be called on null)

    String _printDuration(Duration duration) {
      //NOTE: Does not account for days or anything greater than days

      // Duration duration = Duration(milliseconds: ms);

      String twoDigits(int n) {
        if (n >= 10) return "$n";
        return "0$n";
      }

      String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
      String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
      // logger.log("$twoDigitMinutes:$twoDigitSeconds");

      if (duration.inHours == 0) return "$twoDigitMinutes:$twoDigitSeconds";
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }

    return StreamBuilder(
      stream: Rx.combineLatest2<double, double, double>(
          _dragPositionSubject.stream,
          Stream.periodic(Duration(milliseconds: 200)),
          (dragPosition, _) => dragPosition),
      builder: (context, snapshot) {
        double position = snapshot.data ?? state.currentPosition.toDouble();
        double duration = mediaItem?.duration?.toDouble();
        return Column(
          children: [
            if (duration != null)
              Slider(
                min: 0.0,
                max: duration,
                value: seekPos ?? max(0.0, min(position, duration)),
                activeColor: Color.fromRGBO(80, 174, 221, 1),
                onChanged: (value) {
                  _dragPositionSubject.add(value);
                },
                onChangeEnd: (value) {
                  AudioService.seekTo(value.toInt());
                  // Due to a delay in platform channel communication, there is
                  // a brief moment after releasing the Slider thumb before the
                  // new position is broadcast from the platform side. This
                  // hack is to hold onto seekPos until the next state update
                  // comes through.
                  // TODO: Improve this code.
                  seekPos = value;
                  _dragPositionSubject.add(null);
                },
              ),
            // Text("${(state.currentPosition / 1000).toStringAsFixed(3)}"),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 0, 20, 0),
              child: Container(
                transform: Matrix4.translationValues(0.0, -10.0, 0.0),
                child: Row(children: <Widget>[
                  Text(
                    //Shows duration of slider or actual playback state duration
                    "${_printDuration(Duration(milliseconds: _dragPositionSubject.value != null ? _dragPositionSubject.value.toInt() : state.currentPosition))}",
                    // "${(state.currentPosition / 1000).toStringAsFixed(3)}",
                    style: TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 12,
                    ),
                  ),

                  Spacer(), // use Spacer
                  Text(
                    // Value below was originally mediaItem?.duration? (check if this causes errors)
                    //Shows duration of slider or actual playback state duration - current plackback state position
                    "-${_printDuration(_dragPositionSubject.value != null ? Duration(milliseconds: mediaItem?.duration) - Duration(milliseconds: _dragPositionSubject.value.toInt()) : Duration(milliseconds: mediaItem?.duration) - Duration(milliseconds: state.currentPosition))}",
                    style: TextStyle(fontWeight: FontWeight.w300, fontSize: 12),
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ScreenState {
  final List<MediaItem> queue;
  final MediaItem mediaItem;
  final PlaybackState playbackState;

  ScreenState(this.queue, this.mediaItem, this.playbackState);
}

void _audioPlayerTaskEntrypoint() async {
  AudioServiceBackground.run(() => AudioPlayerTask());
}

class AudioPlayerTask extends BackgroundAudioTask {
  final _queue = <MediaItem>[];
  //    // MediaItem(
  //   id: "https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3",
  //   album: "Science Friday",
  //   title: "A Salute To Head-Scratching Science",
  //   artist: "Science Friday and WNYC Studios",
  //   duration: 5739820,
  //   artUri:
  //       "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg",
  // ),
  // MediaItem(
  //   id: "https://s3.amazonaws.com/scifri-segments/scifri201711241.mp3",
  //   album: "Science Friday",
  //   title: "From Cat Rheology To Operatic Incompetence",
  //   artist: "Science Friday and WNYC Studios",
  //   duration: 2856950,
  //   artUri:
  //       "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg",
  // ),

  // final _queue = <String, MediaItem>{};

  int _queueIndex = -1;
  AudioPlayer _audioPlayer = new AudioPlayer();
  Completer _completer = Completer();
  BasicPlaybackState _skipState;
  bool _playing;

  bool get hasNext => _queueIndex + 1 < _queue.length;

  bool get hasPrevious => _queueIndex > 0;

  MediaItem get mediaItem => _queue[_queueIndex];

  BasicPlaybackState _stateToBasicState(AudioPlaybackState state) {
    // print(state);
    // print(_audioPlayer.buffering);
    switch (state) {
      case AudioPlaybackState.none:
        return BasicPlaybackState.none;
      case AudioPlaybackState.stopped:
        return BasicPlaybackState.stopped;
      case AudioPlaybackState.paused:
        return BasicPlaybackState.paused;
      case AudioPlaybackState.playing:
        return BasicPlaybackState.playing;
      //   //TODO: Figure this code out
      // case AudioPlaybackState.buffering:
      //   return BasicPlaybackState.buffering;
      case AudioPlaybackState.connecting:
        return _skipState ?? BasicPlaybackState.connecting;
      case AudioPlaybackState.completed:
        return BasicPlaybackState.stopped;
      default:
        throw Exception("Illegal state");
    }
  }

  @override
  Future<void> onStart() async {
    var playerStateSubscription = _audioPlayer.playbackStateStream
        .where((state) => state == AudioPlaybackState.completed)
        .listen((state) {
      _handlePlaybackCompleted();
    });
    var eventSubscription = _audioPlayer.playbackEventStream.listen((event) {
      final state = _stateToBasicState(event.state);
      if (state != BasicPlaybackState.stopped) {
        _setState(
          state: state,
          position: event.position.inMilliseconds,
        );
      }
    });

    // AudioServiceBackground.setQueue(_queue);
    await onSkipToNext();
    await _completer.future;
    playerStateSubscription.cancel();
    eventSubscription.cancel();
  }

  void _handlePlaybackCompleted() {
    if (hasNext) {
      onSkipToNext();
    } else {
      // onStop();
      onPause();
    }
  }

  void playPause() {
    if (AudioServiceBackground.state.basicState == BasicPlaybackState.playing)
      onPause();
    else
      onPlay();
  }

  @override
  Future<void> onSkipToNext() => _skip(1);

  @override
  Future<void> onSkipToPrevious() => _skip(-1);

  Future<void> _skip(int offset) async {
    final newPos = _queueIndex + offset;
    if (!(newPos >= 0 && newPos < _queue.length)) return;
    if (_playing == null) {
      // First time, we want to start playing
      _playing = true;
    } else if (_playing) {
      // Stop current item
      await _audioPlayer.stop();
    }
    // Load next item
    _queueIndex = newPos;
    AudioServiceBackground.setMediaItem(mediaItem);
    _skipState = offset > 0
        ? BasicPlaybackState.skippingToNext
        : BasicPlaybackState.skippingToPrevious;
    await _audioPlayer.setUrl(mediaItem.id);
    _skipState = null;
    // Resume playback if we were playing
    if (_playing) {
      onPlay();
    } else {
      _setState(state: BasicPlaybackState.paused);
    }
  }

  @override
  void onPlay() {
    if (_skipState == null) {
      _playing = true;
      _audioPlayer.play();
    }
  }

  @override
  void onPause() {
    if (_skipState == null) {
      _playing = false;
      _audioPlayer.pause();
    }
  }

  @override
  void onSeekTo(int position) {
    _audioPlayer.seek(Duration(milliseconds: position));
  }

  @override
  void onClick(MediaButton button) {
    playPause();
  }

  @override
  void onStop() {
    _audioPlayer.stop();
    _setState(state: BasicPlaybackState.stopped);
    _completer.complete();
  }

  void _setState({@required BasicPlaybackState state, int position}) {
    if (position == null) {
      position = _audioPlayer.playbackEvent.position.inMilliseconds;
    }
    AudioServiceBackground.setState(
      controls: getControls(state),
      systemActions: [MediaAction.seekTo],
      basicState: state,
      position: position,
    );
  }

  List<MediaControl> getControls(BasicPlaybackState state) {
    if (_playing) {
      return [
        skipToPreviousControl,
        pauseControl,
        stopControl,
        skipToNextControl
      ];
    } else {
      return [
        skipToPreviousControl,
        playControl,
        stopControl,
        skipToNextControl
      ];
    }
  }

  @override
  void onAddQueueItem(MediaItem mediaItem) {
    super.onAddQueueItem(mediaItem);
    _queue.add(mediaItem);
    AudioServiceBackground.setQueue(_queue);
  }

  @override
  void onPlayFromMediaId(String mediaId) async {
    // play the item at mediaItems[mediaId]
    // await _audioPlayer.setUrl(mediaId);
    _audioPlayer.play();
  }
}

// void _textToSpeechTaskEntrypoint() async {
//   AudioServiceBackground.run(() => TextPlayerTask());
// }

// class TextPlayerTask extends BackgroundAudioTask {
//   // FlutterTts _tts = FlutterTts();

//   /// Represents the completion of a period of playing or pausing.
//   Completer _playPauseCompleter = Completer();

//   /// This wraps [_playPauseCompleter.future], replacing [_playPauseCompleter]
//   /// if it has already completed.
//   Future _playPauseFuture() {
//     if (_playPauseCompleter.isCompleted) _playPauseCompleter = Completer();
//     return _playPauseCompleter.future;
//   }

//   BasicPlaybackState get _basicState => AudioServiceBackground.state.basicState;

//   @override
//   Future<void> onStart() async {
//     playPause();
//     for (var i = 1; i <= 10 && _basicState != BasicPlaybackState.stopped; i++) {
//       AudioServiceBackground.setMediaItem(mediaItem(i));
//       AudioServiceBackground.androidForceEnableMediaButtons();
//       // _tts.speak('$i');
//       // Wait for the speech or a pause request.
//       await Future.any(
//           [Future.delayed(Duration(seconds: 1)), _playPauseFuture()]);
//       // If we were just paused...
//       if (_playPauseCompleter.isCompleted &&
//           _basicState == BasicPlaybackState.paused) {
//         // Wait to be unpaused...
//         await _playPauseFuture();
//       }
//     }
//     if (_basicState != BasicPlaybackState.stopped) onStop();
//   }

//   MediaItem mediaItem(int number) => MediaItem(
//       id: 'tts_$number',
//       album: 'Numbers',
//       title: 'Number $number',
//       artist: 'Sample Artist');

//   void playPause() {
//     if (_basicState == BasicPlaybackState.playing) {
//       // _tts.stop();
//       AudioServiceBackground.setState(
//         controls: [playControl, stopControl],
//         basicState: BasicPlaybackState.paused,
//       );
//     } else {
//       AudioServiceBackground.setState(
//         controls: [pauseControl, stopControl],
//         basicState: BasicPlaybackState.playing,
//       );
//     }
//     _playPauseCompleter.complete();
//   }

//   @override
//   void onPlay() {
//     playPause();
//   }

//   @override
//   void onPause() {
//     playPause();
//   }

//   @override
//   void onClick(MediaButton button) {
//     playPause();
//   }

//   @override
//   void onStop() {
//     if (_basicState == BasicPlaybackState.stopped) return;
//     // _tts.stop();
//     AudioServiceBackground.setState(
//       controls: [],
//       basicState: BasicPlaybackState.stopped,
//     );
//     _playPauseCompleter.complete();
//   }
// }
