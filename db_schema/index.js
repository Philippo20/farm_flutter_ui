const sdk = require('node-appwrite');

// Configure
const client = new sdk.Client()
    .setEndpoint('http://134.209.212.84/v1') //Appwrite endpoint
    .setProject('68323d9a001ee58070b5')          // Project ID
    .setKey('standard_9a7f6948aaa2946856f5a14d62f62594e6e8ac1f29e5a9cae4916394d1af29e21f8134ec82f5fadeb090842d22a6009013dc8a5bbfbf387951af6b221e763392a6c9659d42a1b07e85a354f827c5d583208433ce91bb7dd6ed32f872579dcae277d4cf844f3456065175b769aa38b0878bb277894e5f9797110818e3c3980837');// API Key with Database permissions

const databases = new sdk.Databases(client);
const databaseId = '683245610000d2dd24f8'; // Database ID

// Helper to create a collection
async function createCollection(id, name, permissions = []) {
    try {
        await databases.createCollection(databaseId, id, name, permissions);
        console.log(`Collection ${name} created.`);
    } catch (e) {
        if (e.message && e.message.includes('already exists')) {
            console.log(`Collection ${name} already exists. Skipping...`);
        } else {
            console.error(`Error creating ${name}:`, e.message);
        }
    }
}

// Helper to add attributes
async function addAttributes(collectionId, attributes) {
    for (const attr of attributes) {
        try {
            switch (attr.type) {
                case 'string':
                    await databases.createStringAttribute(
                        databaseId,
                        collectionId,
                        attr.key,
                        255,
                        attr.required,
                        null, // Default value
                        false // encrypt = false
                    );
                    break;
                case 'enum':
                    await databases.createEnumAttribute(
                        databaseId,
                        collectionId,
                        attr.key,
                        attr.elements,
                        attr.required,
                        attr.required ? undefined : attr.elements[0] // Set default only if NOT required
                    );
                    break;
                case 'float':
                    await databases.createFloatAttribute(
                        databaseId,
                        collectionId,
                        attr.key,
                        attr.required,
                        null, // min
                        null, // max
                        attr.required ? undefined : null // Default only if NOT required
                    );
                    break;
                case 'boolean':
                    await databases.createBooleanAttribute(
                        databaseId,
                        collectionId,
                        attr.key,
                        attr.required,
                        attr.required ? undefined : null // Default only if NOT required
                    );
                    break;
                case 'datetime':
                    await databases.createDatetimeAttribute(
                        databaseId,
                        collectionId,
                        attr.key,
                        attr.required,
                        attr.required ? undefined : null // Default only if NOT required
                    );
                    break;
            }
            console.log(`Attribute ${attr.key} added to ${collectionId}.`);
        } catch (e) {
            if (
                e.message &&
                (e.message.includes('already exists') || e.message.includes('Attribute with the requested key already exists'))
            ) {
                console.log(`Attribute ${attr.key} already exists in ${collectionId}. Skipping...`);
            } else {
                console.error(`Error adding ${attr.key} to ${collectionId}:`, e.message);
            }
        }
    }
}


(async () => {
    // 1. users
    await createCollection('users', 'Users');
    await addAttributes('users', [
        {key: 'name', type: 'string', required: true},
        {key: 'email', type: 'string', required: true},
        {key: 'role', type: 'enum', elements: ['admin', 'owner', 'caretaker'], required: true},
        {key: 'address', type: 'string', required: true},
        {key: 'farmID', type: 'string', required: true},
    ]);

    // 2. farms
    await createCollection('farms', 'Farms');
    await addAttributes('farms', [
        {key: 'name', type: 'string', required: true},
        {key: 'location', type: 'string', required: true},
        {key: 'ownerID', type: 'string', required: true},
        {key: 'careTakerID', type: 'string', required: true},
        {key: 'tierType', type: 'enum', elements: ['Compact', 'Medium', 'Mega'], required: true},
        {key: 'status', type: 'enum', elements: ['active', 'inactive'], required: true},
        {key: 'plant_type', type: 'enum', elements: ['lettuce', 'tomatoes', 'basil'], required: true},
        {key: 'plant_variety', type: 'enum', elements: ['romaine', 'cherry tomatoes', 'beef stock'], required: true},
        {key: 'created_at', type: 'datetime', required: true},
    ]);

    // 3. sensors
    await createCollection('sensors', 'Sensors');
    await addAttributes('sensors', [
        {key: 'farmID', type: 'string', required: true},
        {key: 'type', type: 'enum', elements: ['temperature', 'humidity', 'co2', 'light', 'ph', 'ec', 'electricity'], required: true},
        {key: 'value', type: 'float', required: true},
        {key: 'unit', type: 'string', required: true},
        {key: 'timestamp', type: 'datetime', required: true},
    ]);

    // 4. alerts
    await createCollection('alerts', 'Alerts');
    await addAttributes('alerts', [
        {key: 'farmID', type: 'string', required: true},
        {key: 'message', type: 'string', required: true},
        {key: 'sensorType', type: 'string', required: true},
        {key: 'severity', type: 'enum', elements: ['low', 'medium', 'high'], required: true},
        {key: 'timestamp', type: 'datetime', required: true},
        {key: 'resolved', type: 'boolean', required: false},
    ]);

    // 5. thresholds
    await createCollection('thresholds', 'Thresholds');
    await addAttributes('thresholds', [
        {key: 'farmID', type: 'string', required: true},
        {key: 'temperature_max', type: 'float', required: true},
        {key: 'temperature_min', type: 'float', required: true},
        {key: 'ph_min', type: 'float', required: true},
        {key: 'ph_max', type: 'float', required: true},
        {key: 'ec_max', type: 'float', required: true},
        {key: 'humidity_max', type: 'float', required: false},
    ]);

    // 6. logs
    await createCollection('logs', 'Logs');
    await addAttributes('logs', [
        {key: 'userID', type: 'string', required: true},
        {key: 'action', type: 'string', required: true},
        {key: 'timestamp', type: 'datetime', required: true},
    ]);

    // 7. grow_stages
    await createCollection('grow_stages', 'Grow Stages');
    await addAttributes('grow_stages', [
        {key: 'farmID', type: 'string', required: true},
        {key: 'stage_name', type: 'enum', elements: ['germination', 'vegetative', 'flowering', 'harvest'], required: true},
        {key: 'started', type: 'boolean', required: true},
        {key: 'start_time', type: 'datetime', required: true},
        {key: 'end_time', type: 'datetime', required: false},
        {key: 'created_by', type: 'string', required: true},
    ]);
})();
