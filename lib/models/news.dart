import 'dart:convert';

class News {
  int? id;
  String date;
  String title;
  String link;

  News(
      {
        this.id,
        required this.date,
        required this.title,
        required this.link,
      });

  News copy(
      {
        int? id,
        String? date,
        String? title,
        String? link,
      }) =>
      News(
        id: id?? this.id,
        date: date?? this.date,
        title: title?? this.title,
        link: link?? this.link,
      );

  factory News.fromJson(dynamic json) {
    return News(
      id: jsonDecode(json['id']),
      date: json['date'],
      title: json['title'],
      link: json['link'],
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'title': title,
    'link': link,
  };
}
