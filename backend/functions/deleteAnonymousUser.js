/** Function to delete an anoymous
 * */
exports = async function(userId) {
  
  const public_key = context.values.get("publicKey");
  const private_key = context.values.get("privateKeyValue");
  const groupId = context.values.get("groupId");
  const appId = context.environment.values.appId;
  const ADMIN_API_BASE_URL = context.values.get("adminBaseURL");
  const axios = require('axios');
  
  const db = context.services.get("mongodb-atlas").db("product");
  const users = db.collection("user");
  
  // Check if the user has anonymous auth
  const filter = { "_id": userId };
  const anon = await users.findOne(filter);
  if (anon == null) {
    return {error: `User ${userId} not found`};
  }
  
  if (anon.registered == false && anon.providerType.provider_type == "anon-user") {
    // Request access token
    return requestAccessToken()
    .then(token => {
      return deleteUser(userId, token.access_token)
      .then(response => {
        if (response.status === 204) {
          users.deleteOne(filter);
          return { success: `The user ${userId} was deleted successfully`};
        } else {
          return {error: `Cant delete user ${response.status}`};
        }
      })
      .catch(err =>{
        return {error: `Error deleting user ${err}`};
      });
    })
    .catch(err => {
      return {error: `Cant get access token ${err}`};
    });
  } else {
    return {error: `User ${userId} is not anonymous`};
  }

  function requestAccessToken() {
    // Get access token
    const endpoint = `${ADMIN_API_BASE_URL}/auth/providers/mongodb-cloud/login`;
    return axios.post(endpoint,{
      "username": public_key, 
      "apiKey": private_key
    },{
      "headers": {
        "Content-Type": ["application/json"]
      },
    })
    .then((response) => {
      return response.data;
    })
    .catch(err => {
      console.error(err);
      throw err;
    });
  }  
  
  function deleteUser(id, access_token) {
    // Get logs for your Realm App
    const endpoint = `${ADMIN_API_BASE_URL}/groups/${groupId}/apps/${appId}/users/${id}`;
    console.log(endpoint);
    return axios.delete(endpoint,{
      "headers": {
        "Authorization": [`Bearer ${access_token}`]
      }
    })
    .then((response) => {
      return response;
    })
    .catch(err => {
      console.error(err);
      throw err;
    });
  }
  
};
