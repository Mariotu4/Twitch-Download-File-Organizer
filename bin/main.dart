import 'dart:io';
import 'dart:convert';

main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print('Program expects absolute file paths of videos - drag the video files over the executable.');
    return;
  }

  //get oauth token
  var clientId = 'djgvan0m6ga1cf7jdpzba3qa9c9bdk';
  var auth_url = 'https://id.twitch.tv/oauth2/authorize?client_id=$clientId&redirect_uri=http://localhost/&response_type=token&scope=';
  stdout.write('Please go to $auth_url, sign in (if you need to), and paste the resulting link (it may take a second to direct to localhost): ');
  var authToken = RegExp('(?<=access_token=)[a-z0-9]+(?=&scope)').firstMatch(stdin.readLineSync()).group(0);
  print('');

  await Future.forEach(arguments, (videoPath) => organizeVideo(videoPath, clientId, authToken));
  await Future.delayed(Duration(seconds: 5), () => exit(1));
}

void organizeVideo(String videoPath, String clientId, String authToken) async {
  var videoFileName = videoPath.substring(videoPath.lastIndexOf('\\')+1);

  //get video id
  var url = 'https://api.twitch.tv/helix/videos';
  var twitchLeecherPattern = RegExp('(?<=[0-9]+_)[0-9]+(?=_)');
  var youtubeDlPattern = RegExp('(?<=v)[0-9]+(?=.mp4)');

  var videoId;
  if (twitchLeecherPattern.hasMatch(videoPath)) {
    videoId = twitchLeecherPattern.firstMatch(videoPath).group(0);
  }
  else if (youtubeDlPattern.hasMatch(videoPath)) {
    videoId = youtubeDlPattern.firstMatch(videoPath).group(0);
  }
  else {
    print('Unrecognized name format - have you used the default setting for twitch leecher/youtube-dl?');
    return;
  }

  var request = await HttpClient().getUrl(Uri.parse('$url?id=$videoId'));
  request.headers.add('Client-Id', clientId);
  request.headers.add('Authorization', 'Bearer $authToken');

  //determine if the data exists
  var response = await request.close();
  if (response.statusCode == 404) {
    print('$videoFileName video has been deleted from twitch.');
    return;
  }

  //gather data
  var data = json.decode(await response.transform(Utf8Decoder()).first)['data'][0];
  var createdDateTime = DateTime.parse(data['created_at']);
  var streamer = data['user_name'];
  var streamNameSafe = '${data['title']}'.replaceAll(RegExp('[\\/:*?"<>|]'), '');
  var directoryName = '${createdDateTime.year}-${createdDateTime.month}-${createdDateTime.day} ${createdDateTime.hour}.${createdDateTime.minute} $streamNameSafe';
  var streamerDirectory = Directory('$streamer');
  var videoDirectory = Directory('${streamerDirectory.path}/$directoryName');
  var videoFile = File('${videoPath}');

  //move file
  if (videoFile.existsSync()) {
    streamerDirectory.createSync();
    videoDirectory.createSync();

    print('Archived ${videoDirectory.path}/$videoFileName');
    videoFile.renameSync('${videoDirectory.path}/$videoFileName');
  }

  //write information
  File('${videoDirectory.path}/data.json')
  ..createSync()
  ..writeAsStringSync(JsonEncoder.withIndent('\t').convert(data));
}