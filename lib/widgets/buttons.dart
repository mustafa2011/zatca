import 'package:flutter/material.dart';
import '../helpers/utils.dart';

class AppButtons extends StatelessWidget {
  final double? fontSize;
  final IconData icon;
  final Function()? onTap;
  final Function()? onTapCancel;
  final Function(TapDownDetails)? onTapDown;
  final Function(TapUpDetails)? onTapUp;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? textColor;
  final String? text;
  final double? size;
  final double? iconSize;
  final bool? textPositionDown;
  final double? radius;
  final double? padding;

  const AppButtons({
    super.key,
    this.backgroundColor = Utils.primary,
    this.textColor = Utils.primary,
    this.text,
    this.size = 40,
    this.iconSize = 20,
    this.fontSize = 12,
    required this.icon,
    this.iconColor = Utils.background,
    this.onTap,
    this.onTapCancel,
    this.onTapDown,
    this.onTapUp,
    this.textPositionDown = false,
    this.radius = 20.0,
    this.padding = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onTapCancel: onTapCancel,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(padding!),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius!),
              color: backgroundColor,
            ),
            child: textPositionDown == false
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      text != null
                          ? Text(
                              text!,
                              style: TextStyle(
                                  fontSize: fontSize,
                                  color: iconColor,
                                  fontWeight: FontWeight.bold),
                            )
                          : Container(),
                      SizedBox(width: text != null ? 5 : 0),
                      Icon(
                        icon,
                        color: iconColor,
                        size: iconSize,
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Icon(
                        icon,
                        color: iconColor,
                        size: iconSize,
                      ),
                      SizedBox(height: text != null ? 5 : 0),
                      text != null
                          ? Text(
                              text!,
                              style: TextStyle(
                                  fontSize: fontSize,
                                  color: iconColor,
                                  fontWeight: FontWeight.bold),
                            )
                          : Container(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
