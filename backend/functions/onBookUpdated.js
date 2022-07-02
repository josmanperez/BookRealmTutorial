exports = async function(changeEvent) {
  
  const id = changeEvent.documentKey._id;
  const changes =  changeEvent.updateDescription.updatedFields;
  
  //console.log(JSON.stringify(changes));

  if (id === undefined) {
    return null;
  } 
  
  var db = context.services.get("mongodb-atlas").db("product");
  const userCollection = db.collection("user");
  const bookCollection = db.collection("book");
  const pushNotification = db.collection("pushNotification");
  
  const pipeline = [
  {
    '$match': {
      'favoriteBooks': new BSON.ObjectId(`${id}`), 
      'registered': true
    }
  }, {
    '$lookup': {
      'from': 'customUserData', 
      'localField': '_id', 
      'foreignField': 'userId', 
      'as': 'customData'
    }
  }, {
    '$replaceRoot': {
      'newRoot': {
        '$mergeObjects': [
          {
            '$arrayElemAt': [
              '$customData', 0
            ]
          }, '$$ROOT'
        ]
      }
    }
  }, {
    '$project': {
      '_id': 0, 
      'FCMToken': 1
    }
  }];
  
  const book = await bookCollection.findOne({"_id": BSON.ObjectId(`${id}`)}).then(book => {
    return book;
  }).catch(err => {
    console.error(err);
    return false;
  });
  
  return await userCollection.aggregate(pipeline).toArray().then(data => {
    data.forEach(token => {
      // insert in the pending send push collection 
      if (token.FCMToken) {
        pushNotification.insertOne({
          "token": token.FCMToken,
          "date": new Date(),
          "processed": false,
          "changes": changes
        }); 
      }
      return true;
    });
  }).catch(err => {
    console.error(err);
    return false;
  });
  
};
