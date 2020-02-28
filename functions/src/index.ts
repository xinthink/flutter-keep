import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

admin.initializeApp();
const firestoreAdmin = new admin.firestore.v1.FirestoreAdminClient();
const projectId = 'fltflynotes';

/**
 * Trigger on user creation.
 */
exports.createIndex = functions.auth.user().onCreate((user) => createIndex(user.uid));

/**
 * Create notes collection index for the user.
 * @param uid User id
 */
async function createIndex(uid: string): Promise<any> {
  const index: Index = {
    fields: [
      {
        fieldPath: 'state',
        order: 'DESCENDING',
      }, {
        fieldPath: 'createdAt',
        order: 'DESCENDING',
      },
    ],
    queryScope: 'COLLECTION',
  };
  const operations = await firestoreAdmin.createIndex({
    index,
    parent: `projects/${projectId}/databases/(default)/collectionGroups/notes-${uid}`,
  });
  const indexId = operations[0].metadata.index;
  console.log('index created:', indexId);
  return indexId;
}

/**
 * Testing only. List indexes of a given collection.
 *
 * Query params:
 * - db: database id, for now, it should be: (default)
 * - uid: user id
 * - filter
 */
exports.indexes = functions.https.onRequest((req, res) =>
  firestoreAdmin.listIndexes({
    parent: `projects/${projectId}/databases/${req.query.db}/collectionGroups/notes-${req.query.uid}`,
    filter: req.query.filter,
  }).then((data: any) => {
    console.log('got indexes', data);
    res.send(JSON.stringify(data));
  }).catch((e: any) => {
    console.error('failed to list index', e);
    res.sendStatus(500);
  }));

/** Test the [createIndex] function using http endpoint. */
exports.testIndex = functions.https.onRequest(async (req, res) => {
  const result = await createIndex(req.query.uid);
  res.send(JSON.stringify(result));
});
