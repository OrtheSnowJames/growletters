import 'package:flutter/material.dart';
import '../resource_manager/resource_manager.dart';

enum TreeStage { seed, sprout, branchy, sapling, grown }

class TreeData {
  TreeStage stage;

  TreeData({required this.stage});
}

class Tree extends StatefulWidget {
  final TreeData dat;

  Tree({required this.dat});

  _TreeState createState() => _TreeState();
}

class _TreeState extends State<Tree> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Image(image: ResourceManager.all[widget.dat.stage.index])
        ],
      ),
    );
  }
}
