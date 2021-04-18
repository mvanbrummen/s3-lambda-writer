const AWS = require('aws-sdk');


exports.handler = async (event, context, callback) => {
    
    var s3 = new AWS.S3();
    console.log('Received event:', JSON.stringify(event, null, 2));
    const srcBucket = event.Records[0].s3.bucket.name;
    // Object key may have spaces or unicode non-ASCII characters.
    const srcKey    = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, " "));
    
    console.log("srcBucket: " + srcBucket);
    console.log("srcKey: " + srcKey);

     var params = {
      Bucket: srcBucket, 
      Key: srcKey, 
      Tagging: {
      TagSet: [
          {
            Key: "Expire", 
            Value: "true"
          } 
      ]
      }
    };

    try {
      const result = await s3.putObjectTagging(params).promise();
      console.log(result);
    } catch(error) {
      console.log(error);
      throw error;
    }
};