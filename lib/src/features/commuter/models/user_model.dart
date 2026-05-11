import 'package:firebase_database/firebase_database.dart';

//Getting user info from data base
class UserModel
{
  String? phone;
  String? name;
  String? id;
  String? email;
  String? comment;

  UserModel({this.phone, this.name, this.comment,this.id, this.email,});

  UserModel.fromSnapshot(DataSnapshot snap)
  {
    phone = (snap.value as dynamic)["phone"];
    name = (snap.value as dynamic)["name"];
    id = snap.key;
    email = (snap.value as dynamic)["email"];
    comment = (snap.value as dynamic)["comment"];
  }
}