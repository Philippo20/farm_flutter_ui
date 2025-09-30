const sdk = require('node-appwrite');

const client = new sdk.Client()
    .setEndpoint('http://134.209.212.84/v1')
    .setProject('68323d9a001ee58070b5')
    .setKey('standard_9a7f6948aaa2946856f5a14d62f62594e6e8ac1f29e5a9cae4916394d1af29e21f8134ec82f5fadeb090842d22a6009013dc8a5bbfbf387951af6b221e763392a6c9659d42a1b07e85a354f827c5d583208433ce91bb7dd6ed32f872579dcae277d4cf844f3456065175b769aa38b0878bb277894e5f9797110818e3c3980837');

const databases = new sdk.Databases(client);
const databaseId = '683245610000d2dd24f8';

async function updateCollectionPermissions(collectionId, readPerms, createPerms, updatePerms, deletePerms) {
    try {
        const collection = await databases.getCollection(databaseId, collectionId);
        await databases.updateCollection(
            databaseId,
            collectionId,
            collection.name,
            readPerms,
            createPerms,
            updatePerms,
            deletePerms
        );
        console.log(`Permissions updated for ${collectionId}`);
    } catch (e) {
        console.error(`Failed to update permissions for ${collectionId}:`, e.message);
    }
}

const collections = [
    'users',
    'farms',
    'sensors',
    'alerts',
    'thresholds',
    'logs',
    'grow_stages'
];

// PUBLIC access for all actions:
const readPerms = ['any'];
const createPerms = ['any'];
const updatePerms = ['any'];
const deletePerms = ['any'];

(async () => {
    for (const collection of collections) {
        await updateCollectionPermissions(collection, readPerms, createPerms, updatePerms, deletePerms);
    }
})();
