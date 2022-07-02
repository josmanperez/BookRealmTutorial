exports = function(FCMToken, operation) {

  var db = context.services.get("mongodb-atlas").db("product");
  const userData = db.collection("customUserData");
  
  if (operation === "add") {
    console.log("add");
    userData.updateOne({"userId": context.user.id},
    { "$addToSet": {
      "FCMToken": FCMToken
    }  
    }).then((doc) => {
      return {success: `User token updated`};
    }).catch(err => {
      return {error: `User ${context.user.id} not found`};
    });
  } else if (operation === "remove") {
    console.log("remove");
    
  }
  
  
};