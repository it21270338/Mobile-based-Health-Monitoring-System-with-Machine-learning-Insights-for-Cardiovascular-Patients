import 'package:flutter/material.dart';

class Relaxation extends StatefulWidget {
  const Relaxation({super.key});

  @override
  State<Relaxation> createState() => _RelaxationState();
}

class _RelaxationState extends State<Relaxation> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("User  Feel"),
      ),
      body: Center(
        child:Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Lets Play Song to Relax"),
              SizedBox(height: 20,),
              ElevatedButton(onPressed: (){}, child: Text("Song 1")),
              SizedBox(height: 20,),
              ElevatedButton(onPressed: (){}, child: Text("Song 2")),
              SizedBox(height: 20,),
              ElevatedButton(onPressed: (){}, child: Text("Song 3")),
              SizedBox(height: 20,),
              ElevatedButton(onPressed: (){}, child: Text("Song 4")),
              SizedBox(height: 20,),
              ElevatedButton(onPressed: (){}, child: Text("Song 5")),
              SizedBox(height: 20,),
              ElevatedButton(onPressed: (){}, child: Text("Song 6")),
            ],
          ),
        ),
      ),
    );
  }
}
