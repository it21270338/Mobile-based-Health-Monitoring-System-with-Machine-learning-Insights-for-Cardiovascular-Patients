import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class UserSelectPreference extends StatefulWidget {
  const UserSelectPreference({super.key});

  @override
  State<UserSelectPreference> createState() => _UserSelectPreferenceState();
}

class _UserSelectPreferenceState extends State<UserSelectPreference> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:Container(
          child: Column(
            children: [
              Text("Select your Preference "),
              SizedBox(height: 20,),
              ElevatedButton(onPressed: (){}, child: Text("Mind Relaxing")),
              SizedBox(height: 20,),
              ElevatedButton(onPressed: (){}, child: Text("Send Notification")),
            ],
          ),
        ),
      ),
    );
  }
}
