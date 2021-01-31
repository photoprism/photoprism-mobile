import 'package:flutter/widgets.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';

class AlbumManager {
  static Future<void> addPhotosToAlbum(
      BuildContext context, int albumId, List<String> photoUUIDs) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    print('Adding photos to album ' + model.albums[albumId].uid);
    model.photoprismLoadingScreen.showLoadingScreen('Adding photos to album..');
    final int status = await Api.addPhotosToAlbum(
        model.albums[albumId].uid, photoUUIDs, model);

    if (status == 0) {
      final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
      await Api.updateDb(model);
      await model.photoprismLoadingScreen.hideLoadingScreen();
      model.photoprismMessage
          .showMessage('Adding photos to album successfull.');
    } else {
      await model.photoprismLoadingScreen.hideLoadingScreen();
      model.photoprismMessage.showMessage('Adding photos to album failed.');
    }
  }
}
