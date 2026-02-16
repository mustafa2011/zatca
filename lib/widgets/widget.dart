import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helpers/utils.dart';
import '../screens/home.dart';

class NewButton extends StatelessWidget {
  final double? fontSize;
  final IconData? icon;
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
  final double? space;
  final bool? tapped;
  final double? width;

  const NewButton({
    super.key,
    this.backgroundColor = Utils.primary,
    this.textColor = Utils.primary,
    this.text,
    this.size = 40,
    this.iconSize = 0,
    this.fontSize = 12,
    this.icon,
    this.iconColor = Utils.background,
    this.onTap,
    this.onTapCancel,
    this.onTapDown,
    this.onTapUp,
    this.textPositionDown = false,
    this.radius = 10.0,
    this.padding = 10.0,
    this.space = 0.0,
    this.tapped = false,
    this.width = 70,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    EdgeInsets edgeInsets = const EdgeInsets.fromLTRB(12, 12, 12, 15);
    return TextButton(
      onPressed: onTap,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(backgroundColor),
        shadowColor: WidgetStateProperty.all(Colors.grey),
        elevation: WidgetStateProperty.all(3.0),
        padding: WidgetStateProperty.all(edgeInsets),
      ),
      child: Text(text!, style: textStyle),
    );
  }
}

class NewTab extends StatelessWidget {
  final double? fontSize;
  final IconData? icon;
  final Function()? onTap;
  final Color? backgroundColor;
  final Color? textColor;
  final String? text;
  final double? radius;
  final double? padding;

  const NewTab({
    super.key,
    this.backgroundColor = Utils.background,
    this.textColor = Utils.primary,
    this.text,
    this.fontSize = 12,
    this.icon,
    this.onTap,
    this.radius = 10,
    this.padding = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
                left: padding!,
                right: padding!,
                bottom: padding!,
                top: padding! * 1),
            margin: EdgeInsets.only(left: padding! * 0.3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius!),
              color: backgroundColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  text ?? '',
                  style: TextStyle(
                      fontSize: fontSize,
                      color: textColor,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NewForm extends StatelessWidget {
  final Widget child;
  final Widget? action;
  final Widget? tab;
  final String? title;
  final IconData? icon;
  final Function()? onIconTab;
  final bool? isLoading;

  const NewForm({
    super.key,
    required this.child,
    this.action,
    this.tab,
    this.title,
    this.icon,
    this.onIconTab,
    this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.only(top: 30),
        color: Utils.secondary,
        child: Stack(
          children: [
            titleBar(width),
            tabBar(width),
            bottomBar(width),
            body(width, height),
            Center(
              child: isLoading! ? const CircularProgressIndicator() : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget titleBar(double width) => Container(
        width: width,
        height: 150,
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 100),
        margin: const EdgeInsets.only(top: 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(0),
          color: Utils.primary,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title ?? '',
              style: const TextStyle(
                  fontSize: 20,
                  color: Utils.secondary,
                  fontWeight: FontWeight.bold),
            ),
            InkWell(
              onTap: onIconTab,
              child: Icon(
                icon,
                color: Utils.secondary,
                size: 40,
              ),
            ),
          ],
        ),
      );

  Widget bottomBar(double width) => Positioned(
      left: 0,
      bottom: 0,
      child: Container(
          width: width,
          height: 70,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(0),
            color: Utils.background,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              actionBar(width),
              NewButton(
                icon: Icons.home,
                iconSize: 25,
                onTap: () => Get.to(() => const HomePage()),
              )
            ],
          )));

  Widget actionBar(double width) => SizedBox(
        width: width - 70,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            Row(
              children: [
                action ?? const Text(''),
              ],
            ),
          ],
        ),
      );

  Widget tabBar(double width) => Positioned(
        right: 10,
        top: 57,
        child: SizedBox(
          width: width - 20,
          height: 50,
          child: tab,
        ),
      );

  Widget body(double width, double height) => Positioned(
        top: 105,
        child: SingleChildScrollView(
          child: Container(
              width: width - 20,
              height: height - 225,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(
                  left: 10, right: 10, bottom: 10, top: 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Utils.background,
              ),
              child: child),
        ),
      );
}

class NewFrame extends StatelessWidget {
  final String title;
  final Widget child;
  final double padding;
  final Color background;
  final Color borderColor;

  const NewFrame({
    super.key,
    required this.title,
    required this.child,
    this.padding = 5.0,
    this.background = Colors.transparent,
    this.borderColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(top: padding, left: 10, right: 10),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: background,
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: Container(
            padding: EdgeInsets.all(padding),
            margin: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: child,
          ),
        ),
        Container(
          color: Utils.background,
          margin: EdgeInsets.only(right: title == '' ? 0 : 20),
          padding: EdgeInsets.only(
              left: title == '' ? 0 : 5, right: title == '' ? 0 : 5),
          child: Text(title, style: const TextStyle(fontSize: 10)),
        ),
      ],
    );
  }
}

class MyTextFormField extends StatelessWidget {
  final String labelText;
  final RegExp? pattern;
  final String? errorMessage;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final bool isMandatory;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final bool readOnly;
  final bool obscureText;
  final FocusNode? focusNode;
  final Function()? onTap;
  final Function(String value)? onFieldSubmitted;
  final Widget? suffixIcon;
  final double padding;
  final bool autofocus;

