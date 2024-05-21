import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodapptruck/Photoform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class WelcomePageWidget extends StatelessWidget {
  final VoidCallback onSignInPressed;

  const WelcomePageWidget({Key? key, required this.onSignInPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Text(
            'Welcome to \n ChicoFoodTruckFinder!',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange),
            textAlign: TextAlign.center,
          ),
        ),
        const Text(
          'Delicious meals at your fingertips!',
          style: TextStyle(fontSize: 18, color: Colors.brown),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrangeAccent, // Orange theme
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          onPressed: onSignInPressed,
          child: const Text(
            'Login with Google',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class DetailScreen extends StatelessWidget {
  final String imageUrl;

  const DetailScreen({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Image Detail"),
        backgroundColor: Colors.black,
      ),
      body: Container(
        constraints: BoxConstraints.expand(
          height: MediaQuery.of(context).size.height,
        ),
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
          backgroundDecoration: BoxDecoration(color: Colors.black),
          minScale: PhotoViewComputedScale.contained * 1,
          maxScale: PhotoViewComputedScale.covered * 2,
          heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
        ),
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const MapScreen({Key? key, required this.latitude, required this.longitude})
      : super(key: key);

  @override
  MapScreenState createState() => MapScreenState(); // Change here
}

class MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        onMapCreated: onMapCreated, // Use the public method
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.latitude, widget.longitude),
          zoom: 15.0,
        ),
        markers: {
          Marker(
            markerId: const MarkerId("loc"),
            position: LatLng(widget.latitude, widget.longitude),
          ),
        },
      ),
    );
  }
}

class _LoginPageState extends State<LoginPage> {
  bool _initialized = false;
  UserCredential? _userCredential;
  GoogleSignInAccount? googleUser;

  Future<void> initializeDefault() async {
    FirebaseApp app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _initialized = true;
    if (kDebugMode) {
      print("Initialized default app $app");
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    if (!_initialized) {
      await initializeDefault();
    }
    // Trigger the authentication flow
    googleUser = await GoogleSignIn().signIn();

    if (kDebugMode) {
      if (googleUser != null) {
        print(googleUser!.displayName);
      }
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    _userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    setState(() {});
    return _userCredential!;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (googleUser != null) {
      return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Food Truck/Stand Page',
              style: TextStyle(
                fontSize: 25.0,
              ),
            ),
            backgroundColor: Colors.deepOrangeAccent,
            actions: [
              IconButton(
                onPressed: logout,
                icon: const Icon(Icons.logout),
                color: Colors.white,
              ),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: getBody(),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyHomePage()),
              );
            },
            backgroundColor:
                Colors.deepOrangeAccent, // Set FAB background color to orange
            foregroundColor: Colors.white,
            child: const Icon(Icons.add_sharp),
          ));
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Login Page'),
          backgroundColor: Colors.deepOrangeAccent,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: getBody(),
          ),
        ),
      );
    }
  }

  Future<void> logout() async {
    FirebaseAuth.instance.signOut();
    GoogleSignIn().signOut();
    setState(() {
      googleUser = null;
    });
  }

  List<Widget> getBody() {
    List<Widget> body = [];
    if (googleUser == null) {
      body.add(Expanded(
        child: WelcomePageWidget(
          onSignInPressed: () {
            signInWithGoogle();
          },
        ),
      ));
    } else {
      body.add(StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('photos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            if (kDebugMode) {
              print(snapshot.error.toString());
            }
            return Text("Error: ${snapshot.error}");
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasData) {
            return Expanded(
              child: ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot doc = snapshot.data!.docs[index];
                  return Padding(
                      padding: const EdgeInsets.all(
                          8.0), // Adjust the padding value as needed
                      child: ListTile(
                        leading: CachedNetworkImage(
                          imageUrl: doc['url'], // URL of the image
                          imageBuilder: (context, imageProvider) => Container(
                            width: 75.0,
                            height: 75.0,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(
                                  10), // Optional rounded corners
                            ),
                          ),
                          placeholder: (context, url) => const SizedBox(
                            width: 75.0,
                            height: 75.0,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error, size: 75.0),
                        ),
                        title: Text(
                            doc['title']), // Display the title from Firestore
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => MapScreen(
                                      latitude: doc['location'].latitude,
                                      longitude: doc['location'].longitude),
                                ));
                              },
                              child: Text(
                                'Location: ${doc['location'].latitude.toStringAsFixed(6)}, ${doc['location'].longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Colors.blue),
                              ),
                            ),
                            Text(
                                'Time: ${DateFormat('yyyy-MM-dd – kk:mm').format(doc['timestamp'].toDate())}'),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) {
                            return DetailScreen(imageUrl: doc['url']);
                          }));
                        },
                      ));
                },
              ),
            );
          } else {
            return const Text("No photos found.");
          }
        },
      ));
      body.add(Row(
        children: [
          Expanded(
            flex: 3,
            child: ListTile(
              leading: GoogleUserCircleAvatar(identity: googleUser!),
              title: Text(googleUser!.displayName ?? ""),
              tileColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            ),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              GoogleSignIn().signOut();
              setState(() {
                googleUser = null;
              });
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(
              width: 129), // Adds a specific amount of space after the button
        ],
      ));
    }
    return body;
  }
}
