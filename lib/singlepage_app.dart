// @dart=2.9
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'CircleProgress.dart';
import 'package:rflutter_alert/rflutter_alert.dart';


class SinglePageApp extends StatefulWidget {
  @override
  _SinglePageAppState createState() => _SinglePageAppState();
}

class _SinglePageAppState extends State<SinglePageApp>
    with SingleTickerProviderStateMixin {
  bool isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final databaseReference = FirebaseDatabase.instance.reference();
  bool _signIn;
  AnimationController progressController;
  Animation<double> tempAnimation;
  Animation<double> humidityAnimation;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _signIn = false;
    databaseReference.child('FirebaseIOT').once().then((DataSnapshot snapshot) {
      double temp = snapshot.value['Temperature']['Data'];
      double hum = snapshot.value['Humidity']['Data'].toDouble();
      isLoading = true;
      _DashboardInit(temp, hum);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _signIn ? mainScaffold() : signInScaffold();
  }
  _DashboardInit(double temp, double hum) {
    progressController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 5000)); //5s

    tempAnimation =
        Tween<double>(begin: -50, end: temp).animate(progressController)
          ..addListener(() {
            setState(() {});
          });

    humidityAnimation =
        Tween<double>(begin: 0, end: hum).animate(progressController)
          ..addListener(() {
            setState(() {});
          });

    progressController.forward();
  }

  Widget mainScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: Text('IOT '),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: handleLoginOutPopup,
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
          child: isLoading
              ? Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:[
              Container(
                child: StreamBuilder(
                  stream: databaseReference.child('FirebaseIOT').onValue,
                  builder: (context, AsyncSnapshot snapshot){
                    if (snapshot.hasData && !snapshot.hasError &&
                        snapshot.data.snapshot.value != null){
                      DataSnapshot dataValues = snapshot.data.snapshot;
                      final Map<String, dynamic> data =
                      Map<String, dynamic>.from(dataValues.value);
                      final double temp = (data['Temperature']['Data']);
                      final int hum = data['Humidity']['Data'];
                      print('Temperature -> $temp');
                      print('Humidity -> $hum');
                      return Column(
                        children: [
                          CustomPaint(
                            foregroundPainter:
                            CircleProgress(tempAnimation.value, true),
                            child: Container(
                              width: 200,
                              height: 200,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text('Temperature'),
                                    Text(
                                      '$temp',
                                      style: TextStyle(
                                          fontSize: 50, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '°C',
                                      style: TextStyle(
                                          fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          CustomPaint(
                            foregroundPainter:
                            CircleProgress(humidityAnimation.value, false),
                            child: Container(
                              width: 200,
                              height: 200,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text('Humidity'),
                                    Text(
                                      '$hum',
                                      style: TextStyle(
                                          fontSize: 50, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '%',
                                      style: TextStyle(
                                          fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )

                        ],
                      );
                    }else{
                      return CircularProgressIndicator();
                    }
                  },
                ),
              )
            ],
          )
              : Text(
            'Loading...',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          )),
    );

  }

  Widget signInScaffold() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "IOT Flutter Firebase",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            SizedBox(
              height: 50,
            ),
            RaisedButton(
              textColor: Colors.white,
              color: Colors.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.blueAccent)),
              onPressed: () async {
                _signInAnonymously();
              },
              child: const Text(
                "Sing-in",
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _signInAnonymously() async {
    final FirebaseUser user = (await _auth.signInAnonymously()).user;
    print("user isAnonymous: ${user.isAnonymous}");
    print("user uid: ${user.uid}");

    setState(() {
      if (user != null) {
        _signIn = true;
      } else {
        _signIn = false;
      }
    });
  }

  handleLoginOutPopup() {
    Alert(
      context: context,
      type: AlertType.info,
      title: "Login Out",
      desc: "Do you want to login out now?",
      buttons: [
        DialogButton(
          child: Text(
            "No",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => Navigator.pop(context),
          color: Colors.teal,
        ),
        DialogButton(
          child: Text(
            "Yes",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: handleSignOut,
          color: Colors.teal,
        )
      ],
    ).show();
  }

  Future<Null> handleSignOut() async {
    this.setState(() {
      isLoading = true;
    });

    await FirebaseAuth.instance.signOut();
    //await googleSignIn.signOut();

    this.setState(() {
      isLoading = false;
    });

    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => SinglePageApp()),
            (Route<dynamic> route) => false);
  }

}
