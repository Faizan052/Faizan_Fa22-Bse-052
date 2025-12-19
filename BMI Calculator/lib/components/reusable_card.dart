import 'package:flutter/material.dart';

class ReusableCard extends StatelessWidget {
  ReusableCard({required this.color, required this.cardChild, this.onPress});

  final Color color;
  final Widget cardChild;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeIn,
        child: Container(
          child: cardChild,
          margin: EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
