import 'package:appwrite/appwrite.dart';

class AppwriteService {
  late final Client client;
  late final Databases databases;

  AppwriteService() {
    client = Client()
      .setEndpoint('http://137.184.127.121/v1')
      .setProject('68dd35d5000df5252818');

    databases = Databases(client);
  }

  Future<void> createUser(Map<String, dynamic> userData) async {
    await databases.createDocument(
      databaseId: '68dd365d002c20b09502',        // Your Appwrite database ID
      collectionId: 'users',           // The collection you're writing to
      documentId: 'unique()',          // Let Appwrite create a unique ID
      data: userData,
    );
  }
}