  const MyTextFormField({
    super.key,
    required this.labelText,
    this.pattern,
    this.errorMessage,
    this.initialValue,
    this.onChanged,
    this.isMandatory = false,
    this.controller,
    this.keyboardType = TextInputType.name,
    this.textAlign = TextAlign.center,
    this.textDirection = TextDirection.rtl,
    this.readOnly = false,
    this.obscureText = false,
    this.focusNode,
    this.onTap,
    this.onFieldSubmitted,
    this.suffixIcon,
    this.padding = 5.0,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      child: TextFormField(
        maxLines: null,
        obscuringCharacter: '*',
        obscureText: obscureText,
        readOnly: readOnly,
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        initialValue: initialValue,
        style: dataStyle,
        decoration: InputDecoration(
          labelStyle: const TextStyle(fontSize: 12),
          labelText: labelText,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 22.0, horizontal: 10.0),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          suffixIcon: suffixIcon,
        ),
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        onTap: onTap,
        validator: isMandatory
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'يجب ادخال $labelText';
                } else if (pattern != null && !pattern!.hasMatch(value)) {
                  return errorMessage ?? '$labelText غير صحيح';
                }
                return null;
              }
            : null,
        keyboardType: keyboardType,
        textAlign: textAlign,
        textDirection: textDirection,
      ),
    );
  }
}

class CTextField extends StatelessWidget {
  final bool isMandatory;
  final String labelText;
  final RegExp? pattern;
  final String? errorMessage;
  final Widget? suffixIcon;

  const CTextField({
    super.key,
    this.isMandatory = false,
    required this.labelText,
    this.pattern,
    this.errorMessage,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        labelStyle: const TextStyle(fontSize: 12),
        labelText: labelText,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 11.0, horizontal: 10.0),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        suffixIcon: suffixIcon,
      ),
      validator: isMandatory
          ? (value) {
              if (value!.isEmpty) {
                return 'يجب ادخال بيانات هذا الحقل';
              } else {
                if (pattern != null && !pattern!.hasMatch(value)) {
                  return errorMessage ?? 'يجب ادخال رقم جوال صحيح';
                }
              }
              return null;
            }
          : null,
    );
  }
}

const TextStyle dataStyle =
    TextStyle(color: Utils.primary, fontSize: 14, fontWeight: FontWeight.bold);

const TextStyle menuStyle = TextStyle(
    color: Utils.secondary, fontSize: 18, fontWeight: FontWeight.bold);

const TextStyle whiteLargeTextStyle = TextStyle(
    color: Color(0xFFFFFFFF), fontSize: 16, fontWeight: FontWeight.bold);

const TextStyle whiteTextStyle = TextStyle(color: Color(0xFFFFFFFF));

TextButton textButton(Function(Key? key) onPressed,
        {String? line1, String? line2}) =>
    TextButton(
        onPressed: () {
          onPressed;
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(const Color(0xFF57007F)),
          padding: WidgetStateProperty.all(const EdgeInsets.all(20)),
        ),
        child: SizedBox(
          width: 100,
          height: 50,
          child: Column(
            children: [
              Text(line1!, style: whiteLargeTextStyle),
              Text(
                line2!,
                style: whiteTextStyle,
              ),
            ],
          ),
        ));

IconButton backHome = IconButton(
  onPressed: () => Get.to(() => const HomePage()),
  icon: const Icon(Icons.home, size: 30),
  color: Colors.white,
);

class MyTextButton extends StatelessWidget {
  final Function()? onPressed;
  final String? line1;
  final String line2;
  final double width;
  final double height;

  const MyTextButton(
      {super.key,
      this.onPressed,
      this.line1,
      this.line2 = "",
      this.width = 110.0,
      this.height = 30.0});

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(
              line2 == "" ? const Color(0xFF57007F) : const Color(0xFF57007F)),
          // line2 == "" ? const Color(0xFFFF9800) : const Color(0xFF57007F)),
          padding: WidgetStateProperty.all(const EdgeInsets.all(20)),
        ),
        child: Container(
          padding: EdgeInsets.only(left: 0, right: 0),
          width: width,
          height: height,
          child: line2 == ""
              ? Center(child: Text(line1!, style: whiteLargeTextStyle))
              : Column(
                  children: [
                    Text(line1!, style: whiteLargeTextStyle),
                    Text(line2, style: whiteTextStyle),
                  ],
                ),
        ));
  }
}

class InvoiceKind extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;

  const InvoiceKind({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<InvoiceKind> createState() => _InvoiceKind();
}

class _InvoiceKind extends State<InvoiceKind> {
  late String selectedValue;

  final Map<String, String> options = {
    'مبسطة': 'simplified',
    'ضريبية': 'standard',
  };

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          dropdownColor: Colors.black87,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          borderRadius: BorderRadius.circular(8),
          items: options.keys.map((label) {
            return DropdownMenuItem<String>(
              value: label,
              child: Text(label, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() => selectedValue = newValue);
              widget.onChanged(options[newValue]!); // Return English value
            }
          },
        ),
      ),
    );
  }
}
