/** 
 * This function will only be called on login. 
 * 
 * */
exports = async function({user}) {

  const db = context.services.get("mongodb-atlas").db("product");
  const userCollection = db.collection("user");
  const userData = db.collection("customUserData");

  const _user = await userCollection.findOne({"_id": user.id});

  if (_user.registered === true && _user.providerType.provider_type === "local-userpass") {
    console.log("Already registered, nothing to do here");
    return;
  }
  
  const partition = `${user.id}`;
  var username = null;
  var displayname = null;
  var registered = false;
  
  // The last identity
  if (user.identities[user.identities.length - 1].provider_type == "local-userpass") {
    username = user.data.email;
    displayname = user.data.email;
    registered = true;
  }
  
  const userPreferences = {
    displayName: displayname
  };
  
  console.log(`user: ${JSON.stringify(user)}`);
  
  // Save default custom user data
  userData.insertOne({
    userId: user.id,
    color: "#000000FF",
    fullImage: true
  });
  
  return userCollection.updateOne({"_id" : user.id},{"$set" : {
    userName: username,
    userPreferences: userPreferences,
    providerType: user.identities[user.identities.length-1],
    registered: registered,
    favoriteRelatedBooks: []
  }})
  .then(result => {
    console.log(`Added User document with _id: ${result.insertedId}`);
  }, error => {
    console.log(`Failed to insert User document: ${error}`);
  });
};