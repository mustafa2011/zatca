import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:zatca/widgets/widget.dart';

import '../helpers/utils.dart';

class SettingFormWidget extends StatelessWidget {
  final String? logo;
  final String? terms;
  final int? logoWidth;
  final int? logoHeight;
  final ValueChanged<String> onChangedLogo;
  final ValueChanged<String> onChangedTerms;
  final ValueChanged<String> onChangedLogoWidth;
  final ValueChanged<String> onChangedLogoHeight;

  const SettingFormWidget({
    super.key,
    this.logo = '',
    this.terms = '',
    this.logoWidth = 75,
    this.logoHeight = 75,
    required this.onChangedLogo,
    required this.onChangedTerms,
    required this.onChangedLogoWidth,
    required this.onChangedLogoHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Container(
      padding: const EdgeInsets.all(5),
      child: buildUser(),
    ));
  }

  Widget buildUser() => NewFrame(
        title: "معلومات المستخدم",
        child: Column(
          children: [
            rowText('رقم المستخدم:', Utils.clientId.toString()),
            rowText('اسم المستخدم:', Utils.contactName),
            rowText('الجوال:', Utils.contactNumber),
            rowText('صلاحية الاستخدام:', Utils.subscriptionExpiry),
            rowText('بيئة الربط مع الزكاة:',
                Utils.environment == "simulation" ? "محاكاة" : "مباشر"),
            rowText('الشركة:', Utils.companyName),
            rowText('الرقم الضريبي:', Utils.vatNumber),
            rowText('السجل التجاري:', Utils.crNumber),
            rowText('نوع الجهاز:', Utils.device),
            buildNationalAddress(),
            Utils.terms == ""
                ? Container()
                : NewFrame(
                    title: "شروط تظهر أسفل الفاتورة", child: Text(Utils.terms)),
          ],
        ),
      );

  Widget rowText(String title, String value) => Row(
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              softWrap: true,
            ),
          ),
        ],
      );

  Widget buildNationalAddress() => NewFrame(
        title: "العنوان الوطني",
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("رقم المبنى: ${Utils.buildingNo}"),
              Text("الرقم الفرعي: ${Utils.secondaryNo}"),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("الشارع: ${Utils.street}"),
              Text("الحي: ${Utils.district}"),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("المدينة: ${Utils.city}"),
              Text("رمز البريد: ${Utils.postalCode}"),
            ],
          ),
        ]),
      );

  Widget address1() => Container(
        padding: EdgeInsets.only(top: 5, right: 5, bottom: 5),
        child: Text(
          "رقم المبنى: ${Utils.buildingNo}\n"
          "الرقم الفرعي: ${Utils.secondaryNo}\n"
          "الشارع: ${Utils.street}",
        ),
      );

  Widget address2() => Container(
        padding: EdgeInsets.only(top: 5, left: 5, bottom: 5),
        child: Text(
          "الحي: ${Utils.district}\n"
          "المدينة: ${Utils.city}\n"
          "رمز البريد: ${Utils.postalCode}",
        ),
      );

  Widget buildLogo() => logo != ''
      ? Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(158, 158, 158, 0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: Image.memory(
            base64Decode(logo!),
            height: logoHeight!.toDouble(),
            width: logoWidth!.toDouble(),
            fit: BoxFit.fill,
          ))
      : Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(158, 158, 158, 0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: Image(
            image: const AssetImage('assets/images/logo.png'),
            height: logoHeight!.toDouble(),
            width: logoWidth!.toDouble(),
            fit: BoxFit.fill,
          ));

  Widget buildLogoWidth() => SizedBox(
        width: 100,
        child: MyTextFormField(
          keyboardType: TextInputType.number,
          initialValue: logoWidth.toString(),
          labelText: 'عرض الشعار',
          onChanged: onChangedLogoWidth,
        ),
      );

  Widget buildLogoHeight() => SizedBox(
        width: 100,
        child: MyTextFormField(
          keyboardType: TextInputType.number,
          initialValue: logoHeight.toString(),
          labelText: 'ارتفاع الشعار',
          onChanged: onChangedLogoHeight,
        ),
      );

  Widget buildTextLogo() => TextFormField(
        initialValue: logo,
        onChanged: onChangedLogo,
      );
}
