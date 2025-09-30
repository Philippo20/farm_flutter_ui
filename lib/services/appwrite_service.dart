import 'package:appwrite/appwrite.dart';

class AppwriteService {
  late final Client client;
  late final Databases databases;

  AppwriteService() {
    client = Client()
      .setEndpoint('http://134.209.212.84/v1')
      .setProject('68323d9a001ee58070b5');

    databases = Databases(client);
  }

  Future<void> createUser(Map<String, dynamic> userData) async {
    await databases.createDocument(
      databaseId: '683245610000d2dd24f8',        // Your Appwrite database ID
      collectionId: 'users',           // The collection you're writing to
      documentId: 'unique()',          // Let Appwrite create a unique ID
      data: userData,
    );
  }
}



