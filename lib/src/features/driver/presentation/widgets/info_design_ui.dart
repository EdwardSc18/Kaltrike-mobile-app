import 'package:flutter/material.dart';


class InfoDesignUIWidget extends StatefulWidget
{
  String? textInfo;
  IconData? iconData;

  InfoDesignUIWidget({this.textInfo, this.iconData});

  @override
  State<InfoDesignUIWidget> createState() => _InfoDesignUIWidgetState();
}




class _InfoDesignUIWidgetState extends State<InfoDesignUIWidget>
{
  @override
  Widget build(BuildContext context)
  {
    return Card(
      color: Color(0xfffff59d),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 45),
      child: ListTile(
        leading: Icon(
          widget.iconData,
          color: Colors.black,
        ),
        title: Text(
          widget.textInfo!,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
