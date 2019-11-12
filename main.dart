import 'dart:io';
import 'dart:convert';

main(List<String> arguments) {
  arguments.forEach((arg) async {
    arg = arg.substring(arg.lastIndexOf('\\')+1);
    var url = 'https://api.twitch.tv/helix/videos';
    var authToken = 'djgvan0m6ga1cf7jdpzba3qa9c9bdk';
    var startIdIndex = arg.indexOf('_')+1;
    var endIdIndex = arg.indexOf('_', startIdIndex+1);
    var videoId = arg.substring(startIdIndex, endIdIndex);

    var request = await HttpClient().getUrl(Uri.parse('$url?id=$videoId'));
    request.headers.add('Client-Id', authToken);

    var response = await request.close();
    var data = json.decode(await response.transform(Utf8Decoder()).first)['data'][0];

    var createdDateTime = DateTime.parse(data['created_at']);
    var directoryName = '${createdDateTime.year}-${createdDateTime.month}-${createdDateTime.day} ${createdDateTime.hour}.${createdDateTime.minute} ${data['title']}';
    directoryName = directoryName.replaceAll(RegExp('[\\\/:*?"<>|]'), '');
    print(directoryName);
    var directory = Directory('${data['user_name']}/$directoryName');
    var videoFile = File('${arg}');
    if (videoFile.existsSync()) {
      await directory.create(recursive: true);
      videoFile.renameSync('${directory.path}/${arg}');
    }
    else {
      print('sad ${arg}');
    }

    var dataFile = File('${directory.path}/data.txt');
    dataFile.createSync();
    var writer = dataFile.openWrite();
    for (var field in (data as Map).keys) {
      writer.write('$field: ${data[field]}\r\n');
    }
    await writer.close();

    sleep(Duration(seconds: 5));
  });
}
