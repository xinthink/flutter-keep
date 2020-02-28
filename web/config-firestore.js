
// Enable offline persistence
firebase.firestore().enablePersistence()
  .catch(function(err) {
    console.log('enable firestore persistence failed', err);
    if (err.code == 'failed-precondition') {
      // Multiple tabs open, persistence can only be enabled
      // in one tab at a a time.
      // ...
    } else if (err.code == 'unimplemented') {
      // The current browser does not support all of the
      // features required to enable persistence
      // ...
    }
  });
