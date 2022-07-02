exports = function({user}) {

  const db = context.services.get("mongodb-atlas").db("product");
  const userCollection = db.collection("user");
  
  const partition = `${user.id}`;
  var username = null;
  var displayname = null;
  var registered = false;
  
  if (user.identities[0].provider_type != "anon-user") {
    username = user.data.email;
    displayname = user.data.email;
    registered = true;
  }
  
  const userPreferences = {
    displayName: displayname
  };
  
  console.log(`user: ${JSON.stringify(user)}`);
  
  const userDoc = {
    _id: user.id,
    _partition: partition,
    userName: username,
    userPreferences: userPreferences,
    providerType: user.identities[0],
    registered: registered
  };
  
  return userCollection.insertOne(userDoc)
  .then(result => {
    console.log(`Added User document with _id: ${result.insertedId}`);
  }, error => {
    console.log(`Failed to insert User document: ${error}`);
  });
};