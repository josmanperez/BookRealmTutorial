exports = async function(changeEvent) {
  
  const admin = require('firebase-admin');
  const db = context.services.get("mongodb-atlas").db("product");
  
  const id = changeEvent.documentKey._id;
  
  const bookCollection = db.collection("book");
  const pushNotification = db.collection("pushNotification");
  
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: context.values.get('projectId'),
      clientEmail: context.values.get('clientEmail'),
      privateKey: context.values.get('fcm_private_key_value').replace(/\\n/g, '\n'),
    }),
  });
  
  const registrationToken = changeEvent.fullDocument.token;
  console.log(JSON.stringify(registrationToken));
  const title = changeEvent.fullDocument.changes.volumeInfo.title;
  const image = changeEvent.fullDocument.changes.volumeInfo.imageLinks.smallThumbnail;
  
  const message = {
    "notification":{
      "body": `One of your favorites changed`,
      "title": `${title} changed`
    },
    tokens: registrationToken
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
  
  // Send a message to the device corresponding to the provided
  // registration token.
  admin.messaging().sendMulticast(message)
    .then((response) => {
      // Response is a message ID string.
      console.log('Successfully sent message:', response);
      pushNotification.updateOne({"_id": BSON.ObjectId(`${id}`)},{
        "$set" : {
          "processed": true
        }
      });
    })
    .catch((error) => {
      console.log('Error sending message:', error);
  });
};