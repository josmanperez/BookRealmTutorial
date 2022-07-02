exports = async function(changeEvent) {
  /*
    A Database Trigger will always call a function with a changeEvent.
    Documentation on ChangeEvents: https://docs.mongodb.com/manual/reference/change-events/

    Access the _id of the changed document:
    const docId = changeEvent.documentKey._id;

    Access the latest version of the changed document
    (with Full Document enabled for Insert, Update, and Replace operations):
    const fullDocument = changeEvent.fullDocument;

    const updateDescription = changeEvent.updateDescription;

    See which fields were changed (if any):
    if (updateDescription) {
      const updatedFields = updateDescription.updatedFields; // A document containing updated fields
    }

    See which fields were removed (if any):
    if (updateDescription) {
      const removedFields = updateDescription.removedFields; // An array of removed fields
    }

    Functions run by Triggers are run as System users and have full access to Services, Functions, and MongoDB Data.

    Access a mongodb service:
    const collection = context.services.get("mongodb-atlas").db("product").collection("book");
    const doc = collection.findOne({ name: "mongodb" });

    Note: In Atlas Triggers, the service name is defaulted to the cluster name.

    Call other named functions if they are defined in your application:
    const result = context.functions.execute("function_name", arg1, arg2);

    Access the default http client and execute a GET request:
    const response = context.http.get({ url: <URL> })

    Learn more about http client here: https://docs.mongodb.com/realm/functions/context/#context-http
  */
  const admin = require('firebase-admin');
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: context.values.get('projectId'),
      clientEmail: context.values.get('clientEmail'),
      privateKey: context.values.get('fcm_private_key_value').replace(/\\n/g, '\n'),
    }),
  });
  const topic = 'books';
  var message = {
    topic: topic
  };
  if (changeEvent.operationType === "insert") {
    const name = changeEvent.fullDocument.volumeInfo.title;
    const image = changeEvent.fullDocument.volumeInfo.imageLinks.smallThumbnail;
    message.notification = {
      "body": `${name} has been added to the list`,
      "title": `New book added`
    };
    if (image !== undefined) {
      message.apns = {
        payload: {
          aps: {
            'mutable-content': 1
          }
        },
        fcm_options: {
          image: image
        }
      };
    } 
  } else if (changeEvent.operationType === "delete") {
    console.log(JSON.stringify(changeEvent));
    const name = changeEvent.fullDocumentBeforeChange.volumeInfo.title;
    message.notification = {
      "body": `${name} has been deleted from the list`,
      "title": `Book deleted`
    };
  }
  admin.messaging().send(message)
    .then((response) => {
      // Response is a message ID string.
      console.log('Successfully sent message:', response);
      return true;
    })
    .catch((error) => {
      console.log('Error sending message:', error);
      return false;
  });
};
