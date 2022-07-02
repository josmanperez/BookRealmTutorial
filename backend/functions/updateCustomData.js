exports = function(color, imageQuality, bookNotification) {

  var db = context.services.get("mongodb-atlas").db("product");
  const userData = db.collection("customUserData");
  
  userData.updateOne({"userId": context.user.id},
  { "$set": {
    "color": color,
    "fullImage": imageQuality,
    "bookNotification": bookNotification
  }  
  }).then((doc) => {
    return {success: `User ${doc.color} found`};
  }).catch(err => {
    return {error: `User ${context.user.id} not found`};
  });
  
};