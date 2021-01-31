import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:photoprism/common/photoprism_uploader.dart';
import 'package:photoprism/model/photo_old.dart' as photo_old;
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photoprism/widgets/auth_dialog.dart';
import 'package:photoprism/widgets/multi_select_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:photo_manager/photo_manager.dart' as photolib;
import 'package:photoprism/pages/auto_upload_queue.dart';
import 'package:easy_localization/easy_localization.dart';

import 'log_view.dart';

class SettingsPage extends StatelessWidget {
  final TextEditingController _urlTextFieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    return Scaffold(
        appBar: AppBar(
          title: const Text('PhotoPrism'),
        ),
        body: Container(
            //width: double.maxFinite,
            child: ListView(
          children: <Widget>[
            ListTile(
              title: const Text('Photoprism URL'),
              subtitle: Text(model.photoprismUrl),
              leading: Container(
                width: 10,
                alignment: Alignment.center,
                child: const Icon(Icons.public),
              ),
              onTap: () {
                _settingsDisplayUrlDialog(context);
              },
            ),
            ListTile(
              title: const Text('authentication').tr(),
              leading: Container(
                width: 10,
                alignment: Alignment.center,
                child: const Icon(Icons.vpn_key),
              ),
              onTap: () => showDialog<void>(
                  context: context,
                  builder: (BuildContext context) => AuthDialog(
                        context: context,
                      )),
            ),
            ListTile(
              title: const Text('empty_cache').tr(),
              leading: Container(
                width: 10,
                alignment: Alignment.center,
                child: const Icon(Icons.delete),
              ),
              onTap: () {
                emptyCache(context);
              },
            ),
            SwitchListTile(
              title: Text('auto_upload'.tr()),
              secondary: const Icon(Icons.cloud_upload),
              value: model.autoUploadEnabled,
              onChanged: (bool newState) async {
                final bool result =
                    await photolib.PhotoManager.requestPermission();
                if (result) {
                  model.photoprismUploader.setAutoUpload(newState);
                  if (newState) {
                    configureAlbumsToUpload(context);
                  }
                } else {
                  model.photoprismMessage
                      .showMessage('Permission to photo library denied!');
                }
              },
            ),
            ListTile(
              title: const Text('warning_autoupload').tr(),
            ),
            if (model.autoUploadEnabled)
              ListTile(
                title: const Text('albums_to_upload').tr(),
                subtitle: _albumsToUploadText(),
                leading: Container(
                  width: 10,
                  alignment: Alignment.center,
                  child: const Icon(Icons.folder),
                ),
                onTap: () {
                  configureAlbumsToUpload(context);
                },
              ),
            if (model.autoUploadEnabled)
              ListTile(
                title: const Text('last_time_checked_for_photos_to_be_uploaded')
                    .tr(),
                subtitle: Text(model.autoUploadLastTimeCheckedForPhotos),
                leading: Container(
                  width: 10,
                  alignment: Alignment.center,
                  child: const Icon(Icons.sync),
                ),
              ),
            if (model.autoUploadEnabled)
              ListTile(
                title: Text('delete_already_uploaded_photos_info'.tr()),
                leading: Container(
                  width: 10,
                  alignment: Alignment.center,
                  child: const Icon(Icons.delete_sweep),
                ),
                onTap: () {
                  deleteUploadInfo(context);
                },
              ),
            if (model.autoUploadEnabled)
              ListTile(
                title: Text('retry_all_failed_uploads'.tr()),
                leading: Container(
                  width: 10,
                  alignment: Alignment.center,
                  child: const Icon(Icons.refresh),
                ),
                onTap: () {
                  PhotoprismUploader.clearFailedUploadList(model);
                },
              ),
            if (model.autoUploadEnabled)
              ListTile(
                title: Text('trigger_auto_upload_manually'.tr()),
                leading: Container(
                  width: 10,
                  alignment: Alignment.center,
                  child: const Icon(Icons.sync),
                ),
                onTap: () {
                  model.photoprismUploader
                      .runAutoUploadBackgroundRoutine(model, 'Manual');
                },
              ),
            if (model.autoUploadEnabled)
              ListTile(
                title: Text('show_upload_queue'.tr()),
                leading: Container(
                  width: 10,
                  alignment: Alignment.center,
                  child: const Icon(Icons.sort),
                ),
                trailing: Text(model.photosToUpload.length.toString()),
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                        builder: (BuildContext ctx) => FileList(model,
                            files: model.photosToUpload.toList(),
                            title: 'Auto upload queue')),
                  );
                },
              ),
            if (model.autoUploadEnabled)
              ListTile(
                title: Text('show_uploaded_photos_list'.tr()),
                leading: Container(
                  width: 10,
                  alignment: Alignment.center,
                  child: const Icon(Icons.sort),
                ),
                trailing: Text(model.alreadyUploadedPhotos.length.toString()),
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                        builder: (BuildContext ctx) => FileList(model,
                            files: model.alreadyUploadedPhotos.toList(),
                            title: 'Uploaded photos list')),
                  );
                },
              ),
            if (model.autoUploadEnabled)
              ListTile(
                title: Text('show_failed_uploads_list'.tr()),
                leading: Container(
                  width: 10,
                  alignment: Alignment.center,
                  child: const Icon(Icons.warning),
                ),
                trailing: Text(model.photosUploadFailed.length.toString()),
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                        builder: (BuildContext ctx) => FileList(model,
                            files: model.photosUploadFailed.toList(),
                            title: 'Failed uploads list')),
                  );
                },
              ),
            ListTile(
                title: const Text('show_log').tr(),
                leading: Container(
                  width: 10,
                  alignment: Alignment.center,
                  child: const Icon(Icons.text_snippet),
                ),
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                        builder: (BuildContext ctx) => LogView(ctx)),
                  );
                }),
            const AboutListTile()
          ],
        )));
  }

  Future<void> deleteUploadInfo(BuildContext context) async {
    await PhotoprismUploader.saveAndSetAlreadyUploadedPhotos(
        Provider.of<PhotoprismModel>(context), <String>{});
    await PhotoprismUploader.saveAndSetPhotosUploadFailed(
        Provider.of<PhotoprismModel>(context), <String>{});
  }

  Future<void> configureAlbumsToUpload(BuildContext context) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    if (!await photolib.PhotoManager.requestPermission()) {
      model.photoprismMessage
          .showMessage('Permission to photo library denied!');
      return;
    }

    final List<photolib.AssetPathEntity> assets =
        await photolib.PhotoManager.getAssetPathList();
    assets.sort((photolib.AssetPathEntity a, photolib.AssetPathEntity b) =>
        b.assetCount.compareTo(a.assetCount));

    final Set<String> result = await showDialog(
        context: context,
        builder: (BuildContext context) => MultiSelectDialog(
            titles: assets
                .map((photolib.AssetPathEntity asset) => asset.name)
                .toList(),
            subtitles: assets
                .map((photolib.AssetPathEntity asset) =>
                    '${asset.assetCount} Elements')
                .toList(),
            ids: assets
                .map((photolib.AssetPathEntity asset) => asset.id)
                .toList(),
            selected: model.albumsToUpload.toList()));

    if (result == null) {
      return;
    }
    if (!const SetEquality<String>().equals(result, model.albumsToUpload)) {
      print('album selection updated');
      PhotoprismUploader.saveAndSetAlbumsToUpload(model, result);
      PhotoprismUploader.getPhotosToUpload(model);
    }
  }

  Future<void> _settingsDisplayUrlDialog(BuildContext context) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    _urlTextFieldController.text = model.photoprismUrl;

    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('enter_photoprism_url'.tr()),
            content: TextField(
              key: const ValueKey<String>('photoprismUrlTextField'),
              controller: _urlTextFieldController,
              decoration: const InputDecoration(
                  hintText: 'https://demo.photoprism.org'),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('cancel'.tr()),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('save'.tr()),
                onPressed: () {
                  setNewPhotoprismUrl(context, _urlTextFieldController.text);
                },
              )
            ],
          );
        });
  }

  Future<void> setNewPhotoprismUrl(BuildContext context, String url) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    Navigator.of(context).pop();
    await model.photoprismCommonHelper.setPhotoprismUrl(url);
    model.photoprismRemoteConfigLoader.loadApplicationColor();
    emptyCache(context);
  }

  static Future<void> emptyCache(BuildContext context) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    final SharedPreferences sp = await SharedPreferences.getInstance();
    sp.remove('momentsTime');
    sp.remove('photos');
    sp.remove('videos');
    sp.remove('albums');
    if (model.albums != null) {
      for (final int albumId in model.albums.keys) {
        sp.remove('photos' + albumId.toString());
      }
    }
    model.photosOld = null;
    model.videos = <int, photo_old.Photo>{};
    model.momentsTime = null;
    model.albums = null;
    model.config = null;
    await DefaultCacheManager().emptyCache();
    model.resetDatabase();
  }

  Widget _albumsToUploadText() => FutureBuilder<List<photolib.AssetPathEntity>>(
      future: photolib.PhotoManager.getAssetPathList(),
      builder: (BuildContext context,
          AsyncSnapshot<List<photolib.AssetPathEntity>> snapshot) {
        if (snapshot.data == null) {
          return const Text('');
        }
        final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
        String selectedAlbums = '';
        for (final photolib.AssetPathEntity album in snapshot.data) {
          if (model.albumsToUpload.contains(album.id)) {
            selectedAlbums += '${album.name}, ';
          }
        }
        if (selectedAlbums.isEmpty) {
          return const Text('none');
        }
        return Text(selectedAlbums.substring(0, selectedAlbums.length - 2));
      });
}
