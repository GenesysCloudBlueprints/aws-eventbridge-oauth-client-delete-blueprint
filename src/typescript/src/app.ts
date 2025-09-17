import fs from 'fs'
import path from 'path'
import { api } from '@pagerduty/pdjs'
import { APIResponse } from '@pagerduty/pdjs/build/src/api'

import { Marshaller } from './model/oauth_client_delete/marshaller/Marshaller'
import config from './config'

export const lambdaHandler = async (
    event: any
  ): Promise<any> => {
    console.log(`Received Event: ${JSON.stringify(event, null, 2)}`)

    // unmarshal the event
    const awsEvent = Marshaller.unmarshal(event, 'AWSEvent')
    
    // only process OAuthClient events
    if (!awsEvent.detail.topicName.includes('OAuthClient'))
        return generateReturnBody(200, 'Not an OAuth Client event')

    const oauthClientEvent = awsEvent.detail.eventBody

    // only respond to deleted clients
    if (oauthClientEvent.action !== 'Delete')
        return generateReturnBody(200, 'OAuth Client not deleted')

    let deleteTime = ''
    for (const propertyChange of oauthClientEvent.propertyChanges) {
        if (propertyChange.property === 'deleted_on')
            deleteTime = propertyChange.newValues[0]
    }

    console.log(`${oauthClientEvent.entity.name} has been deleted at ${deleteTime}`)

    try {
        // create a pager duty incident with the client id and deletion time
        const incident = await notifyPagerDuty(oauthClientEvent.entity.id, deleteTime, config.pagerDutyServiceId)
        console.log("Status:", incident.status);
        console.log("Data:", incident.data);
        console.log(`PagerDuty incident has been created....`)
    } catch (err) {
        console.error(`Failed to create PagerDuty incident: ${err}`)
        return generateReturnBody(500, err.statusText)
    }

    return generateReturnBody(200, 'PagerDuty incident created')
}

const notifyPagerDuty = async (oauthClientId : string, deletedOn: string, serviceId: string) : Promise<APIResponse> => {
    const pd = api({token: config.pagerDutyApiKey})

    const details = `OAuth Client with ID ${oauthClientId} has been deleted at ${deletedOn}`
    const payload = {
        'incident': {
            'type': 'incident',
            'title': 'OAuth Client Deleted',
            'service': {
                'id': serviceId,
                'type': 'service_reference'
            },
            'body': {
                'type': 'incident_body',
                'details': details
            }
        }
    }

    console.log(`Creating PagerDuty incident with payload: ${JSON.stringify(payload, null, 2)}`)

    return await pd.post('/incidents', { data: payload })
}

function generateReturnBody(statusCode: number, message: string) {
    return {
        statusCode: statusCode,
        body: message
    }
}

// For running locally. Pass in the path to a valid event in a JSON file to test
const filePath = process.argv[2]
if (filePath !== undefined && filePath.includes(path.basename(filePath))) {
    try {
        const data = fs.readFileSync(filePath, 'utf8')

        lambdaHandler(JSON.parse(data))
            .then((body) => {
                console.log(JSON.stringify(body, null, 2))
            })
            .catch((err) => {
                console.log(err)
            })
    } catch (err) {
        console.error(err)
    }
}