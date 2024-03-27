import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodapptruck/Photoform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
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
            title: const Text('Food Trucks Page'),
            actions: [
              IconButton(
                onPressed: logout,
                icon: Icon(Icons.logout),
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
            child: const Icon(Icons.add_a_photo),
            foregroundColor: Colors.amber,
          ));
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('FoodAppTruck Login Page'),
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
      body.add(ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue, // Button background color
          foregroundColor: Colors.white, // Text color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        ),
        onPressed: () {
          signInWithGoogle();
        },
        child: const Text(
          'Login with Google',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ));
    } else {
      body.add(StreamBuilder(
          stream: FirebaseFirestore.instance.collection('photos').snapshots(),
          builder: ((context, snapshot) {
            if (snapshot.hasError) {
              if (kDebugMode) {
                print(snapshot.error.toString());
              }
              return Text(snapshot.error.toString());
            }
            if (!snapshot.hasData) {
              return const Text("Loading Photos...");
            }
            return Expanded(
                child: ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: ((context, index) {
                return Text(snapshot.data!.docs[index]["title"]);
              }),
              shrinkWrap: true,
            ));
          })));
      body.add(ListTile(
          leading: GoogleUserCircleAvatar(identity: googleUser!),
          title: Text(googleUser!.displayName ?? ""),
          subtitle: Text(googleUser!.email ?? ""),
          tileColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          )));
      body.add(ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Color.fromARGB(255, 244, 168, 54), // Text color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
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
      ));
    }
    return body;
  }
}
