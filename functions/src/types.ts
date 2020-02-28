/**
 * Firstore Admin v1
 *
 * https://firebase.google.com/docs/firestore/reference/rpc/google.firestore.admin.v1#google.firestore.admin.v1.Index
 * https://googleapis.dev/nodejs/firestore/latest/v1.FirestoreAdminClient.html
 */
interface Index {
  fields: IndexField[];

  queryScope: 'COLLECTION' | 'QUERY_SCOPE_UNSPECIFIED';

  /** The resource name of the index. Output only. */
  name?: string;

  /** The state of the index. Output only. */
  state?: 'STATE_UNSPECIFIED' | 'CREATING' | 'READY' | 'NEEDS_REPAIR';
}

interface IndexField {
  /**
   * The path of the field.
   *
   * Must match the field path specification described by [google.firestore.v1beta1.Document.fields][fields].
   * Special field path `__name__` may be used by itself or at the end of a path.
   * `__type__` may be used only at the end of path.
   */
  fieldPath: string;

  order?: 'DESCENDING' | 'ASCENDING' | 'ORDER_UNSPECIFIED';

  /** output only? */
  valueMode?: 'order';
}
