import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late var _myController;
  bool buttonWorks = true;
  String displayString = "";
  late Future<Position> _futurePosition;
  late Stream<Position> positionStream;
  final ImagePicker picker = ImagePicker();
  File? imageFile;

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  @override
  void dispose() {
    _myController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _myController = TextEditingController();
    _futurePosition = _determinePosition();
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );
    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  void _getPhoto() async {
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        imageFile = File(photo.path);
      });
    }
  }

  void _submit() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Processing Data')),
    );
    // sleep(duration);

    if (_formKey.currentState!.validate()) {
      if (imageFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Validated')),
        );
        var uuid = const Uuid();
        String uuidString = uuid.v4();
        String downloadURL = await uploadFile(uuidString);
        await addItem(downloadURL, _myController.text);
        if (kDebugMode) {
          print(uuidString);
        }
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please take a photo')),
        );
      }
    }
    setState(() {});
  }

  Future<void> addItem(String downloadURL, String title) async {
    // Call the user's CollectionReference to add a new user
    Position position = await _futurePosition;
    await FirebaseFirestore.instance.collection('photos').add({
      'title': title,
      'url': downloadURL,
      'location': GeoPoint(position.latitude, position.longitude),
      'user': FirebaseAuth.instance.currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<String> uploadFile(String filename) async {
    Reference ref = FirebaseStorage.instance.ref().child('$filename.jpg');
    final SettableMetadata metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: <String, String>{'file': 'image'},
      contentLanguage: 'en',
    );
    UploadTask uploadTask = ref.putFile(imageFile!, metadata);
    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadURL = await taskSnapshot.ref.getDownloadURL();
    if (kDebugMode) {
      print(downloadURL);
    }
    return downloadURL;
  }

  String? _textValidator(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter some text";
    }
    if (value.contains("@")) {
      return "Don't use the @ char.";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Add a Photo"),
      ),
      body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              controller: _myController,
              validator: _textValidator,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter name of Food Stand/Truck',
              ),
            ),
            ElevatedButton(
                onPressed: buttonWorks ? _submit : null,
                child: const Text("Submit")),
            Text(displayString),
            SizedBox(
              height: 300,
              width: 300,
              child: imageFile != null
                  ? Image.file(imageFile!)
                  : Placeholder(
                      fallbackHeight: 100,
                      fallbackWidth: 100,
                      child: Image.network(
                        'https://img.lovepik.com/free-png/20210918/lovepik-street-food-stalls-png-image_400270387_wh1200.png',
                      )),
            ),
            StreamBuilder(
                stream: positionStream,
                builder:
                    (BuildContext context, AsyncSnapshot<Position> snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                        'Lat: ${snapshot.data!.latitude}, Long: ${snapshot.data!.longitude}, Accuracy: ${snapshot.data!.accuracy}');
                  } else if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  }

                  return const CircularProgressIndicator();
                }),
          ],
        ),
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: _getPhoto,
        tooltip: 'Get Photo',
        child: const Icon(Icons.add_a_photo),
        foregroundColor: Colors.amber,
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
