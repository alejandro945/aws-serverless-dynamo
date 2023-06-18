const AWS = require('aws-sdk');
const dynamo = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event, context) => {
    const headers = { "Content-Type": "application/json" };
    console.log('request:', JSON.stringify(event));
    try {
        switch (event.httpMethod) {
            case 'GET':
                const data = await dynamo.scan({ TableName: 'visits' }).promise();
                return { statusCode: 200, headers, body: JSON.stringify(data.Items) };
            case 'POST':
                const { date, place } = JSON.parse(event.body);
                const params = { TableName: 'visits', Item: { id: Date.now().toString(), date, place }};
                await dynamo.put(params).promise();
                return { statusCode: 200, headers, body: JSON.stringify(params.Item) };
            default:
                return { statusCode: 405, headers, body: 'Method Not Allowed' };
        }
    } catch (error) {
        return { statusCode: 500, headers, body: JSON.stringify(error) };
    }
};